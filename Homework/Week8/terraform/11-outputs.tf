output "vm_name" {
  description = "Name of the VM"
  value       = google_compute_instance.vm.name
}

output "vm_id" {
  description = "Id of the VM"
  value       = google_compute_instance.vm.id
}

output "self_link" {
  description = "self link to the VM"
  value       = google_compute_instance.vm.self_link
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --zone us-east4-a"
}

output "Wait" {
  value = "VM apache services are booting. Wait 5-10 minutes then visit http://${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}