data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
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

data "aws_security_group" "eks" {
  name   = var.eks_sg
  vpc_id = data.aws_vpc.this.id
}
