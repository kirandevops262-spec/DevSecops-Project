# Private EKS Cluster — Production Terraform Setup

A production-grade private AWS EKS cluster provisioned with Terraform, secured with Checkov static analysis and integrated with GitHub Actions CI.

## 🌟 Overview

This project provisions a fully private EKS cluster on AWS inside a private VPC. There are no jump servers or public-facing workloads. All access to the Kubernetes API server is restricted to within the VPC.

### Key Features

- **Private EKS Cluster** — API server accessible only within the VPC, no public endpoint
- **KMS Encryption** — Secrets encrypted at rest using a customer-managed KMS key with rotation enabled
- **Control Plane Logging** — All 5 log types enabled (`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`)
- **IMDSv2 Enforced** — Node groups use launch templates with `http_tokens = required` and hop limit of 1
- **Encrypted EBS Volumes** — Node root volumes encrypted with KMS via launch templates
- **S3 + DynamoDB Backend** — Remote Terraform state with DynamoDB locking
- **Modular Design** — Separate modules for VPC and EKS, independently deployable
- **Checkov Security Scanning** — Static IaC analysis on every push and pull request via GitHub Actions

## 🏗️ Architecture

```
vpc-ec2/          → Provisions VPC, subnets, NAT gateway, EKS security group
eks/              → Provisions EKS cluster, node groups, OIDC, EBS CSI driver
module/vpc-ec2/   → Reusable VPC module
module/eks/       → Reusable EKS module (KMS, launch templates, IAM roles)
.github/workflows/checkov.yml  → GitHub Actions Checkov CI pipeline
.checkov.yaml     → Checkov check configuration
```

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- An S3 bucket and DynamoDB table for Terraform state:
  - S3 bucket: `dev-tarak01-tf-bucket`
  - DynamoDB table: `dev-tarak01-tf-lock` (partition key: `LockID`, type: `String`)

### Quickstart

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd DevSecops-Project
   ```

2. **Deploy VPC**
   ```bash
   cd vpc-ec2
   terraform init
   terraform validate
   terraform plan -var-file=../variables.tfvars
   terraform apply -auto-approve -var-file=../variables.tfvars
   ```

3. **Deploy EKS Cluster**
   ```bash
   cd ../eks
   terraform init
   terraform validate
   terraform plan -var-file=../variables.tfvars
   terraform apply -auto-approve -var-file=../variables.tfvars
   ```

4. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name prod-medium-eks-cluster
   kubectl get nodes
   ```

## 🔒 Security

| Control | Implementation |
|---|---|
| API server access | Private endpoint only (`endpoint-public-access = false`) |
| Secrets encryption | KMS CMK with automatic rotation |
| Node IMDS | IMDSv2 required, hop limit = 1 |
| EBS volumes | Encrypted with KMS via launch template |
| Control plane logs | All 5 log types → CloudWatch |
| EKS SG ingress | Restricted to VPC CIDR only |
| IAM policies | Least privilege, no wildcard `*` actions |
| Terraform state | Encrypted S3 + DynamoDB locking |
| Static analysis | Checkov on every push/PR via GitHub Actions |

## 🛡️ CI/CD Pipeline — GitHub Actions

The pipeline runs automatically on every push and pull request, and can also be triggered manually with a module selector.

```
[push / PR]                        [manual trigger]
     │                                   │
     ▼                                   ▼
                                  Select module:
                               ┌───────────────┐
                               │ all / vpc-only │
                               │ / eks-only     │
                               └───────────────┘
     │                                   │
     ▼                                   ▼
┌─────────────────────┐
│  1. Checkov Scan    │  ← runs on push, PR AND manual trigger
│     (blocks deploy) │
└────────┬────────────┘
         │ pass
         ▼
┌─────────────────────┐
│  2. VPC Deploy      │  ← push (all) / manual: all, vpc-only
│     vpc-ec2/        │
└────────┬────────────┘
         │ success (VPC is EKS dependency)
         ▼
┌─────────────────────┐
│  3. EKS Deploy      │  ← push (all) / manual: all, eks-only
│     eks/            │
└─────────────────────┘
```

**Module selector behaviour:**

| Trigger | Module input | VPC runs | EKS runs |
|---|---|---|---|
| push to main | — | ✅ | ✅ (after VPC) |
| pull request | — | ❌ | ❌ |
| manual | `all` | ✅ | ✅ (after VPC) |
| manual | `vpc-only` | ✅ | ❌ |
| manual | `eks-only` | ❌ | ✅ (skips VPC) |

**Required GitHub Secrets** (Settings → Secrets → Actions):

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

**Run Checkov locally:**
```bash
pip install checkov
checkov --config-file .checkov.yaml
```

**Checks enforced:** EKS encryption, control plane logging, IMDSv2, KMS rotation, IAM least privilege, SG rules, S3/DynamoDB state backend security.

To skip a specific check, add inline to your `.tf` file:
```hcl
#checkov:skip=CKV_AWS_144:Cross-region replication not required
```

## 📁 State Management

| Layer | S3 Key | DynamoDB Table |
|---|---|---|
| VPC | `EKS-Terraform/vpc.tfstate` | `dev-tarak01-tf-lock` |
| EKS | `EKS-Terraform/eks.tfstate` | `dev-tarak01-tf-lock` |

## Contributing

Open a pull request or file an issue. All PRs must pass the Checkov security scan before merging.

## License

This project is licensed under the [MIT License](LICENSE).
