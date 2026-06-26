resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster-name}-eks-kms"
    Env  = var.env
  }
}

resource "aws_eks_cluster" "eks" {
  count    = var.is-eks-cluster-enabled == true ? 1 : 0
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-cluster-role[count.index].arn
  version  = var.cluster-version

  vpc_config {
    subnet_ids              = data.aws_subnets.private_subnets.ids
    endpoint_private_access = var.endpoint-private-access
    endpoint_public_access  = var.endpoint-public-access
    security_group_ids      = [data.aws_security_group.eks-cluster-sg.id]
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name = var.cluster-name
    Env  = var.env
  }
}

# OIDC Provider
resource "aws_iam_openid_connect_provider" "eks-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks-certificate.url
}


# Data source to get the latest addon version
data "aws_eks_addon_version" "latest" {
  for_each           = { for idx, addon in var.addons : idx => addon }
  addon_name         = each.value.name
  kubernetes_version = aws_eks_cluster.eks[0].version
  most_recent        = true
}

# AddOns for EKS Cluster
resource "aws_eks_addon" "eks-addons" {
  for_each                    = { for idx, addon in var.addons : idx => addon }
  cluster_name                = aws_eks_cluster.eks[0].name
  addon_name                  = each.value.name
  addon_version               = data.aws_eks_addon_version.latest[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node
  ]
}

# EBS CSI Driver - separate resource for better control
resource "aws_eks_addon" "ebs-csi" {
  cluster_name                = aws_eks_cluster.eks[0].name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "20m"
    update = "20m"
    delete = "10m"
  }

  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node,
    aws_iam_openid_connect_provider.eks-oidc
  ]
}

# NodeGroups
resource "aws_launch_template" "ondemand" {
  name_prefix = "${var.cluster-name}-ondemand-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }
}

resource "aws_launch_template" "spot" {
  name_prefix = "${var.cluster-name}-spot-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }
}

resource "aws_eks_node_group" "ondemand-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-on-demand-nodes"
  node_role_arn   = aws_iam_role.eks-nodegroup-role[0].arn
  subnet_ids      = data.aws_subnets.private_subnets.ids
  instance_types  = var.ondemand_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.desired_capacity_on_demand
    min_size     = var.min_capacity_on_demand
    max_size     = var.max_capacity_on_demand
  }

  launch_template {
    id      = aws_launch_template.ondemand.id
    version = aws_launch_template.ondemand.latest_version
  }

  update_config {
    max_unavailable = 1
  }

  labels = { type = "ondemand" }

  tags = {
    "Name" = "${var.cluster-name}-ondemand-nodes"
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "aws_eks_node_group" "spot-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-spot-nodes"
  node_role_arn   = aws_iam_role.eks-nodegroup-role[0].arn
  subnet_ids      = data.aws_subnets.private_subnets.ids
  instance_types  = var.spot_instance_types
  capacity_type   = "SPOT"

  scaling_config {
    desired_size = var.desired_capacity_spot
    min_size     = var.min_capacity_spot
    max_size     = var.max_capacity_spot
  }

  launch_template {
    id      = aws_launch_template.spot.id
    version = aws_launch_template.spot.latest_version
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    type      = "spot"
    lifecycle = "spot"
  }

  tags = {
    "Name" = "${var.cluster-name}-spot-nodes"
  }

  depends_on = [aws_eks_cluster.eks]
}