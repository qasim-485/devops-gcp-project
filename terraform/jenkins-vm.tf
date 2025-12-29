# Jenkins VM Instance
resource "google_compute_instance" "jenkins" {
  name         = "jenkins-server"
  machine_type = var.jenkins_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.gke_subnet.name

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = file("${path.module}/scripts/jenkins-startup.sh")

  tags = ["jenkins", "http-server"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

output "jenkins_public_ip" {
  value = google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip
}