# VPC, created only when no existing VPC is given
resource "digitalocean_vpc" "access_server" {
  count    = var.vpc_uuid == null ? 1 : 0
  name     = "${local.name}-vpc"
  region   = var.region
  ip_range = var.vpc_ip_range
}

locals {
  # Resource names are built from the Droplet name, so you can deploy more than one Access Server
  name     = lower(replace(var.droplet_name, ".", "-"))
  vpc_uuid = var.vpc_uuid != null ? var.vpc_uuid : digitalocean_vpc.access_server[0].id
}
