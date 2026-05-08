resource "google_compute_instance" "vm" {
  name         = "lab-vm"
  machine_type = "n1-standard-1"
  zone         = "us-east4-a"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-stream-10"
      size  = 100
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.safehouse.id

    # How to establish External IP (also for SSH use)
    access_config {}
  }

  metadata = {
    startup-script = <<-EOT
#!/usr/bin/bash
META="http://metadata.google.internal/computeMetadata/v1/instance"
HEADER="Metadata-Flavor: Google"
NAME=$(curl -H "$HEADER" "$META/name")
IP=$(curl -H "$HEADER" "$META/network-interfaces/0/ip")
dnf install -y httpd
cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html>
<body>
  <h1>VM Metadata</h1>
  <h2>Instance Name: $NAME</h2>
  <h2>Internal IP: $IP</h2>
  <h2>Colombian prize included for free!</h2>
  <figure>
    <img src="https://test-1256099743.s3.us-east-2.amazonaws.com/Colombian/imgi_22_551283556_24677511425231259_7293143846320648055_n.jpg" alt="Colombian prize!" style="max-width:600px; width:100%; display:block; margin:1rem 0;">
    <figcaption>Colombian prize!</figcaption>
  </figure>
</body>
</html>
HTML
systemctl enable --now httpd
until systemctl is-active --quiet httpd; do
  echo "Waiting for httpd to start..."
  sleep 5
done
EOT
  }

  depends_on = [
    google_compute_subnetwork.safehouse,
    google_compute_router_nat.nat
  ]
}