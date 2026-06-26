data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── KMS Key for EKS Secrets + EBS ───────────────────────────────────────────
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption and EBS volumes"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEKSNodeGroupEBS"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.node_group.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEKSClusterSecrets"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cluster.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-kms"
    Env  = var.env
  }

  depends_on = [
    aws_iam_role.node_group,
    aws_iam_role.cluster
  ]
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.eks.arn

  tags = {
    Name = "${var.cluster_name}-logs"
    Env  = var.env
  }
}

# ─── EKS Cluster ─────────────────────────────────────────────────────────────
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = data.aws_subnets.private.ids
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [data.aws_security_group.eks.id]
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  enabled_cluster_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name = var.cluster_name
    Env  = var.env
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks
  ]
}

# ─── OIDC Provider (required for IRSA) ───────────────────────────────────────
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-oidc"
    Env  = var.env
  }
}

# ─── Launch Template ──────────────────────────────────────────────────────────
resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_volume_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
      Env  = var.env
    }
  }
}

# ─── On-Demand Node Group ─────────────────────────────────────────────────────
resource "aws_eks_node_group" "ondemand" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ondemand"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = data.aws_subnets.private.ids
  instance_types  = var.ondemand_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    type = "ondemand"
    env  = var.env
  }

  tags = {
    Name = "${var.cluster_name}-ondemand-nodes"
    Env  = var.env
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy
  ]
}

# ─── Core EKS Addons ─────────────────────────────────────────────────────────
resource "aws_eks_addon" "this" {
  for_each = { for a in var.addons : a.name => a }

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value.name
  addon_version               = try(each.value.version, null)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [aws_eks_node_group.ondemand]
}

# ─── EBS CSI Driver Addon (with IRSA) ────────────────────────────────────────
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn

  timeouts {
    create = "20m"
    update = "20m"
    delete = "10m"
  }

  depends_on = [aws_eks_node_group.ondemand]
}
