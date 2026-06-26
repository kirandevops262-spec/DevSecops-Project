# ─── Cluster ──────────────────────────────────────────────────────────────────
output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS cluster API endpoint"
}

output "cluster_ca" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "EKS cluster CA certificate (base64)"
}

output "cluster_version" {
  value       = aws_eks_cluster.this.version
  description = "Kubernetes version"
}

# ─── OIDC ─────────────────────────────────────────────────────────────────────
output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.this.arn
  description = "OIDC provider ARN for IRSA"
}

output "oidc_provider_url" {
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
  description = "OIDC provider URL (without https://)"
}

# ─── Networking ───────────────────────────────────────────────────────────────
output "private_subnet_ids" {
  value       = data.aws_subnets.private.ids
  description = "Private subnet IDs"
}

output "vpc_id" {
  value       = data.aws_vpc.this.id
  description = "VPC ID"
}

# ─── IAM Role ARNs for IRSA ───────────────────────────────────────────────────
output "ebs_csi_role_arn" {
  value       = aws_iam_role.ebs_csi.arn
  description = "EBS CSI driver IRSA role ARN"
}

output "lbc_role_arn" {
  value       = aws_iam_role.lbc.arn
  description = "AWS Load Balancer Controller IRSA role ARN"
}

output "cluster_autoscaler_role_arn" {
  value       = aws_iam_role.cluster_autoscaler.arn
  description = "Cluster Autoscaler IRSA role ARN"
}

output "external_dns_role_arn" {
  value       = aws_iam_role.external_dns.arn
  description = "External DNS IRSA role ARN"
}

output "external_secrets_role_arn" {
  value       = aws_iam_role.external_secrets.arn
  description = "External Secrets Operator IRSA role ARN"
}

output "cloudwatch_agent_role_arn" {
  value       = aws_iam_role.cloudwatch_agent.arn
  description = "CloudWatch Agent IRSA role ARN"
}

output "fluent_bit_role_arn" {
  value       = aws_iam_role.fluent_bit.arn
  description = "Fluent Bit IRSA role ARN"
}

# ─── KMS ──────────────────────────────────────────────────────────────────────
output "kms_key_arn" {
  value       = aws_kms_key.eks.arn
  description = "KMS key ARN used for EKS secrets and EBS"
}
