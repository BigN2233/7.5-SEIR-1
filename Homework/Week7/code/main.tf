terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" 
    }
  }
}

provider "google" {
  project = "nt-7-5class-seir"
  region  = "us-east1"
}


# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {
    bucket = "ntstf"
    prefix = "terraform/state"
  }
}

resource "google_compute_disk" "grafana_disk" {
  #depends_on = [terraform_data.preflight_gate]
  name  = "grafana-disk"
  type  = "pd-standard"
  zone  = "us-east1-b"
  size  = 10
}

resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "main" {
  name                            = "main"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false

  #depends_on = [
  #  google_project_service.compute,
  #]
}

resource "google_compute_subnetwork" "private" {
  name                     = "private-subnet"
  ip_cidr_range            = "10.0.10.0/24"
  region                   = "us-east1"
  network                  = google_compute_network.main.id
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = "us-east1"
  network = google_compute_network.main.id

  bgp {
      asn = 65453
  }

  depends_on = [
      google_compute_network.main
  ]
}

resource "google_compute_router_nat" "nat" {
  name   = "nat"
  router = google_compute_router.router.name
  region = "us-east1"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
      name                    = google_compute_subnetwork.private.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat.self_link]

  depends_on = [
      google_compute_router.router
  ]
}

resource "google_compute_address" "nat" {
  name         = "nat"
  region       = "us-east1"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

    depends_on = [google_project_service.compute]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.name

  allow {
      protocol = "tcp"
      ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
      google_compute_network.main
  ]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.main.name

  allow {
      protocol = "tcp"
      ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  depends_on = [
      google_compute_network.main
  ]
}


resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.main.name

  allow {
      protocol = "tcp"
      ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
      google_compute_network.main
  ]
}


resource "google_compute_firewall" "allow_esp" {
  name    = "allow-esp"
  network = google_compute_network.main.name

  allow {
      protocol = "udp"
      ports    = ["500"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
      google_compute_network.main
  ]
}


resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = google_compute_network.main.name

  allow {
      protocol = "tcp"
      ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
      google_compute_network.main
  ]
}

resource "google_compute_instance" "vm" {
  name         = "lab-vm"
  machine_type = "e2-medium"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id

    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y git
    sudo apt-get install -y git nginx

    sudo systemctl enable nginx
    sudo systemctl start nginx


    cd /tmp
    sudo git clone https://github.com/BalericaAI/SEIR-1.git

    sudo chmod +x /tmp/SEIR-1/weekly_lessons/weeka/userscripts/supera.sh
    sudo bash /tmp/SEIR-1/weekly_lessons/weeka/userscripts/supera.sh
  EOT

  tags = ["ssh", "http", "http-server"]

  depends_on = [
    google_compute_subnetwork.private,
    google_compute_router_nat.nat
  ]
}

output "vm_name" {
  description = "Name of the VM"
  value       = google_compute_instance.vm.name
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --zone us-east1-b"
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}