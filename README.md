# AI-Infra

Infrastructure as Code for AI workloads.

## Modules

### [azure-k8s-vms](./azure-k8s-vms/)
Terraform module for provisioning Azure VMs for a Kubernetes cluster with mixed CPU/GPU node pool.

**Features:**
- 2 CPU VMs running Ubuntu 24.04 (control-plane + worker)
- 1 GPU VM with Nvidia support (Standard_NC6s_v3)
- All in the same region and resource group
- Network security configured for kubeadm
- Production-ready with comprehensive documentation

**Quick Start:**
```bash
cd azure-k8s-vms
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

See [azure-k8s-vms/README.md](./azure-k8s-vms/README.md) for detailed documentation.
