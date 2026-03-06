# ==============================================================================
# FILE: service-account.tf
# MỤC ĐÍCH: Tạo Service Account riêng cho GKE nodes
# ==============================================================================
#
# SO SÁNH VỚI AWS EKS:
#   AWS gốc cần TẠO RẤT NHIỀU IAM resources:
#     1. EKSClusterRole (IAM Role cho EKS control plane)
#     2. NodeGroupRole  (IAM Role cho EC2 worker nodes)
#     3. 4 Policy attachments:
#        - AmazonEKSClusterPolicy
#        - AmazonEKSWorkerNodePolicy
#        - AmazonEC2ContainerRegistryReadOnly
#        - AmazonEKS_CNI_Policy
#     → Tổng: 2 roles + 4 policy attachments = 6 IAM resources
#
#   GCP đơn giản hơn NHIỀU:
#     1. GKE control plane: Google tự quản lý (không cần tạo SA)
#     2. GKE nodes: Chỉ cần 1 Service Account + vài roles
#     → Tổng: 1 SA + vài IAM bindings
# ==============================================================================

# --- Service Account cho GKE Nodes ---
resource "google_service_account" "gke_node_sa" {
  account_id   = var.gke_sa_id
  display_name = "GKE Node Service Account"
  description  = "Service Account cho GKE worker nodes — quản lý pull images, logging, monitoring"
  project      = var.project_id
}

# --- IAM Roles cho Node SA ---
# Các roles cần thiết để GKE nodes hoạt động bình thường

# 1. Log Writer — ghi logs từ containers lên Cloud Logging
resource "google_project_iam_member" "gke_node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# 2. Metric Writer — ghi metrics lên Cloud Monitoring
resource "google_project_iam_member" "gke_node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# 3. Monitoring Viewer — đọc monitoring data
resource "google_project_iam_member" "gke_node_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# 4. Artifact Registry Reader — pull container images từ Artifact Registry
# Tương đương AWS: AmazonEC2ContainerRegistryReadOnly
resource "google_project_iam_member" "gke_node_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}
