data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc-name]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }

  filter {
    name   = "tag:Env"
    values = [var.env]
  }
}

data "aws_security_group" "eks-cluster-sg" {
  name = var.eks-sg
}
