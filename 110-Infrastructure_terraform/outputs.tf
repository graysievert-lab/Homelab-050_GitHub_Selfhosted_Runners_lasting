# Output variable definitions

output "vm_id" {
  description = "VM ID"
    value       = {for key, value in local.hostnames : value => module.proxmox_vm_runners[value].vm_id}
}

output "ipv4_addresses" {
  description = "IP v4 addresses"
  value       = {for key, value in local.hostnames : value => module.proxmox_vm_runners[value].ipv4_addresses}
}

output "ipv6_addresses" {
  description = "IP v6 addresses"
  value       = {for key, value in local.hostnames : value => module.proxmox_vm_runners[value].ipv6_addresses}
}

output "mac_addresses" {
  description = "MAC addresses"
  value       = {for key, value in local.hostnames : value => module.proxmox_vm_runners[value].mac_addresses}
}
