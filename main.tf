# let's start with our sensitive credentials. we will
# create a secure password and pass the output into a file on 
# our local pc (which will be added to the gitignore file)

resource "random_password" "password" {
  count            = 6
  length           = 12
  min_lower        = 2
  min_upper        = 2
  numeric          = true
  special          = true
  override_special = "@$-_"
}

resource "local_file" "mypasswords" {
    content  = random_password.password.result
    filename = "mypasswords.txt"
}

#CREATING A VIRTUAL MACHINE IN MY NEW RG
resource "azurerm_resource_group" "RG" {
  name     = var.RGname
  location = var.region
}

resource "azurerm_virtual_network" "VNET" {
  name                = var.vnet-name
  address_space       = var.vnet-addr
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet-name
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = var.subnet-addr
}

resource "azurerm_network_interface" "nic" {
  name                = var.NIC-name
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = var.NIC-IPconfig
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm-name
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  size                = "Standard_D2s_v3"
  admin_username      = var.VMpassword
  admin_password      = random_password.password[0].result
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = var.caching
    storage_account_type = var.storage
  }

  source_image_reference {
    publisher = var.VM-publisher
    offer     = var.VM-offer
    sku       = var.VM-OS-SKU
    version   = var.VM-Image-version
  }
}

resource "azurerm_network_security_group" "NSGSubnet" {
  name                = var.NSG-name
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  security_rule {
    name                       = "Allow-all-HTTP"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.NSGSubnet.id
}

resource "azurerm_public_ip" "LBPIP" {
  name                = "INboundPIP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku = "Standard"
  domain_name_label = "kolaserver"
}

resource "azurerm_public_ip" "LBPIP2" {
  name                = "OutboundPIP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "LB" {
  name                = "KolaLB"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "InboundFIP"
    public_ip_address_id = azurerm_public_ip.LBPIP.id
  }
  frontend_ip_configuration {
    name                 = "OutboundFIP"
    public_ip_address_id = azurerm_public_ip.LBPIP2.id
  }
}

resource "azurerm_lb_backend_address_pool" "LBBEP" {
  loadbalancer_id = azurerm_lb.LB.id
  name            = "WebBEP"
}

resource "azurerm_network_interface_backend_address_pool_association" "BEPNIC" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = var.NIC-IPconfig
  backend_address_pool_id = azurerm_lb_backend_address_pool.LBBEP.id
}

resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.LB.id
  name            = "Probe-80"
  port            = 80
}

resource "azurerm_lb_rule" "LBRULE" {
  loadbalancer_id                = azurerm_lb.LB.id
  name                           = "wEBLBrule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "InboundFIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.LBBEP.id]
  probe_id                       = azurerm_lb_probe.probe.id
  disable_outbound_snat          = "true"
}

resource "azurerm_lb_outbound_rule" "outbound" {
  name                    = "OutboundRule"
  loadbalancer_id         = azurerm_lb.LB.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.LBBEP.id

  frontend_ip_configuration {
    name = "OutboundFIP"
  }
}


#main in the module
resource "azurerm_resource_group" "ots_rg" {
  name     = "${var.environment}-${var.product}-rg01"
  location = "UK South"
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtualNetworkName
  resource_group_name = var.vnet_rg_name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnetName
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azurerm_key_vault" "kv1" {
  name                        = var.kv_name
  resource_group_name         = var.kv_rg_name
#  depends_on = [local_file.key_pem]
}

resource "azurerm_key_vault_secret" "privatekey" {
  name         = "${var.virtualMachineName}-private-key"
  value        = tls_private_key.keypair.private_key_pem
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "publickey" {
  name = "${var.virtualMachineName}-public-key"
  value = tls_private_key.keypair.public_key_pem
  key_vault_id = data.azurerm_key_vault.kv1.id
}

# # Retrieve the SSH public key from the key vault
# data "azurerm_key_vault_secret" "ssh_public_key" {
#   name         = var.ssh_public_key_name
#   key_vault_id = data.azurerm_key_vault.kv1.id
# }


resource "azurerm_network_interface" "nic" {
  name                = "${var.virtualMachineName}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.ots_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = var.virtualMachineName
  location              = data.azurerm_resource_group.ots_rg.location
  resource_group_name   = data.azurerm_resource_group.ots_rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.virtualMachineSize
#   availability_set_id   = data.azurerm_availability_set.main.id
  disable_password_authentication = "true"
  admin_username = var.admin_username
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.keypair.public_key_pem
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.osDiskSize
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

#   tags = local.tags
#   user_data = var.user_data

}




#main in root folder

#OTS_VM
data "azurerm_key_vault" "ssh_kv" {
  name = "iuks-ssh-kv01"
  resource_group_name = "iuks-infra-rg01"
}

module "ots_vm" {
  source = "./modules/ots_vm"
  environment = var.environment
  product = var.product_ots
  location = var.location
  virtualNetworkName = data.azurerm_virtual_network.main_vnet.name
  vnet_rg_name = data.azurerm_virtual_network.main_vnet.resource_group_name
  subnetName = var.subnetName_backend
  virtualMachineName = "${var.environment}${var.product_ots}01"
  virtualMachineSize = "Standard_B2als_v2"
  admin_username = var.admin_username
  osDiskSize = 256
  boot_diagnostics_storage_account_uri = azurerm_storage_account.elis_sa01.primary_blob_endpoint
  kv_name = data.azurerm_key_vault.ssh_kv.name
  kv_rg_name = data.azurerm_key_vault.ssh_kv.resource_group_name
}
