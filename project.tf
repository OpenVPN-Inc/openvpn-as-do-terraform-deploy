# Put the Droplet and the Reserved IP in your existing Project (used only when project_id is set)
resource "digitalocean_project_resources" "access_server" {
  count   = var.project_id != null ? 1 : 0
  project = var.project_id
  resources = concat(
    [digitalocean_droplet.access_server.urn],
    digitalocean_reserved_ip.access_server[*].urn
  )
}
