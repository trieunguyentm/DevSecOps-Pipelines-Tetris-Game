#!/bin/bash
# Startup script for Jenkins Server on GCP Compute Engine (Ubuntu 22.04)
# Tương đương: tools-install.sh trong bản AWS
# Thay đổi: AWS CLI → gcloud CLI + GKE auth plugin

set -e

echo "===== [1/8] Installing Java ====="
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre
java --version

echo "===== [2/8] Installing Jenkins ====="
# Tải GPG key mới nhất từ Jenkins và lưu dưới dạng binary keyring
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
# Thêm repo với trusted=yes làm fallback nếu key bị rotate
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins || {
  echo "Jenkins install failed with signed key, trying with trusted repo..."
  echo "deb [trusted=yes] https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y jenkins
}

echo "===== [3/8] Installing Docker ====="
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart docker
sudo chmod 777 /var/run/docker.sock

echo "===== [4/8] Running SonarQube Container ====="
docker run -d --name sonarqube -p 9000:9000 --restart=unless-stopped sonarqube:community

echo "===== [5/8] Installing Terraform ====="
sudo apt install -y unzip gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y terraform

echo "===== [6/8] Installing kubectl ====="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
kubectl version --client

echo "===== [7/8] Installing Google Cloud CLI (thay cho AWS CLI) ====="
# Thêm Google Cloud repo
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
  sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update
sudo apt install -y google-cloud-cli
# Plugin xác thực GKE cho kubectl
sudo apt install -y google-cloud-cli-gke-gcloud-auth-plugin

echo "===== [8/8] Installing Trivy ====="
sudo apt-get install -y wget gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | \
  sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

echo "===== All tools installed successfully! ====="
echo "Jenkins URL: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):8080"
echo "SonarQube URL: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):9000"
