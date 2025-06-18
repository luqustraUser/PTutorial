// ====================
// Local Variables
// ====================
locals {
  prefix_hub         = "hub"
  hub_location       = "AustraliaEast"
  hub_resource_group = "hub-vnet-rg"
  hub_shared_key     = "4-v3ry-53cr37-5h4r3d-k3y"
}

// ====================
// Random Suffix
// ====================
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  numeric = true
  special = false
}

// ====================
// Resource Group
// ====================
resource "azurerm_resource_group" "hub_vnet_rg" {
  name     = "${local.hub_resource_group}-${random_string.suffix.result}"
  location = local.hub_location
}

// ====================
// Virtual Network
// ====================
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${local.prefix_hub}-vnet"
  location            = azurerm_resource_group.hub_vnet_rg.location
  resource_group_name = azurerm_resource_group.hub_vnet_rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "hub-spoke"
  }
}

// ====================
// Subnets
// ====================
resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.255.224/27"]
}

resource "azurerm_subnet" "hub_mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.hub_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.64/27"]
}

resource "azurerm_subnet" "hub_dmz" {
  name                 = "dmz"
  resource_group_name  = azurerm_resource_group.hub_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.32/27"]
}

// ====================
// Network Interface
// ====================
resource "azurerm_network_interface" "hub_nic" {
  name                  = "${local.prefix_hub}-nic"
  location              = azurerm_resource_group.hub_vnet_rg.location
  resource_group_name   = azurerm_resource_group.hub_vnet_rg.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = local.prefix_hub
    subnet_id                     = azurerm_subnet.hub_mgmt.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.prefix_hub
  }
}

// ====================
// Virtual Machine
// ====================
resource "azurerm_virtual_machine" "hub_vm" {
  name                  = "${local.prefix_hub}-vm"
  location              = azurerm_resource_group.hub_vnet_rg.location
  resource_group_name   = azurerm_resource_group.hub_vnet_rg.name
  network_interface_ids = [azurerm_network_interface.hub_nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix_hub}-vm"
    admin_username = "azureuser"
    admin_password = local.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = local.prefix_hub
  }
}

// ====================
// VPN Gateway Public IP
// ====================
resource "azurerm_public_ip" "hub_vpn_gateway1_pip" {
  name                = "hub-vpn-gateway1-pip"
  location            = azurerm_resource_group.hub_vnet_rg.location
  resource_group_name = azurerm_resource_group.hub_vnet_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

// ====================
// Virtual Network Gateway
// ====================
resource "azurerm_virtual_network_gateway" "hub_vnet_gateway" {
  name                = "hub-vpn-gateway"
  location            = azurerm_resource_group.hub_vnet_rg.location
  resource_group_name = azurerm_resource_group.hub_vnet_rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.hub_vpn_gateway1_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_gateway_subnet.id
  }

  depends_on = [azurerm_public_ip.hub_vpn_gateway1_pip]
}

// ====================
// VPN Gateway Connection (Hub <-> On-Prem)
// ====================
resource "azurerm_virtual_network_gateway_connection" "hub_onprem_conn" {
  name                            = "hub-onprem-conn"
  location                        = azurerm_resource_group.hub_vnet_rg.location
  resource_group_name             = azurerm_resource_group.hub_vnet_rg.name
  type                            = "Vnet2Vnet"
  routing_weight                  = 1
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub_vnet_gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_vpn_gateway.id
  shared_key                      = local.hub_shared_key
}
