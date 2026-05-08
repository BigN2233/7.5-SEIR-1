# BGP can only go up to 65534 and must be assigned a unique number from the other bgp you have in use.

resource "google_compute_router" "router" {
  name    = "router"
  region  = "us-east4"
  network = data.google_compute_network.default.id

  bgp {
    asn = 64514
  }

  depends_on = [
    data.google_compute_network.default
  ]
}
