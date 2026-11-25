output "instance_name" {
  value = google_compute_instance.web.name
}

output "external_ip" {
  value = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "backup_bucket" {
  value = google_storage_bucket.backups.name
}

output "iap_ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.web.name} --zone=${var.zone} --tunnel-through-iap"
}
