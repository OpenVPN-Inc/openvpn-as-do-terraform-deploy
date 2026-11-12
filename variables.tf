variable "region" {
  description = "DigitalOcean region slug to deploy the resources in"
  type        = string
  default     = "sfo3"
}

variable "droplet_size" {
  description = "Access Server Droplet size slug"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "droplet_name" {
  description = "Name of the Access Server Droplet"
  type        = string
  default     = "OpenVPNAccessServer-Terraform"

  validation {
    condition     = can(regex("^[A-Za-z0-9.-]{1,63}$", var.droplet_name))
    error_message = "droplet_name must use only letters, digits, dot, and hyphen (max 63 characters)."
  }
}

variable "project_id" {
  description = "ID of your existing DigitalOcean Project. The Droplet and the Reserved IP are added to it. If null, the resources stay in your default Project"
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.project_id))
    error_message = "project_id must be a valid UUID, or null to use your default Project."
  }
}

variable "vpc_uuid" {
  description = "ID of your existing VPC. If null, a new VPC is created. The VPC must be in the same region"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_uuid == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.vpc_uuid))
    error_message = "vpc_uuid must be a valid UUID, or null to create a new VPC."
  }
}

variable "vpc_ip_range" {
  description = "IP range of the new VPC in CIDR notation (used only when vpc_uuid is null). If null, DigitalOcean chooses a range"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_ip_range == null || can(cidrhost(var.vpc_ip_range, 0))
    error_message = "vpc_ip_range must be a valid CIDR block, for example 10.10.0.0/20."
  }
}

variable "generate_ssh_key" {
  description = "Generate an SSH key pair with Terraform. The public key is added to your DigitalOcean account. The private key is in the sensitive output ssh_private_key and in the Terraform state. Set exactly one of generate_ssh_key, ssh_public_key, or ssh_key_fingerprint"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key content (for example the content of ~/.ssh/id_ed25519.pub) for access to the Droplet as root. It is added to your DigitalOcean account. If the key already exists in your account, use ssh_key_fingerprint instead. Set exactly one of generate_ssh_key, ssh_public_key, or ssh_key_fingerprint"
  type        = string
  default     = null

  validation {
    condition     = var.ssh_public_key == null || can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a public key in OpenSSH format (ssh-rsa, ssh-ed25519, or ecdsa-sha2-...)."
  }
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint of an SSH key that already exists in your DigitalOcean account. Set exactly one of generate_ssh_key, ssh_public_key, or ssh_key_fingerprint"
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to connect over SSH (port 22). Restrict this to trusted IP addresses, for example [\"203.0.113.10/32\"]"
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0 && alltrue([for c in var.ssh_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "ssh_allowed_cidrs must contain at least one valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "admin_ui_allowed_cidrs" {
  description = "List of CIDR blocks allowed to reach the Web UI (port 943). The default is open to the internet. We recommend you restrict it to trusted IP addresses"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.admin_ui_allowed_cidrs) > 0 && alltrue([for c in var.admin_ui_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "admin_ui_allowed_cidrs must contain at least one valid CIDR block."
  }
}

variable "https_allowed_cidrs" {
  description = "List of CIDR blocks allowed to reach the Client Web UI and OpenVPN over TCP (port 443). The default is open to the internet (IPv4 and IPv6). If you restrict it, Let's Encrypt validation may fail"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]

  validation {
    condition     = length(var.https_allowed_cidrs) > 0 && alltrue([for c in var.https_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "https_allowed_cidrs must contain at least one valid CIDR block."
  }
}

variable "vpn_allowed_cidrs" {
  description = "List of CIDR blocks allowed to connect to the VPN over UDP (port 1194). The default is open to the internet (IPv4 and IPv6), so VPN clients can connect from anywhere"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]

  validation {
    condition     = length(var.vpn_allowed_cidrs) > 0 && alltrue([for c in var.vpn_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "vpn_allowed_cidrs must contain at least one valid CIDR block."
  }
}

variable "admin_username" {
  description = "The OpenVPN Access Server admin username (lowercase letters, digits, underscore, hyphen)"
  type        = string
  default     = "openvpn"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.admin_username))
    error_message = "admin_username must start with a lowercase letter or underscore and use only lowercase letters, digits, underscore, and hyphen (max 32 characters)."
  }
}

variable "admin_password" {
  description = "The OpenVPN Access Server admin password (at least 12 characters: letters, digits, and ! @ # % ^ * _ + = . , : -). If null, a random password is generated"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.admin_password == null || can(regex("^[A-Za-z0-9!@#%^*_+=.,:-]{12,}$", var.admin_password))
    error_message = "admin_password must be at least 12 characters and use only letters, digits, and these symbols: ! @ # % ^ * _ + = . , : -"
  }
}

variable "as_version" {
  description = "OpenVPN Access Server version to install"
  type        = string
  default     = "3.2.4"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[A-Za-z0-9.]+)?$", var.as_version))
    error_message = "as_version must look like 3.2.4."
  }
}

variable "use_reserved_ip" {
  description = "Whether to create a Reserved IP (recommended) for the Access Server, so the public IP stays the same if you recreate the Droplet"
  type        = bool
  default     = true
}

variable "enable_lets_encrypt" {
  description = "Whether to automatically request and install a Let's Encrypt TLS certificate for the Access Server once it boots"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Whether to enable a public IPv6 address on the Droplet. This only adds an IPv6 address to the server. It does not set up IPv6 for the VPN clients"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Whether to install the DigitalOcean monitoring agent on the Droplet"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Whether to enable DigitalOcean Droplet backups (extra cost)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags for the Droplet (letters, digits, colon, hyphen, underscore)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for t in var.tags : can(regex("^[A-Za-z0-9:_-]{1,255}$", t))])
    error_message = "Each tag must use only letters, digits, colon, hyphen, or underscore."
  }
}
