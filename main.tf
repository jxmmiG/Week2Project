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
