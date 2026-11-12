# Reserved IP for the Access Server (static public IP that you can move between Droplets)
resource "digitalocean_reserved_ip" "access_server" {
  count  = var.use_reserved_ip ? 1 : 0
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "access_server" {
  count      = var.use_reserved_ip ? 1 : 0
  ip_address = digitalocean_reserved_ip.access_server[0].ip_address
  droplet_id = digitalocean_droplet.access_server.id
}
