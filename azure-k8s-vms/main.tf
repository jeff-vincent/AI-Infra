# Resource Group
resource "azurerm_resource_group" "k8s" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "k8s" {
  name                = "k8s-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "k8s" {
  name                 = "k8s-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.k8s.name
  address_prefixes     = var.subnet_address_prefixes
}

# Network Security Group for Control Plane
# Allows kubeadm traffic (ports 6443, 2379-2380, 10250-10252) from within VNet
resource "azurerm_network_security_group" "control_plane" {
  name                = "control-plane-nsg"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  tags                = var.tags

  # Kubernetes API Server
  security_rule {
    name                       = "allow-k8s-api"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # etcd server client API
  security_rule {
    name                       = "allow-etcd"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Kubelet API
  security_rule {
    name                       = "allow-kubelet"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # kube-scheduler
  security_rule {
    name                       = "allow-kube-scheduler"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10259"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # kube-controller-manager
  security_rule {
    name                       = "allow-kube-controller"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10257"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # SSH access
  security_rule {
    name                       = "allow-ssh"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Worker Nodes
resource "azurerm_network_security_group" "workers" {
  name                = "workers-nsg"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  tags                = var.tags

  # Kubelet API
  security_rule {
    name                       = "allow-kubelet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # NodePort Services
  security_rule {
    name                       = "allow-nodeport"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # SSH access
  security_rule {
    name                       = "allow-ssh"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Public IPs
resource "azurerm_public_ip" "control_plane" {
  name                = "control-plane-pip"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "worker_cpu" {
  name                = "worker-cpu-pip"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "worker_gpu" {
  name                = "worker-gpu-pip"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interfaces
resource "azurerm_network_interface" "control_plane" {
  name                = "control-plane-nic"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.control_plane.id
  }
}

resource "azurerm_network_interface" "worker_cpu" {
  name                = "worker-cpu-nic"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_cpu.id
  }
}

resource "azurerm_network_interface" "worker_gpu" {
  name                = "worker-gpu-nic"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_gpu.id
  }
}

# Associate NSG with NICs
resource "azurerm_network_interface_security_group_association" "control_plane" {
  network_interface_id      = azurerm_network_interface.control_plane.id
  network_security_group_id = azurerm_network_security_group.control_plane.id
}

resource "azurerm_network_interface_security_group_association" "worker_cpu" {
  network_interface_id      = azurerm_network_interface.worker_cpu.id
  network_security_group_id = azurerm_network_security_group.workers.id
}

resource "azurerm_network_interface_security_group_association" "worker_gpu" {
  network_interface_id      = azurerm_network_interface.worker_gpu.id
  network_security_group_id = azurerm_network_security_group.workers.id
}

# Control Plane VM - Ubuntu 24.04
resource "azurerm_linux_virtual_machine" "control_plane" {
  name                = "control-plane"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  size                = var.cpu_vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.control_plane.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 100
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  disable_password_authentication = true
}

# Worker CPU VM - Ubuntu 24.04
resource "azurerm_linux_virtual_machine" "worker_cpu" {
  name                = "worker-cpu"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  size                = var.cpu_vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.worker_cpu.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 100
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  disable_password_authentication = true
}

# Worker GPU VM - Nvidia GPU enabled
resource "azurerm_linux_virtual_machine" "worker_gpu" {
  name                = "worker-gpu"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  size                = var.gpu_vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.worker_gpu.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 100
  }

  # Using Ubuntu 22.04 for GPU VM as it has better Nvidia driver support
  # Ubuntu 24.04 can be used but may require additional driver configuration
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true
}
