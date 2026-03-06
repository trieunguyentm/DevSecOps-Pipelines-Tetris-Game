# ==============================================================================
# FILE: variables.tf
# MỤC ĐÍCH: Khai báo TẤT CẢ biến (variables) dùng trong các file .tf khác
# ==============================================================================
#
# CÁCH HOẠT ĐỘNG CỦA VARIABLES TRONG TERRAFORM:
#
#   1. Khai báo biến ở đây (variables.tf) — tên, kiểu dữ liệu, giá trị mặc định
#   2. Gán giá trị thực tế ở file terraform.tfvars
#   3. Sử dụng trong các file khác bằng cú pháp: var.tên_biến
#
#   Ví dụ:
#     variables.tf:     variable "region" { default = "asia-southeast1" }
#     terraform.tfvars: region = "asia-southeast1"
#     provider.tf:      region = var.region    ← Terraform thay bằng "asia-southeast1"
#
# THỨ TỰ ƯU TIÊN GIÁ TRỊ (cao → thấp):
#   1. Command line: terraform apply -var="region=us-central1"
#   2. File .tfvars:  terraform.tfvars hoặc -var-file=xxx.tfvars
#   3. Default:       giá trị default trong variable block
#   4. Terraform hỏi: nếu không có cả 3 cái trên, Terraform sẽ hỏi khi chạy
# ==============================================================================

# --- THÔNG TIN GCP PROJECT ---

variable "project_id" {
  description = "GCP Project ID — Mã định danh duy nhất của project trên Google Cloud"
  type        = string
  # Không có default → BẮT BUỘC phải khai báo trong terraform.tfvars
  # Ví dụ: "tetris-react-game-123456"
}

variable "region" {
  description = "GCP Region — Khu vực địa lý đặt tài nguyên"
  type        = string
  default     = "asia-southeast1" # Singapore — gần Việt Nam nhất, độ trễ thấp
  # Các region khác gần VN: asia-east1 (Taiwan), asia-east2 (Hong Kong)
}

variable "zone" {
  description = "GCP Zone — Datacenter cụ thể bên trong Region"
  type        = string
  default     = "asia-southeast1-a"
  # Mỗi region có nhiều zones (a, b, c) — đặt nhiều zone để high availability
  # Ở đây chỉ cần 1 zone vì Jenkins server là single instance
}

# --- CẤU HÌNH VM (COMPUTE ENGINE) ---

variable "instance_name" {
  description = "Tên VM Jenkins — hiển thị trên GCP Console"
  type        = string
  default     = "jenkins-server"
}

variable "machine_type" {
  description = "Loại máy (CPU + RAM) — tương đương instance type trên AWS"
  type        = string
  default     = "e2-standard-8"
  # BẢNG SO SÁNH:
  #   AWS t3a.2xlarge    = 8 vCPU, 32 GB RAM  →  GCP e2-standard-8 (8 vCPU, 32 GB)
  #   AWS t3a.xlarge     = 4 vCPU, 16 GB RAM  →  GCP e2-standard-4 (4 vCPU, 16 GB)
  #   AWS t3a.large      = 2 vCPU, 8 GB RAM   →  GCP e2-standard-2 (2 vCPU, 8 GB)
  #
  # 💡 Để tiết kiệm chi phí khi test, đổi thành "e2-standard-4" hoặc "e2-medium"
}

variable "disk_size" {
  description = "Dung lượng ổ đĩa boot (GB) — tương đương root_block_device trên AWS"
  type        = number
  default     = 30
  # 30 GB đủ cho: Ubuntu OS + Jenkins + Docker images + Tools
}

# --- CẤU HÌNH MẠNG (NETWORK) ---

variable "vpc_name" {
  description = "Tên VPC Network — mạng riêng ảo chứa tất cả tài nguyên"
  type        = string
  default     = "jenkins-vpc"
}

variable "subnet_name" {
  description = "Tên Subnet — phân vùng mạng con bên trong VPC"
  type        = string
  default     = "jenkins-subnet"
}

variable "subnet_cidr" {
  description = "Dải IP của Subnet (CIDR notation)"
  type        = string
  default     = "10.0.1.0/24"
  # 10.0.1.0/24 = 256 IP addresses (10.0.1.0 → 10.0.1.255)
  # Tương đương cidr_block trong aws_subnet
}

variable "firewall_name" {
  description = "Tên Firewall Rule — tương đương Security Group trên AWS"
  type        = string
  default     = "jenkins-allow-ports"
}

# --- SERVICE ACCOUNT ---

variable "service_account_id" {
  description = "ID của Service Account gắn vào VM — cho VM quyền truy cập GCP services"
  type        = string
  default     = "jenkins-vm-sa"
  # Service Account = "tài khoản" riêng của VM
  # Tương đương IAM Instance Profile trên AWS
  # VM sẽ tự động có quyền của SA mà KHÔNG cần JSON key
}
