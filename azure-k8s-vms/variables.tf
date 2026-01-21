variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "k8s-cluster-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "cpu_vm_size" {
  description = "Size for CPU VMs"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "gpu_vm_size" {
  description = "Size for GPU VM with Nvidia support"
  type        = string
  default     = "Standard_NC6s_v3"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Purpose     = "k8s-cluster"
  }
}
