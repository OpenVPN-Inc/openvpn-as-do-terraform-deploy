# Admin password: the value you give, or a random one
resource "random_password" "admin" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = false
}

locals {
  admin_password = var.admin_password != null ? var.admin_password : random_password.admin[0].result

  user_data = <<-EOF
    #!/bin/bash
    echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
    dpkg-reconfigure -f noninteractive unattended-upgrades
    OVPN_INIT_MANUAL=true bash <(curl -fsS https://packages.openvpn.net/as/install.sh) --as-version=${var.as_version} --yes
    ovpn-init --batch --force
    apt-mark hold openvpn-as
    . /usr/local/openvpn_as/etc/VERSION
    echo "OpenVPN Access Server Appliance $AS_VERSION \n \l" > /etc/issue
    cat > /etc/update-motd.d/00-header <<HEADER
    #!/bin/sh
    echo "Welcome to OpenVPN Access Server Appliance $AS_VERSION"
    HEADER
    for i in $(seq 1 90); do sacli status 2>/dev/null | grep -q '"api": "on"' && break; sleep 2; done
    ADMIN_USER='${var.admin_username}'
    ADMIN_PW='${local.admin_password}'
    install -m 600 /dev/null /var/log/ovpn-admin-setup.log
    admin_step() { label="$1"; shift; "$@" >> /var/log/ovpn-admin-setup.log 2>&1 || echo "FAILED: $label" >> /var/log/ovpn-admin-setup.log; }
    admin_step type sacli --user "$ADMIN_USER" --key "type" --value "user_connect" UserPropPut
    admin_step auth_type sacli --user "$ADMIN_USER" --key "user_auth_type" --value "local" UserPropPut
    admin_step superuser sacli --user "$ADMIN_USER" --key "prop_superuser" --value "true" UserPropPut
    admin_step password sacli --user "$ADMIN_USER" --new_pass "$ADMIN_PW" SetLocalPassword
    %{if var.enable_lets_encrypt}
    for i in $(seq 1 30); do PUBLIC_IP=$(sacli ip 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1); [ -n "$PUBLIC_IP" ] && break; sleep 2; done
    [ -n "$PUBLIC_IP" ] || echo "WARNING: sacli ip returned no IP address" >> /var/log/ovpn-admin-setup.log
    sacli --key "acme.ip_addresses.0" --value "$PUBLIC_IP" ConfigPut
    sacli --key "acme.cert_profile" --value "shortlived" ConfigPut
    %{endif}
    sacli start
    %{if var.enable_lets_encrypt}
    echo y | sacli AcmeRegisterAccount
    sacli AcmeRequestCertificate
    %{endif}
    exit 0
  EOF
}
