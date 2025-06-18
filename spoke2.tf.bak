locals {
  prefix_spoke2         = "spoke2"
  spoke2_resource_group = "${local.prefix_spoke2}-vnet-rg-${random_string.suffix.result}"
  spoke2_location       = "AustraliaEast"
}

resource "azurerm_resource_group" "spoke2_vnet_rg" {
  name     = local.spoke2_resource_group
  location = local.spoke2_location
}

resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "${local.prefix_spoke2}-vnet"
  location            = azurerm_resource_group.spoke2_vnet_rg.location
  resource_group_name = azurerm_resource_group.spoke2_vnet_rg.name
  address_space       = ["10.2.0.0/16"]

  tags = {
    environment = local.prefix_spoke2
  }
}

resource "azurerm_subnet" "spoke2_mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.spoke2_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.2.0.64/27"]
}

resource "azurerm_subnet" "spoke2_workload" {
  name                 = "workload"
  resource_group_name  = azurerm_resource_group.spoke2_vnet_rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                      = "${local.prefix_spoke2}-hub-peer"
  resource_group_name       = azurerm_resource_group.spoke2_vnet_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke2_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true

  depends_on = [
    azurerm_virtual_network.spoke2_vnet,
    azurerm_virtual_network.hub_vnet,
    azurerm_virtual_network_gateway.hub_vnet_gateway
  ]
}

resource "azurerm_network_interface" "spoke2_nic" {
  name                = "${local.prefix_spoke2}-nic"
  location            = azurerm_resource_group.spoke2_vnet_rg.location
  resource_group_name = azurerm_resource_group.spoke2_vnet_rg.name

  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "${local.prefix_spoke2}-ipconfig"
    subnet_id                     = azurerm_subnet.spoke2_mgmt.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.prefix_spoke2
  }
}

resource "azurerm_virtual_machine" "spoke2_vm" {
  name                  = "${local.prefix_spoke2}-vm"
  location              = azurerm_resource_group.spoke2_vnet_rg.location
  resource_group_name   = azurerm_resource_group.spoke2_vnet_rg.name
  network_interface_ids = [azurerm_network_interface.spoke2_nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.prefix_spoke2}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix_spoke2}-vm"
    admin_username = var.username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = local.prefix_spoke2
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "hub-spoke2-peer"
  resource_group_name       = azurerm_resource_group.hub_vnet_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke2_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  depends_on = [
    azurerm_virtual_network.spoke2_vnet,
    azurerm_virtual_network.hub_vnet,
    azurerm_virtual_network_gateway.hub_vnet_gateway
  ]
}
