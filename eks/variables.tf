variable "env" {
  type        = string
  description = "Environment name"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_name" {
  type        = string
  description = "VPC name suffix"
}

variable "eks_sg" {
  type        = string
  description = "EKS security group name"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name suffix"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
}

variable "ondemand_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "On-demand node instance types"
}

variable "desired_capacity" {
  type        = number
  default     = 2
  description = "Desired node count"
}

variable "min_capacity" {
  type        = number
  default     = 1
  description = "Minimum node count"
}

variable "max_capacity" {
  type        = number
  default     = 5
  description = "Maximum node count"
}

variable "node_volume_size" {
  type        = number
  default     = 50
  description = "Node EBS volume size in GB"
}

variable "addons" {
  type = list(object({
    name    = string
    version = optional(string)
  }))
  default     = []
  description = "EKS managed addons"
}
