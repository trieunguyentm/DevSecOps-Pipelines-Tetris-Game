# ==============================================================================
# FILE: outputs.tf
# MỤC ĐÍCH: Hiển thị thông tin GKE cluster sau khi tạo xong
# ==============================================================================

output "cluster_name" {
  description = "Tên GKE cluster"
  value       = google_container_cluster.gke.name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = google_container_cluster.gke.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location (region)"
  value       = google_container_cluster.gke.location
}

# Lệnh để cấu hình kubectl kết nối đến GKE cluster
# Tương đương AWS: aws eks update-kubeconfig --region us-east-1 --name Tetris-EKS-Cluster
output "kubeconfig_command" {
  description = "Lệnh cấu hình kubectl cho GKE cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gke.name} --region ${google_container_cluster.gke.location} --project ${var.project_id}"
}

output "gke_node_sa_email" {
  description = "Email của GKE Node Service Account"
  value       = google_service_account.gke_node_sa.email
}
