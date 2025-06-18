// ====================
// Local Variables
// ====================
locals {
  prefix_hub_nva         = "hub-nva"
  hub_nva_location       = "AustraliaEast"
  hub_nva_resource_group = "hub-nva-rg"
  nva_shared_key         = "4-v3ry-53cr37-5h4r3d-k3y"
}

// ====================
// Random Suffix
// ====================
resource "random_string" "nva_suffix" {
  length  = 5
  upper   = false
  special = false
}

// ====================
// Resource Group
// ====================
resource "azurerm_resource_group" "hub_nva_rg" {
  name     = "${local.hub_nva_resource_group}-${random_string.nva_suffix.result}"
  location = local.hub_nva_location

  tags = {
    environment = local.prefix_hub_nva
  }
}

// ====================
// Network Interface for NVA
// ====================
resource "azurerm_network_interface" "hub_nva_nic" {
  name                  = "${local.prefix_hub_nva}-nic"
  location              = azurerm_resource_group.hub_nva_rg.location
  resource_group_name   = azurerm_resource_group.hub_nva_rg.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = local.prefix_hub_nva
    subnet_id                     = azurerm_subnet.hub_dmz.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.36"
  }

  tags = {
    environment = local.prefix_hub_nva
  }
}

// ====================
// NVA Virtual Machine
// ====================
resource "azurerm_virtual_machine" "hub_nva_vm" {
  name                  = "${local.prefix_hub_nva}-vm"
  location              = azurerm_resource_group.hub_nva_rg.location
  resource_group_name   = azurerm_resource_group.hub_nva_rg.name
  network_interface_ids = [azurerm_network_interface.hub_nva_nic.id]
  vm_size               = var.vmsize

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix_hub_nva}-vm"
    admin_username = var.username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = local.prefix_hub_nva
  }
}

// ====================
// Enable IP Forwarding (Linux NVA Configuration)
// ====================
resource "azurerm_virtual_machine_extension" "enable_routes" {
  name                 = "enable-iptables-routes"
  virtual_machine_id   = azurerm_virtual_machine.hub_nva_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
{
  "fileUris": [
    "https://raw.githubusercontent.com/lonegunmanb/reference-architectures/master/scripts/linux/enable-ip-forwarding.sh"
  ],
  "commandToExecute": "bash enable-ip-forwarding.sh"
}
SETTINGS

  tags = {
    environment = local.prefix_hub_nva
  }
}

// ====================
// Route Table for Hub Gateway
// ====================
resource "azurerm_route_table" "hub_gateway_rt" {
  name                          = "hub-gateway-rt"
  location                      = azurerm_resource_group.hub_nva_rg.location
  resource_group_name           = azurerm_resource_group.hub_nva_rg.name
  bgp_route_propagation_enabled = true

  route {
    name           = "toHub"
    address_prefix = "10.0.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  route {
    name                   = "toSpoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }

  route {
    name                   = "toSpoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }

  tags = {
    environment = local.prefix_hub_nva
  }
}

// ====================
// Spoke2 Route Table
// ====================
resource "azurerm_route_table" "spoke2_rt" {
  name                          = "spoke2-rt"
  location                      = azurerm_resource_group.hub_nva_rg.location
  resource_group_name           = azurerm_resource_group.hub_nva_rg.name
  bgp_route_propagation_enabled = true

  route {
    name                   = "toSpoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    environment = local.prefix_hub_nva
  }
}

// ====================
// Route Table Associations (Assumes Spoke Subnets Exist)
// ====================
resource "azurerm_subnet_route_table_association" "spoke1_rt_association" {
  subnet_id      = azurerm_subnet.spoke1_mgmt.id
  route_table_id = azurerm_route_table.hub_gateway_rt.id
}

resource "azurerm_subnet_route_table_association" "spoke2_mgmt_rt_association" {
  subnet_id      = azurerm_subnet.spoke2_mgmt.id
  route_table_id = azurerm_route_table.spoke2_rt.id
}

resource "azurerm_subnet_route_table_association" "spoke2_workload_rt_association" {
  subnet_id      = azurerm_subnet.spoke2_workload.id
  route_table_id = azurerm_route_table.spoke2_rt.id
}
