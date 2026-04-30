STEPS
    
    1. Create a folder that will contain the project associated terraform files. This can be done in the file explorer app by navigating to the directory where you would like to create the file, right clicking with your mouse and selecting create folder (name the folder whatever you want).
    
    2. Open VS Code and select file and then open folder. Navigate to the folder that you just created and then open it.
    
    3. Next select the folder in the explorer tab in VS code and right beside it click the New File button (you can also select File and then click New File at the top left corner of the VS code Window). Name the file main.tf and then click inside of the new window that appears for the file         to get started.
    4. Now inside of the main.tf file we will set up your provider (which cloud service you will be using) and the location where this project will be created. Luckily a guideline of how to set this up is provided by the Hashicorp company at https://registry.terraform.io/browse/providers.           This information gives you guidance on how to use Terraform in accordance with whatever provider you will use. For this example we will be using Google Cloud so select it on the website.
    
    5. Now inside of VS Code on typed this out exactly as entered:

        terraform {
            required_providers {
                google = {
                    source  = "hashicorp/google"
                    version = "~> 5.0" 
                }
            }
        }

This will establish that google cloud will be the provider used for this project.

    6. Underneath that block of code we went enter this block of code:

        provider "google" {
  project = "YOUR PROJECT ID IN YOUR GOOGLE CLOUD"
  region  = "REGION YOU WANT TO PUT THE PROJECT"
}

    Inside of the project you will enter your project ID which will replace the information inside of the " ". 
    For example: project = "my-first-project". The same for region. Example: region = "us-east1". You can get the regions from your google cloud or by searching "google cloud regions" in a search engine. But for now let's use region = "us-east1"

    7. Below that line of code we will enter these two blocks of code:

        terraform {
            backend "gcs" {
                bucket = "UNIQUE BUCKET NAME"
                prefix = "terraform/state"
            }
        }

        resource "google_compute_disk" "grafana_disk" {
            name  = "grafana-disk"
            type  = "pd-standard"
            zone  = "us-east1-b"
            size  = 10
        }
    This will establish storage for the project to use that is called a "bucket". We set the bucket up to have the terraform/state prefix (you can name your prefix whatever you want) so that we can track and organize which bucket goes with which project/objects. A prefix isn't required but highly recommended. It also sets up durable network storage for the virtual machines (VMs) that we will be creating later. Our network storage is the pd-standard type and will be located in the "us-east1-b" zone and 10GB in size. Since the storage is durable that means when we shut down the VM out data will still remain.

    8. Now under the last block of code we will enter:

        resource "google_project_service" "compute" {
            service = "compute.googleapis.com"
            disable_on_destroy = false
        }

    This will set up the compute services for our project so that we can create and run VMs. You can name "compute" whatever you want it doesn't have to be compute but remember whatever name you give it.

    9. Beneath the last block input:

        resource "google_compute_network" "main" {
            name                            = "main"
            routing_mode                    = "REGIONAL"
            auto_create_subnetworks         = false
            mtu                             = 1460
            delete_default_routes_on_create = false
        }

    This will set up the network for our projects so they will have IPs. You can name "main" whatever you want it but for best practice I would make sure you enter the same thing nect to the resource and next to name.

    10. Next we will set up our subnetwork which will determin what IPs we can use for our network we created above. We will create a private subnet:

       resource "google_compute_subnetwork" "private" {
            name                     = "private-subnet"
            ip_cidr_range            = "10.0.10.0/18"
            region                   = "us-east1"
            network                  = google_compute_network.main.id
            private_ip_google_access = true
        }

    11. Next we will establish a Google Cloud Router to automatically update routes when the network setup changes, so you won't manually have to enter static routes by using border gateway protocol (BGP). You can name "router" whatever you want but for best practice again I would make sure you enter the same thing next to the resource and next to name. Also take note of the bgp section. You may enter in a random number between 64512 - 65534 to be assigned to your BGP so that it's not misused if you create another BGP:

        resource "google_compute_router" "router" {
            name    = "router"
            region  = "us-east1"
            network = google_compute_network.main.id

            bgp {
                asn = #####
            }

            depends_on = [
                google_compute_network.main
            ]
        }

    This time we included a dependency to make sure the router can't be build unless the "main" network was built in the previous step.

    12. Now we'll be entering a large block of code below. This will establish NAT gateway router for use the safely connect to the internet while allowing noone from the internet into our private VPC and subnet:

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

    13. Next we will setup our firewall rules for the network We will establish the following protocols which are ssh, http, https, esp (for IPSec VPNs), and rdp:

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

            #Security

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

            #udp 500

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

            #tcp 3389

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

    14. The next step will be entering a block of code that will allow us to spin up a Linux Debian VM to see if our network is built properly and is reachable. :

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


    15. The final block of code we'll enter will let us see the output of the IP address an other important information of the VM that will be created to test if our network is and setup is funcitoning:

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

    16. Now inside of VS code run terraform init, then terraform validate, then terraform plan, and then terraform apply to start terraform, valdate there's nothing major to stop it from running and the formatting is correct, and then finally make the changes to our Google Cloud to spin up our resources needed according to our code. There should be a ssh command to run at the end of of running Terraform apply in the output section. If you're able to connect to the VM then everything is correct.


RESOURCES USED
- Terraform Udemy
- Hashicorp Terraform registry
- BalericaAI/SEIR-1 repository
