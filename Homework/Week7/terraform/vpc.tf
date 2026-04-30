module "vpc" {
    source  = "terraform-google-modules/network/google//modules/vpc"
    version = "~> 18.0"

    project_id   = "nt-7-5class-seir"
    network_name = "module-vpc"

    shared_vpc_host = false

    subnets = [
        {
            subnet_name           = "nate-wk7"
            subnet_ip             = "10.0.10.0/24"
            subnet_region         = "us-east1"
        },
    ]
}