# ─── General ──────────────────────────────────────────────────────────────────
env        = "prod"
aws_region = "us-east-1"

# ─── VPC ──────────────────────────────────────────────────────────────────────
vpc_cidr_block        = "10.16.0.0/16"
vpc_name              = "vpc"
igw_name              = "igw"
pub_subnet_count      = 3
pub_cidr_block        = ["10.16.0.0/20", "10.16.16.0/20", "10.16.32.0/20"]
pub_availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pub_sub_name          = "subnet-public"
pri_subnet_count      = 3
pri_cidr_block        = ["10.16.128.0/20", "10.16.144.0/20", "10.16.160.0/20"]
pri_availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pri_sub_name          = "subnet-private"
public_rt_name        = "public-route-table"
private_rt_name       = "private-route-table"
eip_name              = "elasticip-ngw"
ngw_name              = "ngw"
eks_sg                = "eks-sg"

# ─── EKS ──────────────────────────────────────────────────────────────────────
cluster_name            = "eks-cluster"
cluster_version         = "1.31"
ondemand_instance_types = ["t3.medium"]
desired_capacity        = 2
min_capacity            = 1
max_capacity            = 5
node_volume_size        = 50

addons = [
  { name = "vpc-cni" },
  { name = "coredns" },
  { name = "kube-proxy" },
  { name = "eks-pod-identity-agent" }
]
