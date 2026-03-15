# DevSecOps Pipeline — Tetris Game on GCP

A production-grade **DevSecOps CI/CD pipeline** that automates infrastructure provisioning, security scanning, container building, and GitOps-based deployment of a React Tetris game on **Google Kubernetes Engine (GKE)**.

This project demonstrates end-to-end DevSecOps practices: Infrastructure as Code with Terraform, a Jenkins CI pipeline with 4 integrated security scanning layers (SAST, SCA, filesystem, and container image), Docker multi-stage builds, and continuous deployment via ArgoCD following the GitOps model.

---

## Architecture Overview

```
 Developer        GitHub          Jenkins (GCE)       DockerHub        GKE Cluster
    │                │                │                   │                │
    │  git push      │                │                   │                │
    ├───────────────▶│                │                   │                │
    │                │  Build Now     │                   │                │
    │                │◀──────────────┤                   │                │
    │                │  git clone    │                   │                │
    │                ├──────────────▶│                   │                │
    │                │               │                   │                │
    │                │   ┌───────────────────────┐       │                │
    │                │   │  SECURITY SCANNING    │       │                │
    │                │   │  1. SonarQube (SAST)  │       │                │
    │                │   │  2. OWASP (SCA)       │       │                │
    │                │   │  3. Trivy FS Scan     │       │                │
    │                │   └───────────────────────┘       │                │
    │                │               │                   │                │
    │                │   Docker build + push             │                │
    │                │               ├──────────────────▶│                │
    │                │               │                   │                │
    │                │   ┌───────────────────────┐       │                │
    │                │   │  4. Trivy Image Scan  │       │                │
    │                │   └───────────────────────┘       │                │
    │                │               │                   │                │
    │                │  Update manifest (git push)       │                │
    │                │◀──────────────┤                   │                │
    │                │               │                   │                │
    │                │  ArgoCD detects change ───────────────────────────▶│
    │                │               │                   │   kubectl apply│
    │                │               │                   │◀───────────────┤
    │                │               │                   │   Pull image   │
    │                │               │                   │                │
    │  Access app via LoadBalancer External IP           │                │
    │◀───────────────────────────────────────────────────────────────────┤
```

---

## Tech Stack

| Category          | Technology             | Purpose                                                   |
| ----------------- | ---------------------- | --------------------------------------------------------- |
| **Cloud**         | Google Cloud Platform  | Compute Engine, GKE, VPC, IAM, GCS                        |
| **IaC**           | Terraform              | Provision all infrastructure declaratively                |
| **CI Server**     | Jenkins                | Orchestrate build, scan, and deploy pipelines             |
| **CD / GitOps**   | ArgoCD                 | Watch Git manifests, auto-sync to Kubernetes              |
| **SAST**          | SonarQube              | Static code analysis — bugs, vulnerabilities, code smells |
| **SCA**           | OWASP Dependency-Check | Scan npm dependencies against the NVD database            |
| **Scanner**       | Trivy                  | Filesystem scan + Docker image vulnerability scan         |
| **Container**     | Docker                 | Multi-stage builds (Node.js build → Nginx serve)          |
| **Registry**      | DockerHub              | Store and distribute container images                     |
| **Orchestration** | Kubernetes (GKE)       | Run containerized app with rolling updates                |
| **Application**   | React 18               | Tetris game — SPA with hooks-based architecture           |
| **Web Server**    | Nginx                  | Serve static build with gzip and caching                  |
| **SCM**           | GitHub                 | Single source of truth for code, IaC, and manifests       |

---

## Security Scanning — 4 Layers

