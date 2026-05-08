terraform {
  backend "gcs" {
    bucket = "ntstf"
    prefix = "terraform/state"
  }
}
