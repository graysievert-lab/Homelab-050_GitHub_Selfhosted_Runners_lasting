########################################
## Cloud-init custom configs
########################################


resource "proxmox_virtual_environment_file" "cloudinit_meta_config" {
  for_each = toset(local.hostnames)
  
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.proxmox_node
  source_raw {
    file_name = "${each.key}-meta-config.yaml"
    data      = <<EOF
#cloud-config
local-hostname: "${each.key}"
instance-id: ${md5(each.key)}
EOF
  }
}

resource "proxmox_virtual_environment_file" "cloudinit_user_config" {
  for_each = toset(local.hostnames)

  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.proxmox_node
  source_raw {
    file_name = "${each.key}-user-config.yaml"
    data      = <<EOF
#cloud-config
ssh_authorized_keys:
  - "${local.ssh_ca_record}"
user:
  name: rocky
users:
  - default
EOF
  }
}

resource "proxmox_virtual_environment_file" "cloudinit_vendor_config" {
  for_each = toset(local.hostnames)

  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.proxmox_node
  source_raw {
    file_name = "${each.key}-vendor-config.yaml"
    data      = <<EOF
#cloud-config
packages:
    - qemu-guest-agent

runcmd:
  - echo -e "I am $(whoami) at $(hostname -f), myenv is\n$(declare -p)"
  - curl -k -o /etc/pki/ca-trust/source/anchors/localCA.crt https://acme.lan:8443/roots.pem && update-ca-trust extract
EOF
  }
}


