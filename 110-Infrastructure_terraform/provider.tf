terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.61.1"
    }
  
  }
}

provider "proxmox" {
  endpoint  = "https://pve.lan:8006/"
  api_token = var.pvetoken
  ssh {
    agent    = true
    username = "iac"
  }
}


