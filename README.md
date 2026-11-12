# OpenVPN Access Server Deployment on DigitalOcean Using Terraform

This Terraform project automates the deployment of an **OpenVPN Access Server**. The OpenVPN Access Server is installed on a generic Linux Droplet (Ubuntu 26.04 LTS) using a custom script executed via **cloud-init** during the provisioning process.

## Prerequisites

- DigitalOcean account with permissions to manage Droplets, VPCs, firewalls, Reserved IPs, and Projects.
- A DigitalOcean **API token** with read and write scope. Create it in the DigitalOcean control panel under **API**, then **Generate New Token**. Set it in your shell: `export DIGITALOCEAN_TOKEN="..."`.
- **Terraform** 1.5 or later.
- An SSH key. You can use your own public key (for example `~/.ssh/id_ed25519.pub`), use a key that already exists in your account, or let Terraform generate one.

## Quick Start

```bash
export DIGITALOCEAN_TOKEN="..."
cp terraform.tfvars.example terraform.tfvars   # edit the values
terraform init
terraform plan
terraform apply
terraform output -json openvpnas_credentials          # show the admin credentials
```

The first boot takes a few minutes. The installation and the setup run after `terraform apply` finishes, so the Web UI is not ready right away. Wait and try again.

To remove all resources, run `terraform destroy`.

## Input Variables

Key variables:

- `region`: The region where resources will be deployed. Default: `sfo3`.
- `droplet_size`: Droplet size slug. Default: `s-2vcpu-2gb`.
- `droplet_name`: Droplet name. The names of the other resources are built from it, so you can deploy more than one Access Server. Default: `OpenVPNAccessServer-Terraform`.
- `generate_ssh_key`: Generate an SSH key pair with Terraform. The public key is added to your DigitalOcean account. Default: `false`.
- `ssh_public_key`: SSH public key to access the Droplet as `root`. It is added to your DigitalOcean account. Default: `null`.
- `ssh_key_fingerprint`: Fingerprint of a key that already exists in your account. Use it instead of `ssh_public_key`, because DigitalOcean rejects a key that is already in the account. Default: `null`.
- `ssh_allowed_cidrs`: CIDR blocks allowed to use SSH on port 22, for example `["203.0.113.10/32"]`. Required, no default.
- `admin_ui_allowed_cidrs`: CIDR blocks allowed to reach the Web UI on port 943. Default: `["0.0.0.0/0"]`. We recommend you restrict it.
- `https_allowed_cidrs`: CIDR blocks allowed to reach TCP port 443. Default: `["0.0.0.0/0", "::/0"]`.
- `vpn_allowed_cidrs`: CIDR blocks allowed to connect to the VPN on UDP port 1194. Default: `["0.0.0.0/0", "::/0"]`.
- `project_id`: ID of your existing DigitalOcean Project. The Droplet and the Reserved IP are added to it. If `null`, they stay in your default Project. Default: `null`.
- `vpc_uuid`: ID of your existing VPC. If `null`, a new VPC is created. Default: `null`.
- `vpc_ip_range`: IP range of the new VPC. If `null`, DigitalOcean chooses one. Default: `null`.
- `admin_username`: The OpenVPN Access Server admin username, lowercase letters, digits, `_` and `-`. Default: `openvpn`.
- `admin_password`: The OpenVPN Access Server admin password. If `null`, a random password is generated. Default: `null`.
- `as_version`: OpenVPN Access Server version to install. Default: `3.2.4`.
- `use_reserved_ip`: Create a Reserved IP, so the public IP stays the same if you recreate the Droplet. A Reserved IP that is not assigned to a Droplet costs money. Default: `true`.
- `enable_lets_encrypt`: Automatically request a Let's Encrypt TLS certificate on boot. Default: `true`.
- `enable_ipv6`: Enable a public IPv6 address on the Droplet. It does not set up IPv6 for the VPN clients. Default: `false`.
- `enable_monitoring`: Install the DigitalOcean monitoring agent. Default: `true`.
- `enable_backups`: Enable Droplet backups, extra cost. Default: `false`.
- `tags`: Extra tags for the Droplet. Default: `[]`.

Set exactly one of `generate_ssh_key`, `ssh_public_key`, and `ssh_key_fingerprint`. The `admin_password` needs at least 12 characters from letters, digits and `! @ # % ^ * _ + = . , : -`. The `admin_password` value is sensitive. Terraform stores it in the state file, so protect your state. Do not commit `terraform.tfvars` or state files.

## SSH Key

- **Generate:** with `generate_ssh_key = true`, Terraform creates an ED25519 key pair and adds the public key to your DigitalOcean account. The private key is a sensitive output and it is stored in the state file. Save it with `terraform output -raw ssh_private_key > key.pem`. On Linux and macOS, run `chmod 600 key.pem` before you use it.
- **Your own key:** set `ssh_public_key` to the content of your public key, for example `~/.ssh/id_ed25519.pub`.
- **Existing key:** set `ssh_key_fingerprint` to the fingerprint of a key that is already in your account. You need the matching private key to log in.

## Network Access

| Port | Protocol | Purpose | Source |
|------|----------|---------|--------|
| 22 | TCP | SSH | `ssh_allowed_cidrs` |
| 943 | TCP | Admin and Client Web UI | `admin_ui_allowed_cidrs` (default: any) |
| 443 | TCP | HTTPS and OpenVPN over TCP | `https_allowed_cidrs` (default: any) |
| 1194 | UDP | OpenVPN tunnel | `vpn_allowed_cidrs` (default: any) |

We recommend you set `admin_ui_allowed_cidrs` to trusted IP addresses if your users do not need the Web UI from the internet. If you restrict `https_allowed_cidrs`, Let's Encrypt validation may fail.

## Outputs

- `admin_ui_url`: Admin Web UI URL.
- `client_ui_url`: Client Web UI URL.
- `public_ip_address`: Public IP address (the Reserved IP when `use_reserved_ip` is true).
- `ipv6_address`: Public IPv6 address (`null` when `enable_ipv6` is false).
- `droplet_id`: ID of the Droplet.
- `ssh_command`: SSH command for the `root` user.
- `ssh_private_key`: Generated SSH private key (sensitive). It is `null` unless `generate_ssh_key` is true.
- `openvpnas_credentials`: Admin credentials (sensitive). Show with `terraform output -json openvpnas_credentials`.

## Project Structure

```
├── LICENSE                     # License
├── README.md                   # Project documentation
├── droplet.tf                  # Droplet
├── firewall.tf                 # Tag and cloud firewall setup
├── image.tf                    # Base image (Ubuntu 26.04 LTS)
├── network.tf                  # VPC (created when no vpc_uuid is given)
├── outputs.tf                  # Outputs from Admin credentials, Admin UI, and Client UI URLs
├── project.tf                  # Adds resources to your existing Project (when project_id is set)
├── provider.tf                 # Provider info and versions
├── reserved_ip.tf              # Reserved IP and its assignment
├── ssh_key.tf                  # SSH key setup (generate, own key, or existing key)
├── terraform.tfvars.example    # Example values
├── user_data.tf                # Admin password and User Data (cloud-init) setup
└── variables.tf                # Input variables
```

## Contact support

You can contact the support team for OpenVPN Access Server here:

https://support.openvpn.com/hc/en-us/categories/360006075631-Access-Server
