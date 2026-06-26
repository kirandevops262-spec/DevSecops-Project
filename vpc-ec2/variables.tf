variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name suffix (used for subnet tags)"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "vpc_name" {
  type        = string
  description = "VPC name suffix"
}

variable "igw_name" {
  type        = string
  description = "Internet gateway name suffix"
}

variable "pub_subnet_count" {
  type        = number
  description = "Number of public subnets"
}

variable "pub_cidr_block" {
  type        = list(string)
  description = "Public subnet CIDR blocks"
}

variable "pub_availability_zone" {
  type        = list(string)
  description = "Public subnet availability zones"
}

variable "pub_sub_name" {
  type        = string
  description = "Public subnet name suffix"
}

variable "pri_subnet_count" {
  type        = number
  description = "Number of private subnets"
}

variable "pri_cidr_block" {
  type        = list(string)
  description = "Private subnet CIDR blocks"
}

variable "pri_availability_zone" {
  type        = list(string)
  description = "Private subnet availability zones"
}

variable "pri_sub_name" {
  type        = string
  description = "Private subnet name suffix"
}

variable "public_rt_name" {
  type        = string
  description = "Public route table name suffix"
}

variable "private_rt_name" {
  type        = string
  description = "Private route table name suffix"
}

variable "eip_name" {
  type        = string
  description = "Elastic IP name suffix"
}

variable "ngw_name" {
  type        = string
  description = "NAT gateway name suffix"
}

variable "eks_sg" {
  type        = string
  description = "EKS cluster security group name"
}
