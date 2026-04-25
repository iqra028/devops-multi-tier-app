
# DevSecOps CI/CD Pipeline — Example Voting App

## 📌 Overview

This project demonstrates a complete **DevSecOps CI/CD pipeline** deploying a microservices-based voting application on AWS using Terraform, Ansible, Kubernetes (MicroK8s), GitHub Actions, and ArgoCD.

---

## 🏗️ Application Architecture

The system consists of **5 microservices**:

| Service | Description |

|---------|-------------|

| `vote` | Python Flask frontend for voting |

| `result` | Node.js frontend showing results |

| `worker` | .NET service processing votes |

| `redis` | Message queue |

| `postgres` | Database for persistent storage |

---

## 🧰 Tech Stack

| Layer | Tool |

|-------|------|

| Containerization | Docker |

| Infrastructure as Code | Terraform |

| Configuration Management | Ansible |

| Orchestration | Kubernetes (MicroK8s) |

| CI/CD Pipeline | GitHub Actions |

| CD Tool | ArgoCD |

| Security Scanning | Trivy + OWASP Dependency Check |

| Cloud Provider | AWS EC2 (Ubuntu 22.04) |

---

## 📁 Repository Structure

```

vote/              → Flask voting app

result/            → Node.js results app

worker/            → .NET worker service

terraform/         → AWS infrastructure (VPC, EC2, SG)

ansible/           → EC2 configuration + MicroK8s setup

kubernetes/        → Kubernetes manifests

argocd/            → ArgoCD application manifest

.github/workflows/ → CI/CD pipeline

```

---

## 🚀 Deployment Steps

### 1️⃣ Prerequisites

Install the required tools:

```bash

terraform --version

ansible --version

docker --version

aws --version

kubectl version --client

```

Configure AWS CLI:

```bash

aws configure

```

---

### 2️⃣ Create Key Pair

```bash

aws ec2 create-key-pair \

  --key-name devops-key \

  --query 'KeyMaterial' \

  --output text > ~/.ssh/devops-key.pem

chmod 400 ~/.ssh/devops-key.pem

```

---

### 3️⃣ Provision Infrastructure (Terraform)

```bash

cd terraform/

terraform init

terraform apply

```

**Creates:**

- VPC + Subnet

- Internet Gateway

- Security Groups

- EC2 instance (t3.micro)

---

### 4️⃣ Configure EC2 (Ansible)

Update `inventory.ini` with your EC2 IP, then run:

```bash

cd ansible/

ansible -i inventory.ini voting_app -m ping

ansible-playbook -i inventory.ini setup.yml

```

**Installs:**

- Docker

- MicroK8s

- Kubernetes addons (DNS, ingress, storage)

---

### 5️⃣ Deploy Kubernetes Manifests

Copy files to EC2:

```bash

scp -i ~/.ssh/devops-key.pem kubernetes/*.yaml ubuntu@<EC2-IP>:~/

```

SSH into EC2:

```bash

ssh -i ~/.ssh/devops-key.pem ubuntu@<EC2-IP>

```

Apply manifests:

```bash

sudo microk8s kubectl apply -f ~/

sudo microk8s kubectl get pods

```

---

### 6️⃣ CI/CD Pipeline (GitHub Actions)

Triggers automatically on every push to `main`:

1. Trivy filesystem scan

2. OWASP Dependency Check

3. Build Docker images

4. Push images to Docker Hub

5. Update Kubernetes manifests

**Required GitHub Secrets:**

| Secret | Description |

|--------|-------------|

| `DOCKERHUB_USERNAME` | Docker Hub username |

| `DOCKERHUB_TOKEN` | Docker Hub access token |

---

### 7️⃣ ArgoCD Deployment

**Install ArgoCD:**

```bash

curl -L -o argo.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo microk8s kubectl create namespace argocd

sudo microk8s kubectl apply -n argocd -f argo.yaml

```

**Expose the UI:**

```bash

sudo microk8s kubectl patch svc argocd-server -n argocd \

  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8080,"nodePort":30080,"name":"http"}]}}'

```

**Apply application manifest:**

```bash

sudo microk8s kubectl apply -f argocd/application.yaml

```

**Get admin password:**

```bash

sudo microk8s kubectl -n argocd get secret argocd-initial-admin-secret \

  -o jsonpath="{.data.password}" | base64 -d

```

---

## 🌐 Application Access

| Service | URL |

|---------|-----|

| Vote App | `http://<EC2-IP>:31000` |

| Result App | `http://<EC2-IP>:31001` |

| ArgoCD UI | `http://<EC2-IP>:30080` |

---

## 🔐 Security Tools

| Tool | Purpose |

|------|---------|

| **Trivy** | Container vulnerability scanning |

| **OWASP Dependency Check** | Library CVE scanning |

| **GitHub Actions** | CI security gates |

---

## ⚠️ Notes

- This project runs on the **AWS Free Tier** (t3.micro).

- Due to limited RAM, MicroK8s + ArgoCD may require **swap memory** and occasional restarts.

---

## 🧹 Cleanup

To destroy all provisioned AWS infrastructure:

```bash

cd terraform/

terraform destroy

```

---

