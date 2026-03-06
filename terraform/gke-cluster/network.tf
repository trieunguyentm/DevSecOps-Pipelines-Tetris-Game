# ==============================================================================
# FILE: network.tf
# MỤC ĐÍCH: Tham chiếu VPC từ Jenkins (Step 3) + tạo subnet riêng cho GKE
# ==============================================================================
#
# SO SÁNH VỚI AWS EKS:
#   AWS gốc: Dùng data source tìm VPC, subnet, IGW, SG bằng tag name
#            Tạo thêm subnet 2 ở AZ khác (EKS bắt buộc ít nhất 2 AZ)
#   GCP:     Tham chiếu VPC bằng tên, tạo 1 subnet với secondary ranges
#            GKE KHÔNG bắt buộc multi-zone (tự HA trong 1 region)
#
# KIẾN TRÚC MẠNG:
#   jenkins-vpc (đã tạo ở Step 3)
#   ├── jenkins-subnet  10.0.1.0/24  (Jenkins VM)      ← đã có
#   └── gke-subnet      10.0.2.0/24  (GKE nodes)       ← TẠO MỚI
#       ├── pods range:     10.1.0.0/16  (secondary)
#       └── services range: 10.2.0.0/16  (secondary)
#
# TẠI SAO CẦN SECONDARY RANGES?
#   GKE dùng "VPC-native" networking (IP aliases):
#   - Mỗi Pod được gán 1 IP riêng từ pods range → pod-to-pod communication trực tiếp
#   - Mỗi Service được gán 1 IP riêng từ services range
#   - AWS EKS cũng tương tự nhưng dùng VPC CNI plugin (ẩn bên trong)
# ==============================================================================

# --- Tham chiếu VPC đã tạo ở Step 3 ---
# Tương đương AWS: data "aws_vpc" "vpc" { filter { name = "tag:Name" ... } }
# GCP đơn giản hơn: chỉ cần biết tên
data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.project_id
}

# --- Tạo Subnet riêng cho GKE ---
# Tương đương AWS: resource "aws_subnet" "public-subnet2" (subnet thứ 2 cho EKS)
# Khác biệt: GCP subnet có secondary_ip_range cho pods và services
resource "google_compute_subnetwork" "gke_subnet" {
  name          = var.gke_subnet_name
  ip_cidr_range = var.gke_subnet_cidr    # 10.0.2.0/24 — IP cho GKE nodes
  region        = var.region
  network       = data.google_compute_network.vpc.id
  project       = var.project_id

  # Secondary IP ranges — đặc trưng GKE (AWS EKS không có khái niệm này)
  # GKE cần 2 secondary ranges: 1 cho Pods, 1 cho Services
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.gke_pods_cidr     # 10.1.0.0/16 — ~65,000 pod IPs
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.gke_services_cidr # 10.2.0.0/16 — ~65,000 service IPs
  }
}
