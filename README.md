
# DevSecOps CI/CD Pipeline — Example Voting App

## Overview

A complete DevSecOps pipeline deploying a microservices-based voting application on AWS EC2 using industry-standard tools.

## Application Architecture

The voting app consists of 5 microservices:

- **vote** — Python Flask frontend for casting votes

- **result** — Node.js frontend showing real-time results  

- **worker** — .NET service processing votes from Redis to Postgres

- **redis** — Message queue for incoming votes

- **postgres** — Persistent database for vote storage

## Tech Stack

| Layer | Tool |

|-------|------|

| Containerization | Docker |

| Infrastructure | Terraform |

| Configuration | Ansible |

| Orchestration | Kubernetes (microk8s) |

| CI Pipeline | GitHub Actions |

| CD Pipeline | ArgoCD |

| Security Scanning | Trivy + OWASP Dependency Check |

| Cloud | AWS EC2 (us-east-1) |

## Repository Structure├── vote/ # Python voting app + Dockerfile ├── result/ # Node.js results app + Dockerfile├── worker/ # .NET worker service + Dockerfile ├── terraform/ # AWS infrastructure as code │ ├── main.tf # VPC, subnet, security group, EC2 │ ├── variables.tf # Instance type, region, AMI │ └── outputs.tf # Public IP and DNS outputs ├── ansible/ # Configuration management │ ├── inventory.ini # EC2 host configuration │ └── setup.yml # microk8s installation playbook ├── kubernetes/ # Kubernetes manifests │ ├── vote-deployment.yaml │ ├── result-deployment.yaml │ ├── worker-deployment.yaml │ ├── redis-deployment.yaml │ └── db-deployment.yaml ├── argocd/ # ArgoCD CD configuration │ └── application.yaml # Auto-sync application manifest └── .github/workflows/ # CI/CD pipeline └── ci.yml # Build, scan, push, update manifests## Deployment Guide

### Prerequisites

```bash

# Required tools

terraform --version    # v1.7.5+

ansible --version      # v2.20+

docker --version       # v27+

aws --version          # v2.34+

kubectl version --client

# Configure AWS

aws configure

# Enter: Access Key, Secret Key, region: us-east-1

```

### Phase 1 — Create AWS Key Pair

```bash

aws ec2 create-key-pair \

  --key-name devops-key \

  --query 'KeyMaterial' \

  --output text > ~/.ssh/devops-key.pem

chmod 400 ~/.ssh/devops-key.pem

```

### Phase 2 — Provision Infrastructure (Terraform)

```bash

cd terraform/

terraform init

terraform plan

terraform apply

# Note the output public IP

```

Resources created:

- VPC with CIDR 10.0.0.0/16

- Public subnet + Internet Gateway

- Security Group (ports 22, 8080, 30080, 31000, 31001)

- EC2 t3.micro instance (Ubuntu 22.04)

### Phase 3 — Configure EC2 (Ansible)

```bash

# Update inventory.ini with your EC2 IP

cd ansible/

ansible -i inventory.ini voting_app -m ping

ansible-playbook -i inventory.ini setup.yml

```

Ansible installs:

- Docker

- microk8s (Kubernetes)

- Enables dns, storage, ingress addons

### Phase 4 — Kubernetes Manifests

```bash

# Copy manifests to EC2

scp -i ~/.ssh/devops-key.pem kubernetes/*.yaml ubuntu@<EC2-IP>:~/

# SSH and apply

ssh -i ~/.ssh/devops-key.pem ubuntu@<EC2-IP>

sudo microk8s kubectl apply -f ~/

sudo microk8s kubectl get pods

```

### Phase 5 — CI/CD Pipeline

#### GitHub Actions (CI)

Triggers automatically on every push to main branch:

1. **Security Scan** — Trivy filesystem scan + OWASP dependency check

2. **Build Vote Image** — Docker build + push + Trivy image scan

3. **Build Result Image** — Docker build + push + Trivy image scan  

4. **Build Worker Image** — Docker build + push + Trivy image scan

5. **Update Manifests** — Updates image tags in kubernetes/ folder

Required GitHub Secrets:

- `DOCKERHUB_USERNAME` — Docker Hub username

- `DOCKERHUB_TOKEN` — Docker Hub access token (Read & Write)

#### ArgoCD (CD)

```bash

# On EC2 — download and install ArgoCD

curl -L -o argo.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo microk8s kubectl create namespace argocd

sudo microk8s kubectl apply -n argocd -f argo.yaml --request-timeout=300s

# Expose ArgoCD UI

sudo microk8s kubectl patch svc argocd-server -n argocd \

  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8080,"nodePort":30080,"protocol":"TCP","name":"http"}]}}'

# Apply voting app to ArgoCD

sudo microk8s kubectl apply -f argocd/application.yaml

# Get admin password

sudo microk8s kubectl -n argocd get secret argocd-initial-admin-secret \

  -o jsonpath="{.data.password}" | base64 -d

```

Access ArgoCD UI: `http://<EC2-IP>:30080`

- Username: `admin`

- Password: from command above

ArgoCD auto-syncs kubernetes/ folder from GitHub on every commit.

## Security Tools

| Tool | Stage | Purpose |

|------|-------|---------|

| Trivy | CI | Container image + filesystem vulnerability scanning |

| OWASP Dependency Check | CI | Known CVE scanning in dependencies |

| GitHub Actions Gates | CI | Blocks deployment if critical vulnerabilities found |

## Application Access

After deployment:

- **Vote App**: `http://<EC2-IP>:31000`

- **Result App**: `http://<EC2-IP>:31001`

- **ArgoCD UI**: `http://<EC2-IP>:30080`

## Infrastructure Notes

> The project uses AWS free tier (t3.micro, 1GB RAM). microk8s requires

> minimum 2GB RAM for stable operation with ArgoCD. A 2GB swap file

> is added to compensate for memory constraints.

## Cleanup — Important!

```bash

# Destroy all AWS resources to avoid charges

cd terraform/

terraform destroy

```

