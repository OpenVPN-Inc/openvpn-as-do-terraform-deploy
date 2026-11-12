# SSH key for the Droplet. There are three ways to get it:
# 1. generate_ssh_key = true: Terraform generates a key pair
# 2. ssh_public_key: you give the public key content
# 3. ssh_key_fingerprint: you use a key that already exists in your DigitalOcean account
resource "tls_private_key" "access_server" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "ED25519"
}

locals {
  ssh_public_key = var.generate_ssh_key ? trimspace(tls_private_key.access_server[0].public_key_openssh) : var.ssh_public_key
}

resource "digitalocean_ssh_key" "access_server" {
  count      = var.generate_ssh_key || var.ssh_public_key != null ? 1 : 0
  name       = "${local.name}-key"
  public_key = local.ssh_public_key
}

locals {
  ssh_key_fingerprint = var.ssh_key_fingerprint != null ? var.ssh_key_fingerprint : try(digitalocean_ssh_key.access_server[0].fingerprint, null)
}
