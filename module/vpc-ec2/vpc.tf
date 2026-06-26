locals {
  cluster_name = var.cluster_name
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
    Env  = var.env
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name                                           = var.igw_name
    Env                                            = var.env
    "kubernetes.io/cluster/${local.cluster_name}"  = "owned"
  }
}

resource "aws_subnet" "public" {
  count                   = var.pub_subnet_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.pub_cidr_block[count.index]
  availability_zone       = var.pub_availability_zone[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "${var.pub_sub_name}-${count.index + 1}"
    Env                                            = var.env
    "kubernetes.io/cluster/${local.cluster_name}"  = "owned"
    "kubernetes.io/role/elb"                       = "1"
  }
}

resource "aws_subnet" "private" {
  count                   = var.pri_subnet_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.pri_cidr_block[count.index]
  availability_zone       = var.pri_availability_zone[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                           = "${var.pri_sub_name}-${count.index + 1}"
    Env                                            = var.env
    "kubernetes.io/cluster/${local.cluster_name}"  = "owned"
    "kubernetes.io/role/internal-elb"              = "1"
  }
}

resource "aws_eip" "ngw" {
  domain = "vpc"

  tags = {
    Name = var.eip_name
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = var.ngw_name
  }

  depends_on = [aws_eip.ngw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = var.public_rt_name
    Env  = var.env
  }
}

resource "aws_route_table_association" "public" {
  count          = var.pub_subnet_count
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = var.private_rt_name
    Env  = var.env
  }
}

resource "aws_route_table_association" "private" {
  count          = var.pri_subnet_count
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_security_group" "eks" {
  name        = var.eks_sg
  description = "EKS cluster security group - restricts API server access to VPC CIDR only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS from within VPC only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.eks_sg
    Env  = var.env
  }
}
