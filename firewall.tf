# The firewall is assigned by tag, so it is active from the first boot of the Droplet
resource "digitalocean_tag" "access_server" {
  name = local.name
}

resource "digitalocean_firewall" "access_server" {
  name = "${local.name}-firewall"
  tags = [digitalocean_tag.access_server.name]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_allowed_cidrs
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "943"
    source_addresses = var.admin_ui_allowed_cidrs
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = var.https_allowed_cidrs
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1194"
    source_addresses = var.vpn_allowed_cidrs
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
