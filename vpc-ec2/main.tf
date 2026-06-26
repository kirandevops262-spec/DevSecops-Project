locals {
  org = "medium"
  env = var.env
}

module "vpc" {
  source = "../module/vpc-ec2"

  env          = var.env
  cluster_name = "${local.env}-${local.org}-${var.cluster_name}"
  cidr_block   = var.vpc_cidr_block

  vpc_name        = "${local.env}-${local.org}-${var.vpc_name}"
  igw_name        = "${local.env}-${local.org}-${var.igw_name}"
  pub_subnet_count = var.pub_subnet_count
  pub_cidr_block   = var.pub_cidr_block
  pub_availability_zone = var.pub_availability_zone
  pub_sub_name    = "${local.env}-${local.org}-${var.pub_sub_name}"

  pri_subnet_count      = var.pri_subnet_count
  pri_cidr_block        = var.pri_cidr_block
  pri_availability_zone = var.pri_availability_zone
  pri_sub_name          = "${local.env}-${local.org}-${var.pri_sub_name}"

  public_rt_name  = "${local.env}-${local.org}-${var.public_rt_name}"
  private_rt_name = "${local.env}-${local.org}-${var.private_rt_name}"
  eip_name        = "${local.env}-${local.org}-${var.eip_name}"
  ngw_name        = "${local.env}-${local.org}-${var.ngw_name}"
  eks_sg          = var.eks_sg
}
