VMusername = "jxmmi"

RGname = "KolaTF-RG-002"

region = "UK South"

vm-name = "KolaVM"

subnet-name = "Kola-Subnet"

NIC-name = "kolaVMnic"

NIC-IPconfig = "DefaultIPconfig"

vnet-name = "Kola-VNET"

vnet-addr = ["192.168.40.0/24"]

subnet-addr = ["192.168.40.0/28"]

GW-subnet-addr = ["192.168.40.32/27"]

FW-subnet-addr = ["192.168.40.64/26"]

VPNGW-name = "kola-VPNGW"

connection-name = "kola-to-Bonaku"

LNG-name = "kola-to-Bonaku-LNG"

on-prem-LAN = "192.168.0.0/24"

on-prem-GW = "23.23.23.23"

FW-name = "KolaFW"

LB-Name = "KolaLB"

caching = "ReadWrite"

storage = "Standard_LRS"

VM-publisher = "MicrosoftWindowsServer"

VM-offer = "WindowsServer"

VM-OS-SKU = "2016-Datacenter"

VM-Image-version = "latest"

NSG-name = "ServerSubnetNSG"

NSG-ports = ["80,443,22,3389"]

Server-domain-label = "kolaserver"

LB-SKU = "Standard"

