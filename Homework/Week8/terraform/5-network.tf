#Use the "data" block instead of resource when using the default network or you'll get an error when you run terraform apply

data "google_compute_network" "default" {
  name = "default"
}