# ==============================================================================
# FILE: main.tf
# MỤC ĐÍCH: Tạo Jenkins Server — Compute Engine VM (tương đương EC2 trên AWS)
# THỨ TỰ CHẠY: Tạo SAU network.tf và service-account.tf
#   (vì VM cần: subnet để kết nối mạng + SA để có quyền)
# ==============================================================================
#
# SO SÁNH VỚI AWS GỐC (ec2.tf):
#   AWS:
#     resource "aws_instance" "ec2" {
#       ami                    = data.aws_ami.ami.image_id    → image
#       instance_type          = "t3a.2xlarge"                → machine_type
#       key_name               = var.key-name                 → OS Login (không cần key)
#       subnet_id              = aws_subnet...id              → subnetwork
#       vpc_security_group_ids = [...]                        → tags (firewall targeting)
#       iam_instance_profile   = ...                          → service_account
#       root_block_device { volume_size = 30 }                → boot_disk { size = 30 }
#       user_data              = templatefile(...)            → metadata_startup_script
#     }
#
# LUỒNG THAM CHIẾU TRONG FILE NÀY:
#   main.tf tham chiếu đến các resource từ file khác:
#     - google_compute_network.vpc.id           ← từ network.tf
#     - google_compute_subnetwork.subnet.id     ← từ network.tf
#     - google_service_account.jenkins_sa.email ← từ service-account.tf
#   Terraform tự phân tích dependencies và tạo theo đúng thứ tự:
#     VPC → Subnet → SA → VM (song song khi có thể)
# ==============================================================================


resource "google_compute_instance" "jenkins" {

  # --- THÔNG TIN CƠ BẢN ---
  name         = var.instance_name   # Tên VM: "jenkins-server" (hiển thị trên GCP Console)
  machine_type = var.machine_type    # Cấu hình: "e2-standard-8" (8 vCPU, 32 GB RAM)
  zone         = var.zone            # Zone: "asia-southeast1-a"

  # --- TAGS ---
  # Tags = nhãn gắn vào VM, dùng để firewall targeting
  # Firewall rule trong network.tf có: target_tags = ["jenkins-server"]
  # → Chỉ VM nào có tag "jenkins-server" mới được áp dụng firewall rule đó
  # Tương đương AWS: vpc_security_group_ids (nhưng cơ chế khác — tag-based)
  tags = ["jenkins-server"]

  # --- Ổ ĐĨA BOOT ---
  # Tương đương AWS: root_block_device + data.aws_ami
  # Ở AWS: Phải dùng data source "aws_ami" để tìm AMI ID mới nhất
  # Ở GCP: Chỉ định trực tiếp image bằng "project/family" hoặc "project/image-name"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      # Giải thích: "ubuntu-os-cloud" = GCP project chứa Ubuntu images (do Canonical quản lý)
      #             "ubuntu-2204-lts" = Image family — GCP tự chọn bản mới nhất của Ubuntu 22.04
      # 💡 Dùng family thay vì tên cụ thể để luôn lấy image mới nhất

      size = var.disk_size   # 30 GB (tương đương volume_size = 30 trên AWS)
      type = "pd-balanced"   # Loại ổ đĩa: pd-balanced (cân bằng hiệu năng/giá)
      # Các loại disk GCP:
      #   pd-standard  = HDD (rẻ, chậm)
      #   pd-balanced  = SSD balanced (khuyên dùng)
      #   pd-ssd       = SSD nhanh (đắt)
    }
  }

  # --- CẤU HÌNH MẠNG ---
  # Tương đương AWS: subnet_id + vpc_security_group_ids
  network_interface {
    network    = google_compute_network.vpc.id        # ← VPC từ network.tf
    subnetwork = google_compute_subnetwork.subnet.id  # ← Subnet từ network.tf

    # access_config = gán External IP (public IP) cho VM
    # Nếu BỎ block này → VM chỉ có internal IP → không truy cập được từ Internet
    # Tương đương AWS: map_public_ip_on_launch = true
    access_config {
      # Để trống = GCP tự cấp Ephemeral (tạm thời) public IP
      # IP này thay đổi mỗi khi VM restart
      # Nếu muốn IP cố định: dùng google_compute_address (static IP)
    }
  }

  # --- SERVICE ACCOUNT ---
  # Tương đương AWS: iam_instance_profile
  # Gắn SA vào VM → VM tự động có quyền của SA khi gọi GCP API
  # Ví dụ: Jenkins chạy lệnh `gcloud container clusters create` → GCP kiểm tra SA có role
  #         roles/container.admin không → có → cho phép tạo GKE cluster
  # ƯU ĐIỂM: Không cần lưu credentials (JSON key) trên VM → an toàn hơn AWS
  service_account {
    email  = google_service_account.jenkins_sa.email  # ← SA từ service-account.tf
    scopes = ["cloud-platform"]
    # scopes = phạm vi API mà VM được phép gọi
    # "cloud-platform" = tất cả GCP APIs (quyền thực tế vẫn do roles quyết định)
  }

  # --- STARTUP SCRIPT ---
  # Tương đương AWS: user_data = templatefile("./tools-install.sh", {})
  # Script này chạy TỰ ĐỘNG khi VM khởi động lần đầu (hoặc khi restart nếu thay đổi)
  # Cài đặt: Java, Jenkins, Docker, SonarQube, Terraform, kubectl, gcloud CLI, Trivy
  # Xem chi tiết: scripts/tools-install.sh
  #
  # file() = đọc nội dung file → chèn vào metadata của VM
  # ${path.module} = đường dẫn thư mục chứa file .tf hiện tại
  metadata_startup_script = file("${path.module}/scripts/tools-install.sh")

  # --- TÙY CHỌN KHÁC ---
  # Cho phép Terraform dừng VM để thay đổi cấu hình (machine_type, disk, ...)
  # Nếu false: Terraform phải XÓA VM cũ → tạo VM mới khi thay đổi
  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
    # OS Login = tính năng quản lý SSH key tự động của GCP
    # Khi TRUE: dùng `gcloud compute ssh jenkins-server` để SSH
    # → Không cần tạo/quản lý PEM key file như AWS
    # → SSH key tự động gắn vào tài khoản Google của bạn
  }
}
