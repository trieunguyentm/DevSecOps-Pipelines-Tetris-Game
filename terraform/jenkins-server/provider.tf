# ==============================================================================
# FILE: provider.tf
# MỤC ĐÍCH: Cấu hình Google Cloud Provider — "kết nối" Terraform với GCP
# THỨ TỰ CHẠY: Được đọc sau backend.tf, dùng trong mọi resource
# ==============================================================================

# Block "provider" — cấu hình kết nối đến Google Cloud
#
# Hãy tưởng tượng: Terraform giống như "điều khiển từ xa"
#   - provider.tf = nói cho Terraform biết "điều khiển cái gì" (Google Cloud)
#   - project     = "điều khiển project nào"
#   - region/zone = "ở đâu trên thế giới"
#
# XÁC THỰC (Authentication):
#   Terraform sẽ tự tìm credentials theo thứ tự:
#   1. Biến môi trường GOOGLE_APPLICATION_CREDENTIALS (đường dẫn JSON key)
#   2. Application Default Credentials (ADC) — từ `gcloud auth application-default login`
#   3. Service Account của VM (nếu chạy trên GCP)
#   → Chúng ta dùng ADC (cách 2) vì Org Policy chặn JSON key
#
# Ở AWS gốc: provider "aws" { region = "us-east-1" }
# Ở GCP:     provider "google" { project, region, zone }
#   → GCP cần thêm "project" vì 1 tài khoản Google có thể có nhiều projects

provider "google" {
  project = var.project_id   # GCP Project ID — lấy từ terraform.tfvars
  region  = var.region        # Region mặc định — asia-southeast1 (Singapore)
  zone    = var.zone          # Zone mặc định — asia-southeast1-a
  # Không cần dòng "credentials" — Terraform tự dùng ADC
}
