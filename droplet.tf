resource "digitalocean_droplet" "access_server" {
  name       = var.droplet_name
  image      = local.ubuntu26_image
  size       = var.droplet_size
  region     = var.region
  vpc_uuid   = local.vpc_uuid
  ssh_keys   = [local.ssh_key_fingerprint]
  monitoring = var.enable_monitoring
  backups    = var.enable_backups
  ipv6       = var.enable_ipv6
  user_data  = local.user_data
  tags       = concat([digitalocean_tag.access_server.name], var.tags)

  # Create the firewall before the first boot, so Let's Encrypt and the admin setup run behind it
  depends_on = [digitalocean_firewall.access_server]

  lifecycle {
    precondition {
      condition     = (var.generate_ssh_key ? 1 : 0) + (var.ssh_public_key != null ? 1 : 0) + (var.ssh_key_fingerprint != null ? 1 : 0) == 1
      error_message = "Set exactly one of generate_ssh_key, ssh_public_key, or ssh_key_fingerprint."
    }
  }
}
