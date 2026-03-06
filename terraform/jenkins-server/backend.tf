# ==============================================================================
# FILE: backend.tf
# MỤC ĐÍCH: Cấu hình Terraform cốt lõi — backend lưu trữ state và khai báo provider
# THỨ TỰ CHẠY: File này được Terraform đọc ĐẦU TIÊN khi chạy `terraform init`
# ==============================================================================

# Block "terraform" — cấu hình chung cho Terraform
# Đây là nơi khai báo:
#   1. Backend: Nơi lưu file terraform.tfstate (trạng thái infrastructure)
#   2. Required version: Phiên bản Terraform tối thiểu
#   3. Required providers: Các plugin cần thiết (ở đây là Google Cloud)
terraform {

  # --- BACKEND ---
  # Backend = nơi Terraform lưu "terraform.tfstate"
  # File tfstate ghi nhớ TẤT CẢ resources đã tạo (VM, VPC, firewall, ...)
  # Nếu không có backend, file tfstate chỉ nằm trên máy local → dễ mất, không share được
  #
  # Ở AWS gốc: Dùng S3 bucket + DynamoDB (để lock state)
  # Ở GCP:     Dùng GCS bucket (tự động có locking, không cần DynamoDB)
  #
  # ⚠️ BẮT BUỘC: Phải tạo bucket này THỦ CÔNG trước khi chạy `terraform init`
  #   Lệnh: gcloud storage buckets create gs://tetris-devsecops-tfstate --location=asia-southeast1
  backend "gcs" {
    bucket = "tetris-devsecops-tfstate"                  # Tên GCS bucket (phải tồn tại trước)
    prefix = "jenkins-server/terraform.tfstate"           # Đường dẫn file state bên trong bucket
  }

  # --- PHIÊN BẢN TERRAFORM ---
  # Yêu cầu Terraform >= 1.3.0 để dùng các tính năng mới
  required_version = ">= 1.3.0"

  # --- PROVIDER (PLUGIN) ---
  # Provider = plugin giúp Terraform giao tiếp với cloud provider
  # "hashicorp/google" = plugin chính thức để quản lý tài nguyên Google Cloud
  # Khi chạy `terraform init`, Terraform sẽ tải plugin này về thư mục .terraform/
  required_providers {
    google = {
      source  = "hashicorp/google"     # Nguồn: registry.terraform.io/hashicorp/google
      version = ">= 5.0.0"            # Phiên bản plugin tối thiểu
    }
  }
}
