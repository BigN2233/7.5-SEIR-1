Q & A
    
    Q: What is the difference between high availability and fault tolerance? Which is best to strive for?

    A: High availability is how quickly you can get systems or services back up after failure while fault tolerance is making sure there's no downtime if something fails, things will keep running as normal.
    
    Q: Explain the difference between autoscaling and elasticity. What is vertical and horizontal autoscaling? Is one better? Are they feasible on prem?

    A: Autoscaling is the action of adding or deleting resources automatically as needed while elasticity is the concept or theory of a system or service to do so. Vertical autoscaling increases or reduces component capacity of a resource that's running while horizontal autoscaling increases or decreases the amount of current of instances running. Think quality versus quantity. 
    
    Q: Explain what the difference between managed and unmanaged instance groups is.

    A: A managed instance group (MIG) is several identical VMs that are handled autonoumously using a instance template. It allows for autoscaling and autohealing of VMs. An unmanaged instance group (UMIG) is a manually managed group of VMs where some of the VMs may differ from each other. A template isn't used for a UMIG, also autoscaling and autohealing aren't available for UMIGs either. 

    Q: Explain the different use cases for health checks used by applications (in instance groups) and health checks used by load balancers. Can they be the same? Are they different API calls? Should they be the same?

    A: So the health checks used by applications in an instance group will be used to replace VMs deemed unhealthy by the health check. The health checks used by load balancers are used to determine where to route traffic for example if a VMs is down or having issues the load balancer will see the failed health check and either not send traffic to that failed VM or reroute traffic from that VM to another that is healthy. If you want to be technical, yes, they can be the same but I wouldn't make them the same as it can cause issues. Yes, again technically the API calls are the same, but how they are used will be different, and the resources they will use will be different. It's fine that the API call is the same since what they'll be attached to will be different.
    
    Q: Explain in a few sentences what the 3 tier architecture is and how it relates to what you are learning.

    A: A 3 tier architecture is a setup that uses a web tier, an application tier, and a database tier. The web tier handles everything internet related such as static content, HTTPS, load balancing etc. It receives the user requests. The appication tier is where the user requests gets handled. The application tier usually uses API calls to handle processing of services to handle the user request. The database tier is exactly what is sounds like, it's where the data is stored through databases. Currently we are learning to build all three seperately to learn how they function and then combining them to set up an infrastructure that can be maintained easily and can grow without too many issues in the future.   



RUNBOOK

    The endgoal is to establish an instance group through the use of the Google Cloud console that will have complete functional VMs that can be automatically managed. 

    PREREQUISITES:
        - Setup Google Cloud Account
        - An instance template
        - Compute engine enabled

    1.  Log into your Google cloud account and select your project.
    2.  Go to the instance template page under the compute engine section
    3.  Click create instance template.
    4.  Name your template or leave it as the default name as long as you can remember what it will be used for.
    5.  Select your location as regional.
    6.  Select the region where you want to populate the VMs. Choose us-central1 for now.
    7.  Choose a machine type under machine configuration. For now choose E2.
    8.  Select your boot disk type or image. For now leave everything default (Debian GNU/Linux 12)
    9.  Scroll down to the firewall section and select "Allow HTTP traffic"
    10. Open the advance options section and then the management section.
    11. Under the automation section where it says startup script you can copy and enter the script from this link https://github.com/BigN2233/SEIR-1/blob/main/weekly_lessons/weeka/userscripts/supera.sh. This script will help spin up a VM that will give you your metadata/attributes related to your VM such as instance name, IP, and location. It will confirm if you have a healthy functioning VM.
    12. Click create.
    13. Now go to the instance group section and select create instance group.
    14. Leave on the default selection of "New managed instance group (stateless)". Change your instance group name.
    15. In the image template section choose the template you have created.
    16. Click the configure autoscaling button. In the minimum number of instances put 4 and in the maximum put 6.
    17. Under VM lifecycle leave the "Default action on failure" as "Repair Instance". Under the Autohealing section select the "Health check" drop down and choose "Create a health check".
    18. Name your health check. Choose regional for the scope. You can turn on logging if you want, but it will cost you. Leave everything default and select save. You can ignore the warning that will pop up after for now. Select create in the lower left corner.
    19. After being redirected to the instance groups page, you will see your group being spun up. After the status turns into a green check click the instance group you created. Inside you will see the information for the VMs that were spun up. If you look at the zone section you will see the zones the instances are located in. If you see different zones then it's verified that instance group is handling the instances across multiple zones.

TERRAFORM 

    The mandatory arguments for a VM in terraform are:
        name: the name the VM will be called
        machine_type:  the type the VM instance will be (i.e. E2 , N1)
        boot_disk (block of code):  the image you want installed on your VM (i.e. Centos, Debian)
        network_interface (block of code):  the IP(s) you want to assign to the VM(s)


    You can display the external and internal IP addresses of the the provisioned VM with an output block. For example below:

        output "external_ip" {
             value = google_compute_instance.vm_name.network_interface[0].access_config[0].nat_ip
        }

        output "internal_ip" {
                value = google_compute_instance.vm_name.network_interface[0].network_ip
        }

        The main terraform site explains the output block as a whole and the types of things that can be referenced. https://developer.hashicorp.com/terraform/language/block/output

        The terraform registry for google lays out what values to refernce for the VM IPs in the attribute reference section. https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#attributes-reference

        There are arguments that you can use that are non-required such as:
            zone:  where in the region you want your VM to be located (i.e. us-central1-a)
            deletion_protection: prevents the instance from being deleted

        For figuring out the correct format for creating a VM with the "centOS stream 10" image go the terraform registry and look up the boot_disk block section under google_compute_instance. In the boot_disk section look into the initialize_params block section. This will explain what is needed to reference the image under the "image" argument which is usually done in the project/family format however other format examples are provided in the documentation as well. Next to get the list of images that can be used open your gcloud terminal and type the command "gcloud compute images list". At the top of the list you will see a few selections for centos-stream-10. For now let's choose the non-arm64 version. Back in our terraform code in the boot_disk block we will enter:

            boot_disk {
                initialize_params {
                    image = "centos-cloud/centos-stream-10"
                    size  = 10
                }
            }

            The size argument above is just to give how many GB you want the image to be. If you don't include it then it will default to whatever that image's normal size as.

        
        The "name" argument is different from the "id" and "self_link" attributes it this manner:
            name:  a unique identifier that is required but given by the developer of the code
            id:  is the identifier that is given by Terraform to reference a resource in the code and is found in the state file.
            self_link:  a URI that is set by GCP to reference a resource in the code and is also found in the state file.


RESOURCES

    - https://docs.cloud.google.com/compute/docs/instance-templates/create-instance-templates
    - https://docs.cloud.google.com/compute/docs/instance-groups#managed_instance_groups
    - https://docs.cloud.google.com/load-balancing/docs/application-load-balancer#three-tier_web_services
    - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#nested_boot_disk
    - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#deletion_protection-1
    - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
    - https://developer.hashicorp.com/terraform/language/block/output
    - Professional Cloud Architect –Google Cloud Certification Guide by Cłapa and Gerrard (2nd ed.)
    - Terraform for Google Cloud Essential Guide by Nordhausen
    
