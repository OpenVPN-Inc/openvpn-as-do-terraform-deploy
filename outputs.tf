locals {
  access_server_public_ip = var.use_reserved_ip ? digitalocean_reserved_ip.access_server[0].ip_address : digitalocean_droplet.access_server.ipv4_address
}

output "admin_ui_url" {
  description = "OpenVPN Access Server Admin Web UI URL"
  value       = "https://${local.access_server_public_ip}:943/admin"
}

output "client_ui_url" {
  description = "OpenVPN Access Server Client Web UI URL"
  value       = "https://${local.access_server_public_ip}:943"
}

output "public_ip_address" {
  description = "Public IP address of the Access Server (the Reserved IP when use_reserved_ip is true)"
  value       = local.access_server_public_ip
}

output "ipv6_address" {
  description = "Public IPv6 address of the Access Server (null when enable_ipv6 is false)"
  value       = var.enable_ipv6 ? digitalocean_droplet.access_server.ipv6_address : null
}

output "droplet_id" {
  description = "ID of the Access Server Droplet"
  value       = digitalocean_droplet.access_server.id
}

output "ssh_command" {
  description = "Command to connect to the Droplet over SSH (the root user, SSH key only)"
  value       = "ssh root@${local.access_server_public_ip}"
}

output "ssh_private_key" {
  description = "Generated SSH private key (null unless generate_ssh_key is true). Save it with: terraform output -raw ssh_private_key > key.pem"
  sensitive   = true
  value       = var.generate_ssh_key ? tls_private_key.access_server[0].private_key_openssh : null
}

output "openvpnas_credentials" {
  description = "OpenVPN Access Server Admin Credentials"
  sensitive   = true
  value = {
    admin_account  = var.admin_username
    admin_password = local.admin_password
  }
}
