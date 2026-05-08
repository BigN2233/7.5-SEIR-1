#This is subnet 1 for VPC main

resource "google_compute_subnetwork" "safehouse" {
  name                     = "safehouse-subnet"
  ip_cidr_range            = "10.1.0.0/23"
  region                   = "us-east4"
  network                  = data.google_compute_network.default.id
  private_ip_google_access = true

  depends_on = [
    data.google_compute_network.default
  ]
}