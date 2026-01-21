output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.k8s.name
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.k8s.location
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.k8s.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.k8s.id
}

output "control_plane_public_ip" {
  description = "Public IP address of the control plane VM"
  value       = azurerm_public_ip.control_plane.ip_address
}

output "control_plane_private_ip" {
  description = "Private IP address of the control plane VM"
  value       = azurerm_network_interface.control_plane.private_ip_address
}

output "worker_cpu_public_ip" {
  description = "Public IP address of the CPU worker VM"
  value       = azurerm_public_ip.worker_cpu.ip_address
}

output "worker_cpu_private_ip" {
  description = "Private IP address of the CPU worker VM"
  value       = azurerm_network_interface.worker_cpu.private_ip_address
}

output "worker_gpu_public_ip" {
  description = "Public IP address of the GPU worker VM"
  value       = azurerm_public_ip.worker_gpu.ip_address
}

output "worker_gpu_private_ip" {
  description = "Private IP address of the GPU worker VM"
  value       = azurerm_network_interface.worker_gpu.private_ip_address
}

output "control_plane_vm_id" {
  description = "ID of the control plane VM"
  value       = azurerm_linux_virtual_machine.control_plane.id
}

output "worker_cpu_vm_id" {
  description = "ID of the CPU worker VM"
  value       = azurerm_linux_virtual_machine.worker_cpu.id
}

output "worker_gpu_vm_id" {
  description = "ID of the GPU worker VM"
  value       = azurerm_linux_virtual_machine.worker_gpu.id
}

output "ssh_connection_strings" {
  description = "SSH connection strings for all VMs"
  value = {
    control_plane = "ssh ${var.admin_username}@${azurerm_public_ip.control_plane.ip_address}"
    worker_cpu    = "ssh ${var.admin_username}@${azurerm_public_ip.worker_cpu.ip_address}"
    worker_gpu    = "ssh ${var.admin_username}@${azurerm_public_ip.worker_gpu.ip_address}"
  }
}
