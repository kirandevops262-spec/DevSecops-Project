output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API endpoint"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN"
}

output "ebs_csi_role_arn" {
  value       = module.eks.ebs_csi_role_arn
  description = "EBS CSI IRSA role ARN"
}

output "lbc_role_arn" {
  value       = module.eks.lbc_role_arn
  description = "Load Balancer Controller IRSA role ARN"
}

output "cluster_autoscaler_role_arn" {
  value       = module.eks.cluster_autoscaler_role_arn
  description = "Cluster Autoscaler IRSA role ARN"
}
