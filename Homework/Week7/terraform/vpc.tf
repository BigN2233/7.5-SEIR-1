module "vpc" {
    source  = "terraform-google-modules/network/google//modules/vpc"
    version = "~> 18.0"

    project_id   = "nt-7-5class-seir"
    network_name = "module-vpc"

    shared_vpc_host = false
}