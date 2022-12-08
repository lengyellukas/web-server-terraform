# provider is microsoft azure
provider "azurerm" {
  features {}
}

# get resource resource_group_name
data "azurerm_resource_group" "main" {
  name     = "Azuredevops"
}

# define azure output
output "id" {
    value = data.azurerm_resource_group.main.id
}

# get the packer image
data "azurerm_image" "main" {
    name                = "myPackerImage"
    resource_group_name = "Azuredevops" 
}

# get image id
output "image_id" {
    value = "/subscriptions/dd5cdf51-de40-463c-b842-e077e98bede1/resourceGroups/Azuredevops/providers/Microsoft.Compute/images/myPackerImage"
}

# create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.tags
}

# create subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# network security group - access to other VMs in subnet allowed
resource "azurerm_network_security_group" "security" {
  name                = "${var.prefix}-security"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = var.tags
}

resource "azurerm_network_security_rule" "inbound_subnet" {
  name                        = "allow-inbound-subnet-all"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.security.name
}

resource "azurerm_network_security_rule" "outbound_subnet" {
  name                        = "allow-outbound-subnet-all"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.security.name
}

resource "azurerm_network_security_rule" "deny-internet" {
  name                        = "deny-all"
  priority                    = 1005
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.security.name
}

resource "azurerm_subnet_network_security_group_association" "internal" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.security.id
}

# network interface
resource "azurerm_network_interface" "main" {
  count               = "${var.instance_count}"
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# public IP
resource "azurerm_public_ip" "public" {
  name                = "${var.prefix}-publicIP"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = var.tags
}

# load balancer
resource "azurerm_lb" "load_balancer" {
  name                = "loadBalancer"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.public.id
  }

  tags = var.tags
}

#backend address pool
resource "azurerm_lb_backend_address_pool" "backend_address_pool_id" {
  name                = "BackEndAddressPool"
  loadbalancer_id     = azurerm_lb.load_balancer.id
}

#availability set
resource "azurerm_availability_set" "availability_set" {
  name                          = "availabilitySet"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  platform_fault_domain_count   = 2
  platform_update_domain_count  = 2
  managed                       = true
  tags = var.tags
}

# virtual machine
resource "azurerm_linux_virtual_machine" "main" {
  count                             = "${var.instance_count}"
  name                              = "${var.prefix}-vm-${count.index}"
  resource_group_name               = data.azurerm_resource_group.main.name
  location                          = data.azurerm_resource_group.main.location
  availability_set_id               = azurerm_availability_set.availability_set.id
  network_interface_ids             = [element(azurerm_network_interface.main.*.id, count.index)]
  size                              = "Standard_D2s_v3"
  admin_username                    = "${var.username}"
  admin_password                    = "${var.password}"
  disable_password_authentication   = false
  #packer image id
  source_image_id                   = "/subscriptions/481b1dfa-09f6-4305-a978-b656e03d8e84/resourceGroups/Azuredevops/providers/Microsoft.Compute/images/myPackerImage"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  tags = merge(
    var.tags,
    {
      project = "${var.project}"
    }
  )      
}

 # managed drive
resource "azurerm_managed_disk" "managed_drive" {
  count                = "${var.instance_count}"
  name                 = "datadisk_managed_${count.index}"
  resource_group_name  = data.azurerm_resource_group.main.name
  location             = data.azurerm_resource_group.main.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "attached_drive" {
  count              = "${var.instance_count}"
  managed_disk_id    = azurerm_managed_disk.managed_drive[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}