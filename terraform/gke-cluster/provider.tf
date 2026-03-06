# ==============================================================================
# FILE: provider.tf
# MỤC ĐÍCH: Cấu hình Google Cloud provider cho GKE cluster
# ==============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