Every build passes through **4 security gates** before reaching production:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Layer 1: SAST              → SonarQube                    │
│   Static analysis of source code for bugs and smells        │
│                                                             │
│   Layer 2: SCA               → OWASP Dependency-Check       │
│   Scan npm packages for known CVEs in the NVD database      │
│                                                             │
│   Layer 3: Filesystem Scan   → Trivy FS                     │
│   Detect secrets, misconfigurations in source files          │
│                                                             │
│   Layer 4: Image Scan        → Trivy Image                  │
│   Scan final Docker image for OS and app vulnerabilities     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
.
├── game-project/                  # Tetris V1 — React application
│   ├── src/
│   │   ├── components/            # GameController, Board, Cell, GameStats, NextPiece
│   │   ├── hooks/                 # usePlayer, useBoard, useGameStats, useInterval
│   │   ├── utils/                 # Tetrominoes, constants, board helpers
│   │   └── styles/                # Purple cyberpunk theme
│   ├── Dockerfile                 # Multi-stage: node:18-alpine → nginx:alpine
│   └── nginx.conf
│
├── game-project-v2/               # Tetris V2 — Enhanced edition
│   └── src/                       # + Hold piece, combo system, high score (localStorage)
│                                  # + Cyan/Green cyberpunk theme, version badge
│
├── terraform/
│   ├── jenkins-server/            # GCE VM: Jenkins + SonarQube + Docker + Trivy
│   │   ├── main.tf               # Compute Engine instance (e2-standard-8)
│   │   ├── network.tf             # VPC, subnet, firewall rules
│   │   ├── service-account.tf     # IAM service account + 7 roles
│   │   └── scripts/tools-install.sh
│   │
│   └── gke-cluster/               # GKE cluster infrastructure
│       ├── gke-cluster.tf         # Cluster + node pool (2x e2-medium)
│       ├── network.tf             # Subnet with secondary ranges (pods/services)
│       └── service-account.tf     # Node service account + 4 roles
│
├── jenkins-pipelines/
│   ├── Jenkinsfile-GKE-Terraform  # IaC pipeline: plan / apply / destroy GKE
│   ├── Jenkinsfile-TetrisV1       # CI pipeline: scan → build → push → deploy V1
│   └── Jenkinsfile-TetrisV2       # CI pipeline: scan → build → push → deploy V2
│
├── manifest-file/
│   ├── deployment-service.yml     # K8s Deployment (3 replicas) + LoadBalancer Service
│   └── ingress.yaml               # Optional ingress configuration
│
└── docs/                          # Step-by-step implementation guide (9 steps)
```

---

## CI/CD Pipeline Stages

### Infrastructure Pipeline (`Jenkinsfile-GKE-Terraform`)

Parameterized pipeline that manages the GKE cluster lifecycle:

| Stage              | Action                                       |
| ------------------ | -------------------------------------------- |
| Checkout from Git  | Clone Terraform code from GitHub             |
| Terraform Init     | Initialize providers and GCS backend         |
| Terraform Validate | Syntax and configuration validation          |
| Terraform Action   | `plan` / `apply` / `destroy` (user-selected) |
| Configure kubectl  | Fetch GKE credentials (on `apply` only)      |

### Application Pipeline (`Jenkinsfile-TetrisV1` / `V2`)

| #   | Stage                  | Tool               | Description                                       |
| --- | ---------------------- | ------------------ | ------------------------------------------------- |
| 1   | Clean Workspace        | Jenkins            | Remove artifacts from previous builds             |
| 2   | Checkout from Git      | Git                | Clone source code from GitHub                     |
| 3   | SonarQube Analysis     | SonarQube Scanner  | SAST — static code analysis                       |
| 4   | Quality Gate           | SonarQube Webhook  | Block pipeline if quality gate fails              |
| 5   | Install Dependencies   | npm                | `npm install` in project directory                |
| 6   | OWASP Dependency-Check | OWASP + NVD API    | SCA — scan packages for known CVEs                |
| 7   | Trivy File Scan        | Trivy CLI          | Scan source files for secrets and misconfigs      |
| 8   | Docker Image Build     | Docker             | Multi-stage build: React → Nginx                  |
| 9   | Docker Image Push      | Docker + DockerHub | Push tagged image (`tetrisv1:<BUILD_NUMBER>`)     |
| 10  | Trivy Image Scan       | Trivy CLI          | Scan final container image for vulnerabilities    |
| 11  | Update Deployment File | Git + sed          | Update image tag in K8s manifest → push to GitHub |

After stage 11, **ArgoCD** detects the manifest change and automatically syncs the new deployment to the GKE cluster (GitOps).

---

## Infrastructure Resources

### Jenkins Server (Terraform → GCE)

| Resource            | Details                                                                |
| ------------------- | ---------------------------------------------------------------------- |
| Compute Engine VM   | `e2-standard-8` (8 vCPU, 32 GB RAM)                                    |
| VPC + Subnet        | Dedicated network with firewall rules                                  |
| Firewall Rules      | Allow ports 8080 (Jenkins), 9000 (SonarQube), 443, 80                  |
| Service Account     | 7 IAM roles (Compute Admin, GKE Admin, Storage Admin, etc.)            |
| Pre-installed Tools | Jenkins, SonarQube (Docker), Docker, Terraform, kubectl, gcloud, Trivy |

### GKE Cluster (Terraform → GKE, via Jenkins Pipeline)

| Resource        | Details                                                  |
| --------------- | -------------------------------------------------------- |
| GKE Cluster     | Zonal cluster in `asia-southeast1-a`                     |
| Node Pool       | 2× `e2-medium` with autoscaling                          |
| Subnet          | Dedicated subnet with secondary ranges for pods/services |
| Service Account | 4 IAM roles (Logging, Monitoring, Artifact Registry)     |

### Kubernetes Workloads

| Workload   | Namespace | Details                                     |
| ---------- | --------- | ------------------------------------------- |
| ArgoCD     | `argocd`  | GitOps controller watching GitHub manifests |
| Tetris App | `tetris`  | 3 replicas, exposed via LoadBalancer        |

---

## Application — Tetris V1 vs V2

| Feature                   | V1               | V2                         |
| ------------------------- | ---------------- | -------------------------- |
| Theme                     | Purple cyberpunk | Cyan/Green cyberpunk       |
| Hold Piece (C key)        | —                | Yes                        |
| Combo System              | —                | Yes (×1.5 → ×3 multiplier) |
| High Score (localStorage) | —                | Yes                        |
| NEW RECORD animation      | —                | Yes                        |
| Version Badge             | —                | "V2" badge                 |

Both versions share the same React hooks architecture: `usePlayer`, `useBoard`, `useGameStats`, `useInterval`.

---

## GitOps Deployment Flow

```
Jenkins CI Pipeline                    ArgoCD (on GKE)
       │                                     │
       │  Stage: Update Deployment File      │
       │  sed → image: tetrisv1:BUILD#       │
       │  git push → GitHub                  │
       │          │                          │
       │          ▼                          │
       │     GitHub Repo                     │
       │     manifest-file/                  │
       │     deployment-service.yml          │
       │          │                          │
       │          │  ArgoCD polling          │
       │          └─────────────────────────▶│
       │                                     │  Detect: desired ≠ live
       │                                     │  Sync: kubectl apply
       │                                     │  GKE pulls new image
       │                                     │  Rolling update pods
       │                                     ▼
       │                              Tetris App Live
       │                              (LoadBalancer IP)
```

**Key principle:** The Git repository is the **single source of truth**. Jenkins never directly deploys to Kubernetes — it only updates the manifest in Git. ArgoCD handles the actual deployment, ensuring the cluster state always matches what is declared in Git.

---

## Implementation Steps

| Step  | Description                                     | Key Technologies                            |
| ----- | ----------------------------------------------- | ------------------------------------------- |
| **1** | Create GCP Service Account for Terraform        | GCP IAM                                     |
| **2** | Install Terraform and gcloud CLI locally        | Terraform, gcloud                           |
| **3** | Provision Jenkins Server on GCE                 | Terraform, Compute Engine                   |
| **4** | Configure Jenkins (plugins, tools, credentials) | Jenkins                                     |
| **5** | Deploy GKE Cluster via Jenkins Pipeline         | Terraform, GKE                              |
| **6** | Install ArgoCD on GKE                           | ArgoCD, Helm, kubectl                       |
| **7** | Create CI Pipeline and Deploy Tetris V1         | Jenkins, SonarQube, OWASP, Trivy, Docker    |
| **8** | Deploy Tetris V2 (enhanced from V1)             | Jenkins, Docker, ArgoCD                     |
