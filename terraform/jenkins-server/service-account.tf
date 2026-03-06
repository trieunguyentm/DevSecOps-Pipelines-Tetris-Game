# ==============================================================================
# FILE: service-account.tf
# MỤC ĐÍCH: Tạo Service Account và gán quyền (roles) cho Jenkins VM
# THỨ TỰ CHẠY: Tạo TRƯỚC main.tf vì VM cần attach SA
# ==============================================================================
#
# SO SÁNH VỚI AWS GỐC:
#   AWS cần 3 resources riêng biệt:
#     1. aws_iam_role            — tạo IAM Role
#     2. aws_iam_policy          — gắn Policy (AdministratorAccess)
#     3. aws_iam_instance_profile — tạo Instance Profile để gắn vào EC2
#
#   GCP chỉ cần:
#     1. google_service_account      — tạo Service Account
#     2. google_project_iam_member   — gắn role (có thể nhiều role)
#     → Không cần "instance profile" — SA gắn thẳng vào VM
#
# TẠI SAO CẦN SERVICE ACCOUNT?
#   - Jenkins VM cần quyền để: tạo GKE cluster, quản lý Compute Engine, push Docker images
#   - Thay vì đặt credentials (JSON key) lên VM → gắn SA vào VM
#   - VM tự động có quyền của SA khi gọi Google Cloud API
#   - An toàn hơn: không có file key nào trên VM có thể bị lộ
# ==============================================================================


# ===== 1. TẠO SERVICE ACCOUNT =====
# Service Account = "tài khoản" dành riêng cho máy (không phải người dùng)
# Giống như tạo 1 "nhân viên ảo" trên GCP, rồi giao việc cho nó

resource "google_service_account" "jenkins_sa" {
  account_id   = var.service_account_id   # ID: jenkins-vm-sa
  display_name = "Jenkins Server Service Account"
  description  = "Service Account attached to Jenkins VM for managing GKE, GCR, etc."
  # Email tự động sinh: jenkins-vm-sa@<project-id>.iam.gserviceaccount.com
}


# ===== 2. GÁN QUYỀN (ROLES) CHO SERVICE ACCOUNT =====
#
# Mỗi "google_project_iam_member" = 1 lần gán role
# Cú pháp member: "serviceAccount:<email>"
#
# Ở AWS gốc: Gán 1 policy "AdministratorAccess" (full quyền — không an toàn)
# Ở GCP:     Gán TỪNG role cụ thể (principle of least privilege)
#
# BẢNG QUYỀN:
# ┌──────────────────────────────────────────┬──────────────────────────────────────────────┐
# │ Role                                     │ Cho phép làm gì                              │
# ├──────────────────────────────────────────┼──────────────────────────────────────────────┤
# │ roles/compute.admin                      │ Tạo/xóa/sửa VM, disk, network               │
# │ roles/container.admin                    │ Tạo/xóa/sửa GKE cluster                     │
# │ roles/iam.serviceAccountUser             │ SỬ DỤNG SA khác (cần khi tạo VM/GKE)        │
# │ roles/iam.serviceAccountAdmin            │ TẠO/XÓA/SỬA SA (cần tạo GKE Node SA)       │
# │ roles/storage.admin                      │ Đọc/ghi GCS bucket (Terraform state)         │
# │ roles/artifactregistry.admin             │ Push/pull Docker images (nếu dùng)           │
# │ roles/resourcemanager.projectIamAdmin    │ GÁN roles cho SA khác (IAM bindings)         │
# └──────────────────────────────────────────┴──────────────────────────────────────────────┘

# --- Role 1: Compute Admin ---
# Jenkins cần quyền này để: quản lý VM, tạo thêm instance nếu cần
resource "google_project_iam_member" "jenkins_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
  # ${...} = lấy email của SA vừa tạo ở trên (Terraform tự resolve)
}

# --- Role 2: Kubernetes Engine Admin ---
# Jenkins cần quyền này để: tạo GKE cluster ở Step tiếp theo
resource "google_project_iam_member" "jenkins_gke_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# --- Role 3: Service Account User ---
# Cần để VM có thể "dùng" SA khi tạo các resource khác
resource "google_project_iam_member" "jenkins_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# --- Role 4: Storage Admin ---
# Jenkins cần quyền này để: đọc/ghi Terraform state trên GCS bucket
resource "google_project_iam_member" "jenkins_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# --- Role 5: Artifact Registry Admin ---
# Jenkins cần quyền này để: push/pull Docker images (nếu dùng GCP registry thay DockerHub)
resource "google_project_iam_member" "jenkins_artifact_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# --- Role 6: Service Account Admin ---
# Jenkins cần quyền này để: TẠO Service Account mới (ví dụ: GKE Node SA ở Step 5)
# Khác với Role 3 (serviceAccountUser = chỉ SỬ DỤNG SA có sẵn)
# Role này = QUẢN LÝ SA (tạo, xóa, sửa)
resource "google_project_iam_member" "jenkins_sa_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# --- Role 7: Project IAM Admin ---
# Jenkins cần quyền này để: GÁN roles cho SA khác (ví dụ: gán roles cho GKE Node SA)
# Quyền cần: resourcemanager.projects.getIamPolicy + setIamPolicy
# Dùng khi Terraform chạy google_project_iam_member cho GKE node SA
resource "google_project_iam_member" "jenkins_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}
