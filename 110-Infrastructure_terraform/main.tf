
locals {
  runners_quantity = 1
  basename = "gha"
  baseid = 3000
  hostnames = [for i in range(local.runners_quantity) : "${local.basename}-${i + 1}"]

  description = "GHA runner"
  tags        = ["GHA", "linux", "cloudinit", "infra"]

  proxmox_node   = "pve" #name of proxmox node"
  ssh_ca_record = "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTS/AYbRXLDv1EYUBPouFROZ5fTGMge5jMZA7prfMKHMhvCSUQFnS665BQH5pMwxjjXtinn3n1uCR41SWumq6YVWHZZdVm3o2jCfJlKwkax4ZHFeGl3eSXqEqrTauWWUqP35rKbZGsAqAzucBHAmSoQbeN8P7YPVNweD6EUkrFgAB/1HdMPnHlhSH6GSFOKj690kUzkWP+tRqnyt4aQE6nMSsP1plAFDJZOrjVAeyLPKTQFJ1SDbaKD1ZoAJ1ml+BJXFNwPNVOwXQZcfHb6t8gxtxcDWqtNQj/5jicYp8TsnLuHuXQmGjxq3DOi9nDdsVIRX6Cdpjwf+CWbT4VTBZ+ESF5AHFwpe0m67hE2XvAqWb+Bzn8re1ezv/K+0K40vvvrauCvETxjnQOuFwNIhgrulbwFqVEjbRvIgzcY6+nrs4N7A10BAUHnFm5sHZnFVw1QU2HqYUFLosALEhulA1NZr8Zakww9ik7XnWiFyF909CsHHhcdvo+NxmpErethiItVbfflKKft3lN40uUCCOqUUyVvJpzX/LTn8Gbnu99CxxDewKF14DyUpqoSGsiGoXBg5+w6nHZbDzN3JDdYDtLZ73lQqc7bE85bPD45hn7Oeu+rCJvzsXf1/kU8GlwS6tx6ghJloJvShS45E34Zr5eEEYNgoxI/mg0+9Ks9YNTQw=="

}

########################################
## pool
########################################
resource "proxmox_virtual_environment_pool" "main" {
  comment = "Pool for GHA runners"
  pool_id = "gha"
}



########################################
## Generate Ansible inventory
########################################

data "template_file" "ansible_inventory" {
  template = file("${path.module}/files/inventory.tpl")

  vars = {
    hostnames = join("\n", local.hostnames)
  }
}

resource "local_file" "inventory_file" {
  filename = "${path.module}/generated/inventory.yaml"
  content  = data.template_file.ansible_inventory.rendered
}


########################################
## Virtual Machines
########################################
module "proxmox_vm_runners" {
  for_each = { for idx, hostname in local.hostnames : hostname => local.baseid + idx + 1 }
  
  source = "git::https://github.com/graysievert-lab/terraform-modules-proxmox_vm?ref=v1.0.0"

  metadata = {
    node_name    = local.proxmox_node
    datastore_id = "local-zfs"
    image        = "local:iso/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2.img"
    agent        = true
    description  = local.description
    name         = "${each.key}"
    pool_id      = proxmox_virtual_environment_pool.main.id
    tags         = local.tags
    vm_id        = "${each.value}"
  }

  hardware = {
    mem_dedicated_mb = 4096
    mem_floating_mb  = 1024
    cpu_sockets      = 1
    cpu_cores        = 2
    disk_size_gb     = 15
  }

  cloudinit = {
    meta_config_file   = proxmox_virtual_environment_file.cloudinit_meta_config[each.key].id
    user_config_file   = proxmox_virtual_environment_file.cloudinit_user_config[each.key].id
    vendor_config_file = proxmox_virtual_environment_file.cloudinit_vendor_config[each.key].id
    ipv4 = {
      address = "dhcp" # CIDR or "dhcp"
      #gateway = "" # not needed when "dhcp"
    }
  }
}
