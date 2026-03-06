# ==============================================================================
# FILE: variables.tf
# MỤC ĐÍCH: Khai báo tất cả biến cho GKE Cluster Terraform
# ==============================================================================
#
# SO SÁNH VỚI AWS EKS:
#   AWS cần 12 biến (vpc-name, igw-name, subnet, sg, iam-role, iam-policy, ...)
#   GCP chỉ cần ~10 biến (đơn giản hơn vì GKE tự quản lý nhiều thứ)
# ==============================================================================

# --- Project & Region ---
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region cho GKE cluster"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-southeast1-a"
}

# --- Network (tham chiếu từ Jenkins VPC đã tạo ở Step 3) ---
# AWS gốc: dùng data source tìm VPC/subnet bằng tag name
# GCP:     tham chiếu trực tiếp bằng tên (đơn giản hơn)
variable "vpc_name" {
  description = "Tên VPC đã tạo ở Step 3 (Jenkins VPC)"
  type        = string
  default     = "jenkins-vpc"
}

variable "gke_subnet_name" {
  description = "Tên subnet riêng cho GKE nodes"
  type        = string
  default     = "gke-subnet"
}

variable "gke_subnet_cidr" {
  description = "CIDR cho GKE nodes subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "gke_pods_cidr" {
  description = "CIDR cho GKE pods (secondary range)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gke_services_cidr" {
  description = "CIDR cho GKE services (secondary range)"
  type        = string
  default     = "10.2.0.0/16"
}

# --- GKE Cluster ---
variable "cluster_name" {
  description = "Tên GKE cluster"
  type        = string
  default     = "tetris-gke-cluster"
}

# --- GKE Node Pool ---
# AWS gốc: t3a.medium (2 vCPU, 4 GB RAM) — desired: 2, max: 3, min: 1
# GCP:     e2-medium   (2 vCPU, 4 GB RAM) — tương đương
variable "node_machine_type" {
  description = "Machine type cho GKE nodes (tương đương AWS t3a.medium)"
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size" {
  description = "Disk size cho mỗi node (GB)"
  type        = number
  default     = 20
}

variable "node_count" {
  description = "Số node mong muốn (desired)"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Số node tối thiểu (autoscaling)"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Số node tối đa (autoscaling)"
  type        = number
  default     = 3
}

variable "gke_sa_id" {
  description = "Service Account ID cho GKE nodes"
  type        = string
  default     = "gke-node-sa"
}
