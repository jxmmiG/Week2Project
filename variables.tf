variable "VMusername" {
  type  = string
  description = "name of VM's admin account"
  default = "jxmmi"
}

variable "RGname" {
  type  = string
  description = "name of our resource group"
}

variable "region" {
  type = string
  description = "region where resources will be deployed"
}

variable "vm-name" {
  type = string
  description = "name of our Virtual Machine"
}

variable "subnet-name" {
  type = string
  description = "name of our VM subnet"
}

variable "NIC-name" {
  type = string
  description = "Virtual Machine NIC Name"
}

variable "NIC-IPconfig" {
  type = string
  description = "The name of the IP configuration of the VM NIC"
}

variable "vnet-name" {
  type = string
  description = "The name of our Virtual Network"
}

variable "vnet-addr" {
  type = list(string)
  description = "Address space of our Virtual Network"
}

variable "subnet-addr" {
  type = list(string)
  description = "Address space of the VM subnet"
}

variable "GW-subnet-addr" {
  type = list(string)
  description = "Address space of the Gateway Subnet"
}

variable "FW-subnet-addr" {
  type = list(string)
  description = "Address space of the Firewall subnet. Must be a /26"
}

variable "VPNGW-name" {
  type = string
  description = "The name of our VPN Gateway"
}

variable "connection-name" {
  type = string
  description = "The name of our connection"
}

variable "LNG-name" {
  type = string
  description = "Name of the LNG resource"
}

variable "on-prem-LAN" {
  type = string
  description = "IP address space of the Bonaku-LAN"
}

variable "on-prem-GW" {
  type = string
  description = "Public IP address of the on-prem device/gateway"
}

variable "FW-name" {
  type = string
  description = "Name of our Azure Firewall"
}

variable "LB-Name" {
  type = string
  description = "Name of our Load Balancer"
}

variable "caching" {
  type = string
  description = "caching configuration for our VM OS Disk"
}

variable "storage" {
  type = string
  description = "Type of Managed Storage Account for the VM boot diagnostics"
}

variable "VM-publisher" {
  type = string
  description = "Publisher of the OS for the VM"
  default = "MicrosoftWindowsServer"
}

variable "VM-offer" {
  type = string
  description = "VM OS type(offer)"
  default = "WindowsServer"
}

variable "VM-OS-SKU" {
  type = string
  description = "SKU of the VM OS"
  default = "2016-Datacenter"
}

variable "VM-Image-version" {
  type = string
  description = "VM OS Image version"
  default = "latest"
}

variable "NSG-name" {
  type = string
  description = "Name of the Subnet level NSG"
}

variable "NSG-ports" {
  type = list(string)
  description = "Ports you want to open on the Subnet NSG"
}

variable "Server-domain-label" {
  type = string
  description = "DNS label of the PIP of the LB/VM"
}

variable "LB-SKU" {
  type = string
  description = "SKU of the Load Balancer"
}
