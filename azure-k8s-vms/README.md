# Azure Kubernetes Cluster VMs Terraform Module

This Terraform module creates Azure VMs for a Kubernetes cluster with mixed node pool (CPU/GPU nodes).

## Architecture

The module creates:
- **1 Control Plane VM** (`control-plane`): Ubuntu 24.04 CPU VM with kubeadm-compatible network rules
- **1 CPU Worker VM** (`worker-cpu`): Ubuntu 24.04 CPU VM for general workloads
- **1 GPU Worker VM** (`worker-gpu`): Ubuntu 22.04 VM with Nvidia GPU support (Standard_NC6s_v3)

All VMs are deployed in the same Azure region and resource group with proper networking for Kubernetes cluster formation.

## Network Security

### Control Plane NSG Rules
The control plane VM has the following inbound rules to allow kubeadm operations:
- **Port 6443**: Kubernetes API Server
- **Ports 2379-2380**: etcd server client API
- **Port 10250**: Kubelet API
- **Port 10259**: kube-scheduler
- **Port 10257**: kube-controller-manager
- **Port 22**: SSH access

### Worker Nodes NSG Rules
Worker nodes have the following inbound rules:
- **Port 10250**: Kubelet API
- **Ports 30000-32767**: NodePort Services
- **Port 22**: SSH access

All rules allow traffic from within the Virtual Network only.

## Prerequisites

1. Azure subscription
2. Azure CLI installed and configured
3. Terraform >= 1.0
4. SSH key pair for VM access

## Usage

1. **Clone the repository**:
   ```bash
   cd azure-k8s-vms
   ```

2. **Create a terraform.tfvars file**:
   ```hcl
   resource_group_name = "my-k8s-cluster-rg"
   location            = "eastus"
   admin_ssh_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your-email@example.com"
   
   # Optional overrides
   cpu_vm_size = "Standard_D2s_v3"
   gpu_vm_size = "Standard_NC6s_v3"
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Access the VMs**:
   After deployment, use the output SSH connection strings:
   ```bash
   terraform output ssh_connection_strings
   ```

## Kubernetes Cluster Setup

After the VMs are created, you can set up a Kubernetes cluster:

### On the Control Plane VM:
```bash
# SSH into control plane
ssh azureuser@<control-plane-public-ip>

# Initialize the cluster (example)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Save the join command that kubeadm outputs
```

### On Worker VMs:
```bash
# SSH into each worker
ssh azureuser@<worker-public-ip>

# Run the join command from control plane
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### GPU Support on Worker GPU VM:
The GPU worker VM requires Nvidia drivers and container runtime:
```bash
# Install Nvidia drivers
sudo apt update
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# Install nvidia-container-toolkit
# Follow: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the Azure Resource Group | string | "k8s-cluster-rg" | no |
| location | Azure region for all resources | string | "eastus" | no |
| vnet_address_space | Address space for the virtual network | list(string) | ["10.0.0.0/16"] | no |
| subnet_address_prefixes | Address prefixes for the subnet | list(string) | ["10.0.1.0/24"] | no |
| admin_username | Admin username for all VMs | string | "azureuser" | no |
| admin_ssh_key | SSH public key for VM access | string | n/a | **yes** |
| cpu_vm_size | Size for CPU VMs | string | "Standard_D2s_v3" | no |
| gpu_vm_size | Size for GPU VM with Nvidia support | string | "Standard_NC6s_v3" | no |
| tags | Tags to apply to all resources | map(string) | {"Environment": "dev", "Purpose": "k8s-cluster"} | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Name of the created resource group |
| location | Azure region where resources are deployed |
| control_plane_public_ip | Public IP address of the control plane VM |
| control_plane_private_ip | Private IP address of the control plane VM |
| worker_cpu_public_ip | Public IP address of the CPU worker VM |
| worker_cpu_private_ip | Private IP address of the CPU worker VM |
| worker_gpu_public_ip | Public IP address of the GPU worker VM |
| worker_gpu_private_ip | Private IP address of the GPU worker VM |
| ssh_connection_strings | SSH connection strings for all VMs |

## VM Specifications

### CPU VMs (Control Plane & Worker CPU)
- **OS**: Ubuntu 24.04 LTS Server
- **Default Size**: Standard_D2s_v3 (2 vCPUs, 8 GB RAM)
- **Disk**: 100 GB Premium SSD

### GPU VM (Worker GPU)
- **OS**: Ubuntu 22.04 LTS (better Nvidia driver support)
- **Default Size**: Standard_NC6s_v3 (6 vCPUs, 112 GB RAM, 1 x NVIDIA Tesla V100)
- **Disk**: 100 GB Premium SSD

## Notes

- The GPU VM uses Ubuntu 22.04 instead of 24.04 for better out-of-box Nvidia driver compatibility
- All VMs use SSH key authentication (password authentication is disabled)
- Public IPs are static to ensure consistent access
- Network security is configured for internal cluster communication
- Additional firewall rules may be needed for external access to services

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## License

This module is provided as-is for infrastructure setup purposes.
