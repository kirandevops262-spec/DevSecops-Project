# ─── General ──────────────────────────────────────────────────────────────────
variable "env" {
  type        = string
  description = "Environment name (prod, staging, dev)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

# ─── Network ──────────────────────────────────────────────────────────────────
variable "vpc_name" {
  type        = string
  description = "Name tag of the VPC to deploy EKS into"
}

variable "eks_sg" {
  type        = string
  description = "Name of the EKS cluster security group"
}

# ─── EKS Cluster ──────────────────────────────────────────────────────────────
variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
}

# ─── Node Group ───────────────────────────────────────────────────────────────
variable "ondemand_instance_types" {
  type        = list(string)
  description = "EC2 instance types for on-demand node group"
  default     = ["t3.medium"]
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of nodes"
  default     = 2
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of nodes"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of nodes"
  default     = 5
}

variable "node_volume_size" {
  type        = number
  description = "Root EBS volume size in GB"
  default     = 50
}

# ─── Addons ───────────────────────────────────────────────────────────────────
variable "addons" {
  type = list(object({
    name    = string
    version = optional(string)
  }))
  description = "List of EKS managed addons"
  default     = []
}
