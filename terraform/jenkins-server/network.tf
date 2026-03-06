# ==============================================================================
# FILE: network.tf
# MỤC ĐÍCH: Tạo hạ tầng mạng — VPC, Subnet, Firewall Rules
# THỨ TỰ CHẠY: Tạo TRƯỚC main.tf vì VM cần có mạng để kết nối vào
# ==============================================================================
#
# SO SÁNH VỚI AWS GỐC:
#   AWS cần 5 resources:  VPC → IGW → Subnet → Route Table → Security Group
#   GCP chỉ cần 3:       VPC → Subnet → Firewall Rules
#   → GCP đơn giản hơn vì:
#     - Không cần Internet Gateway (GCP tự route ra internet khi VM có external IP)
#     - Không cần Route Table riêng (GCP tự tạo default routes)
#
# HÌNH DUNG CẤU TRÚC MẠNG:
#   ┌─────────────────────────────────────────┐
#   │ VPC Network (jenkins-vpc)               │
#   │   ┌─────────────────────────────────┐   │
#   │   │ Subnet (10.0.1.0/24)           │   │
#   │   │   ┌─────────────────────────┐   │   │
#   │   │   │ Jenkins VM              │   │   │
#   │   │   │ Internal IP: 10.0.1.x  │   │   │
#   │   │   │ External IP: x.x.x.x   │   │   │
#   │   │   └─────────────────────────┘   │   │
#   │   └─────────────────────────────────┘   │
#   └─────────────────────────────────────────┘
#          ↕ Firewall Rules kiểm soát traffic
#       Internet (ports 22, 8080, 9000)
# ==============================================================================


# ===== 1. VPC NETWORK =====
# VPC (Virtual Private Cloud) = mạng riêng ảo, chứa tất cả tài nguyên
#
# Tương đương AWS: aws_vpc + aws_internet_gateway (2 resources)
# Trên GCP:        google_compute_network (1 resource — đã bao gồm routing)
#
# Cú pháp: resource "loại_resource" "tên_đặt_trong_terraform" { ... }
#   - "google_compute_network" = loại resource (do Google provider cung cấp)
#   - "vpc"                    = tên nội bộ (dùng để tham chiếu trong các file khác)
#   - Tham chiếu: google_compute_network.vpc.id (lấy ID của VPC này)

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name           # Tên hiển thị trên GCP Console
  auto_create_subnetworks = false                  # false = tự tạo subnet thủ công (custom mode)
  # Nếu true: GCP tự tạo 1 subnet cho MỖI region → không cần thiết, tốn tài nguyên
}


# ===== 2. SUBNET =====
# Subnet = phân vùng mạng con bên trong VPC, có dải IP riêng
#
# Tương đương AWS: aws_subnet (với map_public_ip_on_launch = true)
# Trên GCP:        google_compute_subnetwork
#
# Lưu ý: "Public subnet" trên GCP không cần cấu hình đặc biệt
#   → VM sẽ có public IP khi thêm access_config trong main.tf

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name                  # Tên subnet
  ip_cidr_range = var.subnet_cidr                  # Dải IP: 10.0.1.0/24 (256 địa chỉ)
  region        = var.region                       # Subnet thuộc region nào
  network       = google_compute_network.vpc.id    # ← THAM CHIẾU: Subnet thuộc VPC nào
  # google_compute_network.vpc.id = lấy ID của VPC đã tạo ở trên
  # Terraform tự hiểu phải tạo VPC TRƯỚC, rồi mới tạo Subnet
}


# ===== 3. FIREWALL RULES =====
# Firewall = quy tắc cho phép/chặn traffic vào/ra khỏi VM
#
# Tương đương AWS: aws_security_group (1 resource chứa cả ingress + egress)
# Trên GCP:        google_compute_firewall (mỗi rule là 1 resource riêng)
#
# KHÁC BIỆT QUAN TRỌNG:
#   AWS Security Group: Gắn vào VM qua vpc_security_group_ids
#   GCP Firewall:       Gắn vào VM qua "target_tags" (tag-based targeting)
#     → VM có tag "jenkins-server" sẽ được áp dụng firewall rule này
#     → Tag được gán trong main.tf: tags = ["jenkins-server"]

# --- Firewall Rule: Cho phép truy cập từ Internet vào 3 ports ---
# Port 22:   SSH — để remote vào server
# Port 8080: Jenkins Web UI
# Port 9000: SonarQube Web UI

resource "google_compute_firewall" "allow_jenkins_ports" {
  name    = var.firewall_name                      # Tên rule
  network = google_compute_network.vpc.id          # Áp dụng cho VPC nào

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9000"]              # Các port được mở
  }

  source_ranges = ["0.0.0.0/0"]                   # Cho phép từ MỌI IP (toàn bộ Internet)
  target_tags   = ["jenkins-server"]               # Chỉ áp dụng cho VM có tag này

  description = "Allow SSH (22), Jenkins (8080), SonarQube (9000)"

  # ⚠️ BẢO MẬT: source_ranges = ["0.0.0.0/0"] cho phép AI CŨNG truy cập được
  # Trong production, nên giới hạn: source_ranges = ["YOUR_IP/32"]
}


# --- Firewall Rule: Cho phép traffic nội bộ trong subnet ---
# Cho phép các VM trong cùng subnet giao tiếp với nhau

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"        # Tên: jenkins-vpc-allow-internal
  network = google_compute_network.vpc.id           # ${...} = string interpolation

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]                          # Tất cả TCP ports
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]                          # Tất cả UDP ports
  }

  allow {
    protocol = "icmp"                               # Ping
  }

  source_ranges = [var.subnet_cidr]                 # Chỉ từ IP trong subnet (10.0.1.0/24)
  description   = "Allow internal traffic within subnet"
}


# --- Firewall Rule: Cho phép tất cả traffic đi ra (Egress) ---
# GCP mặc định đã cho phép egress, nhưng khai báo rõ ràng để dễ hiểu
# Jenkins cần truy cập Internet để: tải plugins, pull Docker images, push lên DockerHub, ...

resource "google_compute_firewall" "allow_egress" {
  name      = "${var.vpc_name}-allow-egress"
  network   = google_compute_network.vpc.id
  direction = "EGRESS"                              # EGRESS = traffic đi ra (mặc định là INGRESS)

  allow {
    protocol = "all"                                # Cho phép mọi protocol
  }

  destination_ranges = ["0.0.0.0/0"]                # Đi đến bất kỳ đâu
  description        = "Allow all outbound traffic"
}
