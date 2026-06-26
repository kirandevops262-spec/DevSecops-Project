locals {
  org  = "medium"
  env  = var.env
  name = "${var.env}-${local.org}-${var.cluster_name}"
}

module "eks" {
  source = "../module/eks"

  env        = var.env
  aws_region = var.aws_region

  # Network — resolved from VPC tags, not passed as variables
  vpc_name = "${local.env}-${local.org}-${var.vpc_name}"
  eks_sg   = var.eks_sg

  # Cluster
  cluster_name    = local.name
  cluster_version = var.cluster_version

  # Node group
  ondemand_instance_types = var.ondemand_instance_types
  desired_capacity        = var.desired_capacity
  min_capacity            = var.min_capacity
  max_capacity            = var.max_capacity
  node_volume_size        = var.node_volume_size

  # Addons
  addons = var.addons
}
