# ==============================================================================
# FILE: backend.tf
# MỤC ĐÍCH: Cấu hình backend lưu Terraform state cho GKE cluster
# ==============================================================================
#
# GIỐNG Jenkins Server backend.tf nhưng dùng prefix khác
# Cùng 1 GCS bucket, mỗi module có prefix riêng → không bị ghi đè state
#
# Cấu trúc trong bucket:
#   gs://tetris-devsecops-tfstate/
#   ├── jenkins-server/terraform.tfstate   ← Step 3 (Jenkins VM)
#   └── gke-cluster/terraform.tfstate      ← Step 5 (GKE Cluster) ← FILE NÀY
# ==============================================================================

terraform {
  backend "gcs" {
    bucket = "tetris-devsecops-tfstate"
    prefix = "gke-cluster/terraform.tfstate"
  }

  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}
