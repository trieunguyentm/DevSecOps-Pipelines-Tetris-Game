# ==============================================================================
# FILE: gke-cluster.tf
# MỤC ĐÍCH: Tạo GKE Cluster + Node Pool
# ==============================================================================
#
# SO SÁNH VỚI AWS EKS:
#   AWS gốc cần 2 file riêng biệt:
#     - eks-cluster.tf    → resource "aws_eks_cluster"
#     - eks-node-group.tf → resource "aws_eks_node_group"
#   Và phải truyền IAM role ARNs, subnet IDs, security group IDs
#
#   GCP gộp lại: 1 cluster + 1 node pool (đơn giản hơn)
#   GKE tự quản lý: control plane IAM, networking, kube-dns, ...
#
# KIẾN TRÚC:
#   GKE Cluster (control plane — Google quản lý, FREE)
#   └── Node Pool (worker nodes — bạn trả tiền)
#       ├── Node 1 (e2-medium)
#       └── Node 2 (e2-medium)
# ==============================================================================

# --- GKE CLUSTER ---
# Tương đương AWS: resource "aws_eks_cluster" "eks-cluster"
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region  # Regional cluster (HA across zones)

  # Xóa default node pool — tạo node pool riêng để quản lý linh hoạt hơn
  # Đây là best practice trên GKE (tương tự AWS managed node groups)
  remove_default_node_pool = true
  initial_node_count       = 1

  # --- Networking ---
  # Tương đương AWS: vpc_config { subnet_ids, security_group_ids }
  network    = data.google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # VPC-native networking (IP aliases) — bắt buộc cho GKE hiện đại
  # Tương đương AWS: EKS VPC CNI plugin (nhưng GCP khai báo rõ ràng hơn)
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"      # Range cho Pod IPs
    services_secondary_range_name = "gke-services"   # Range cho Service IPs
  }

  # --- Deletion Protection ---
  # Tắt để có thể destroy bằng Terraform (bật ON cho production)
  deletion_protection = false

  # Đảm bảo subnet tạo xong trước khi tạo cluster
  depends_on = [google_compute_subnetwork.gke_subnet]
}

# --- GKE NODE POOL ---
# Tương đương AWS: resource "aws_eks_node_group" "eks-node-group"
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.gke.name

  # --- Autoscaling ---
  # Tương đương AWS: scaling_config { desired_size, max_size, min_size }
  initial_node_count = var.node_count    # Số node ban đầu (per zone)

  autoscaling {
    min_node_count = var.node_min_count  # Tối thiểu 1 node
    max_node_count = var.node_max_count  # Tối đa 3 nodes
  }

  # --- Node Config ---
  # Tương đương AWS: instance_types, disk_size, node_role_arn
  node_config {
    machine_type = var.node_machine_type  # e2-medium (= t3a.medium)
    disk_size_gb = var.node_disk_size     # 20 GB

    # Service Account cho nodes
    # Tương đương AWS: node_role_arn = aws_iam_role.NodeGroupRole.arn
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      env = "production"
    }

    tags = ["gke-node", var.cluster_name]
  }

  # Đảm bảo SA và IAM bindings tạo xong trước
  depends_on = [
    google_project_iam_member.gke_node_log_writer,
    google_project_iam_member.gke_node_metric_writer,
    google_project_iam_member.gke_node_monitoring_viewer,
    google_project_iam_member.gke_node_ar_reader,
  ]
}
