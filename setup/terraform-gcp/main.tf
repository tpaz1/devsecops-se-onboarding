provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_address" "static_ip" {
  name   = "devsecops-ip-tom"
  region = var.region
}

resource "google_compute_firewall" "allow_nodeport_tom" {
  name    = "allow-nodeport-tom"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["32639", "8080"]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.allowed_ip_ranges
  target_tags = ["allow-nodeport-tom"]
}

resource "google_compute_instance" "devsecops" {
  name         = "devsecops-cloud-tom"
  machine_type = "e2-standard-4"
  zone         = var.zone
  tags         = ["allow-nodeport-tom"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 256
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip       = google_compute_address.static_ip.address
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    ssh-keys = "tomp:${file("~/.ssh/devsecops-key.pub")}"
  }
  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y git docker.io vim build-essential jq python3-pip
    sudo snap install kubectl --classic
    pip3 install jc
    sudo jc dmidecode | jq .[1].values.uuid -r

    sudo cat > /etc/docker/daemon.json <<EOF
    {
      "exec-opts": ["native.cgroupdriver=systemd"],
      "log-driver": "json-file",
      "storage-driver": "overlay2"
    }
    EOF
    sudo mkdir -p /etc/systemd/system/docker.service.d

    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER

    sudo systemctl enable kubelet
    sudo systemctl start kubelet
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc

    echo 'alias k=kubectl' >> ~/.bashrc
    source ~/.bashrc

    sudo apt install openjdk-11-jdk -y
    sudo apt install -y maven
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update
    sudo apt install -y jenkins
    sudo systemctl daemon-reload
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    sudo usermod -a -G docker jenkins
    sudo echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

    git clone https://github.com/tpaz1/kubernetes-devops-security.git
  EOT
}