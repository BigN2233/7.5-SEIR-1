resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
    data.google_compute_network.default
  ]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = data.google_compute_network.default.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  depends_on = [
    data.google_compute_network.default
  ]
}

#Security

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
    data.google_compute_network.default
  ]
}

#udp 500

resource "google_compute_firewall" "allow_esp" {
  name    = "allow-esp"
  network = data.google_compute_network.default.name

  allow {
    protocol = "udp"
    ports    = ["500"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
    data.google_compute_network.default
  ]
}

#tcp 3389

resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"] # Lab only

  depends_on = [
    data.google_compute_network.default
  ]
}