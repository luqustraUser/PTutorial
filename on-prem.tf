// ====================
// Local Variables
// ====================
locals {
  onprem_location       = "AustraliaEast"
  prefix_onprem         = "onprem"
  onprem_resource_group = "${local.prefix_onprem}-vnet-rg-${random_string.suffix.result}"
}

//
// ====================
// Resource Group
// ====================
resource "azurerm_resource_group" "onprem_vnet_rg" {
  name     = local.onprem_resource_group
  location = local.onprem_location
}

//
// ====================
// Virtual Network
// ====================
resource "azurerm_virtual_network" "onprem_vnet" {
  name                = "${local.prefix_onprem}-vnet"
  location            = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name = azurerm_resource_group.onprem_vnet_rg.name
  address_space       = ["192.168.0.0/16"]

  tags = {
    environment = local.prefix_onprem
  }
}

//
// ====================
// Subnets
// ====================
resource "azurerm_subnet" "onprem_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.onprem_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.onprem_vnet.name
  address_prefixes     = ["192.168.255.224/27"]
}

resource "azurerm_subnet" "onprem_mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.onprem_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.onprem_vnet.name
  address_prefixes     = ["192.168.1.128/25"]
}

//
// ====================
// Public IP
// ====================
resource "azurerm_public_ip" "onprem_pip" {
  name                = "${local.prefix_onprem}-pip"
  location            = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name = azurerm_resource_group.onprem_vnet_rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = local.prefix_onprem
  }
}

//
// ====================
// Network Interface
// ====================
resource "azurerm_network_interface" "onprem_nic" {
  name                  = "${local.prefix_onprem}-nic"
  location              = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name   = azurerm_resource_group.onprem_vnet_rg.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "${local.prefix_onprem}-ipconfig"
    subnet_id                     = azurerm_subnet.onprem_mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onprem_pip.id
  }

  tags = {
    environment = local.prefix_onprem
  }
}

//
// ====================
// Network Security Group
// ====================
resource "azurerm_network_security_group" "onprem_nsg" {
  name                = "${local.prefix_onprem}-nsg"
  location            = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name = azurerm_resource_group.onprem_vnet_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = local.prefix_onprem
  }
}

resource "azurerm_subnet_network_security_group_association" "mgmt_nsg_association" {
  subnet_id                 = azurerm_subnet.onprem_mgmt.id
  network_security_group_id = azurerm_network_security_group.onprem_nsg.id
}

//
// ====================
// Virtual Machine
// ====================
resource "azurerm_virtual_machine" "onprem_vm" {
  name                  = "${local.prefix_onprem}-vm"
  location              = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name   = azurerm_resource_group.onprem_vnet_rg.name
  network_interface_ids = [azurerm_network_interface.onprem_nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.prefix_onprem}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix_onprem}-vm"
    admin_username = "azureuser"
    admin_password = local.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = local.prefix_onprem
  }
}

//
// ====================
// VPN Gateway Public IP
// ====================
resource "azurerm_public_ip" "onprem_vpn_gateway1_pip" {
  name                = "${local.prefix_onprem}-vpn-gateway1-pip"
  location            = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name = azurerm_resource_group.onprem_vnet_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

//
// ====================
// Virtual Network Gateway
// ====================
resource "azurerm_virtual_network_gateway" "onprem_vpn_gateway" {
  name                = "${local.prefix_onprem}-vpn-gateway1"
  location            = azurerm_resource_group.onprem_vnet_rg.location
  resource_group_name = azurerm_resource_group.onprem_vnet_rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onprem_vpn_gateway1_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.onprem_gateway_subnet.id
  }

  depends_on = [azurerm_public_ip.onprem_vpn_gateway1_pip]
}
