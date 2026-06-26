# Changes Applied — Production EKS Hardening

## Removed Components

| Removed | Reason |
|---|---|
| ArgoCD Helm release | Not required for base EKS cluster setup |
| AWS Load Balancer Controller | Removed with ArgoCD dependency |
| Prometheus / Grafana Helm release | Not required for base EKS cluster setup |
| EC2 jump server | Not needed; cluster access handled via VPC-internal tooling |
| EC2 IAM role / instance profile | No EC2 instances to attach to |
| `helm`, `kubernetes`, `time` providers | No Helm or Kubernetes resources remain |
| `delays.tf` (`time_sleep` resources) | Depended on removed Helm releases |
| `iam_policy.json` | Was the LB controller IAM policy file |

---

## Security Hardening Applied

### 1. KMS Encryption for EKS Secrets
- Added `aws_kms_key.eks` with `enable_key_rotation = true` and 30-day deletion window
- Attached to `encryption_config` block on the EKS cluster to encrypt Kubernetes secrets at rest

### 2. Control Plane Logging
- Enabled all 5 log types: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`
- Logs ship to CloudWatch for audit and incident response

### 3. Authentication Mode
- Changed from `CONFIG_MAP` to `API_AND_CONFIG_MAP`
- Supports both legacy ConfigMap and newer EKS access entry API

### 4. IMDSv2 Enforcement via Launch Templates
- Replaced bare `disk_size` on node groups with proper `aws_launch_template` resources
- `http_tokens = "required"` — blocks IMDSv1, prevents SSRF credential theft from pods
- `http_put_response_hop_limit = 1` — prevents pod-level metadata access

### 5. Encrypted EBS Node Volumes
- Node root volumes use `gp3` + KMS encryption via launch template `block_device_mappings`
- Both on-demand and spot node groups covered

### 6. EKS Security Group — Restricted Ingress
- Changed ingress `cidr_blocks` from `0.0.0.0/0` to `var.cidr-block` (VPC CIDR only)
- EKS API server no longer reachable from the public internet at the SG level
- Added `description` fields to ingress/egress rules (Checkov compliance)

### 7. IAM Policy Least Privilege Fix
- OIDC IAM policy previously had `"*"` as both action and resource
- Fixed to only allow `s3:ListAllMyBuckets` and `s3:GetBucketLocation` on `arn:aws:s3:::*`

### 8. Private Endpoint Only
- `endpoint-public-access = false` in `variables.tfvars`
- EKS API server is only reachable from within the VPC

---

## State Backend Hardening

### DynamoDB Locking Added
- Both `vpc-ec2/backend.tf` and `eks/backend.tf` now include `dynamodb_table = "dev-tarak01-tf-lock"`
- Prevents concurrent `terraform apply` runs corrupting state

### State Key Cleanup
- VPC state key: `EKS-Terraform/vpc.tfstate`
- EKS state key: `EKS-Terraform/eks.tfstate`
- Removed old `EKS-ArgoCD-AWS-LB-Controller-Terraform/` prefixed keys

---

## Checkov Integration

### `.checkov.yaml`
- Scans `eks/`, `vpc-ec2/`, and `module/` directories
- Enforces 21 checks across EKS, KMS, IAM, SG, S3, and DynamoDB
- Run locally: `checkov --config-file .checkov.yaml`

### GitHub Actions — `.github/workflows/checkov.yml`
- Triggers on every push and pull request to `main`/`master`
- Installs Checkov and runs the full scan
- Uploads scan artifacts on completion
- All PRs must pass before merging

---

## Current Deployment Order

1. `vpc-ec2/` — VPC, subnets, NAT gateway, EKS security group
2. `eks/` — EKS cluster, node groups (on-demand + spot), OIDC provider, EBS CSI driver, addons
