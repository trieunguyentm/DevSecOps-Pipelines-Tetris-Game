# ==============================================================================
# FILE: outputs.tf
# MỤC ĐÍCH: Hiển thị thông tin quan trọng SAU KHI Terraform tạo xong resources
# THỨ TỰ CHẠY: Được xử lý CUỐI CÙNG — sau khi tất cả resources đã tạo
# ==============================================================================
#
# OUTPUT LÀ GÌ?
#   - Output = giá trị Terraform in ra terminal sau khi chạy `terraform apply`
#   - Giúp bạn biết: IP của VM, URL để truy cập Jenkins, lệnh SSH, ...
#   - Xem lại bất kỳ lúc nào: `terraform output`
#   - Xem 1 output cụ thể: `terraform output jenkins_public_ip`
#
# VÍ DỤ OUTPUT TRÊN TERMINAL:
#   Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
#
#   Outputs:
#   jenkins_public_ip    = "34.126.xxx.xxx"
#   jenkins_url          = "http://34.126.xxx.xxx:8080"
#   sonarqube_url        = "http://34.126.xxx.xxx:9000"
#   ssh_command           = "gcloud compute ssh jenkins-server --zone=asia-southeast1-a ..."
# ==============================================================================


# --- Output 1: IP công khai của VM ---
# Dùng để biết IP và truy cập VM
output "jenkins_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip
  # Giải thích đường dẫn dài:
  #   google_compute_instance.jenkins  = VM đã tạo trong main.tf
  #   .network_interface[0]            = card mạng đầu tiên (index 0)
  #   .access_config[0]                = cấu hình IP công khai đầu tiên
  #   .nat_ip                          = địa chỉ IP công khai (NAT IP)
}

# --- Output 2: URL truy cập Jenkins ---
# Copy URL này → paste vào browser → Jenkins Web UI
output "jenkins_url" {
  description = "Jenkins Web UI URL"
  value       = "http://${google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip}:8080"
}

# --- Output 3: URL truy cập SonarQube ---
# SonarQube chạy trên port 9000 (Docker container)
output "sonarqube_url" {
  description = "SonarQube Web UI URL"
  value       = "http://${google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip}:9000"
}

# --- Output 4: Lệnh SSH vào server ---
# Copy lệnh này → paste vào terminal → SSH vào Jenkins VM
# Tương đương AWS: ssh -i "key.pem" ubuntu@<ip>
# Trên GCP:       gcloud compute ssh (không cần PEM key)
output "ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "gcloud compute ssh ${var.instance_name} --zone=${var.zone} --project=${var.project_id}"
}

# --- Output 5: Email của Service Account ---
# Thông tin tham khảo — dùng khi cần gán thêm quyền cho SA sau này
output "service_account_email" {
  description = "Service Account email attached to Jenkins VM"
  value       = google_service_account.jenkins_sa.email
}
