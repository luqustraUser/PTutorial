# 🌐 Azure Hub-Spoke Infrastructure Deployment using Terraform

This project automates the provisioning of a **Hub-and-Spoke network topology** in **Microsoft Azure** using **Terraform**. It includes secure networking, compute resources, and backend for CI/CD Network Virtual Appliances (NVAs).

---

## 🚀 Features

- Deploys an enterprise-grade **Hub-and-Spoke** virtual network topology.
- Provisions **virtual machines** in each network segment (Hub, Spoke1, Spoke2).
- Supports **Ubuntu (ARM64 and x64)** platform images.
- Automatically generates secure passwords if not provided.
- Modular and production-ready infrastructure-as-code.
- GitHub integration for version control and CI/CD extensibility.

---

## 📁 Project Structure

PTutorial/
├── backend.tf # Remote state backend (Azure Storage)
├── hub-vnet.tf # Hub network, NSG, route table, VM
├── spoke1.tf # Spoke1 network and VM
├── spoke2.tf # Spoke2 network and VM
├── hub-nva.tf # Network Virtual Appliance (optional)
├── variables.tf # Input variable declarations
├── terraform.tfvars # Variable value assignments
├── outputs.tf # Output values after deployment
├── main.tf # Entry point (optional if splitting files)
└── README.md # Documentation (this file)


---

## ⚙️ Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) v1.3 or higher
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (logged in via `az login`)
- An active [Azure Subscription](https://azure.microsoft.com/free)

---

## 🔐 Admin Password Logic

Terraform uses the following logic for virtual machine passwords:

- If `admin_password` is **not provided**, a **secure 20-character password** is generated automatically.
- If you provide `admin_password`, it must be **at least 12 characters long** (validated in code).

---

## 🛠️ How to Use

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/PTutorial.git
cd PTutorial (It depends where is your local folder is.)

###
🌍 Architecture Diagram



         +-----------------------+
         |        HUB VNet       |
         |  +-----------------+  |
         |  |     Hub VM      |  |
         |  +-----------------+  |
         +----------+------------+
                    |
      +-------------+-------------+
      |                           |
+-------------+           +-------------+
|  Spoke1 VM  |           |  Spoke2 VM  |
| Spoke1 VNet |           | Spoke2 VNet |
+-------------+           +-------------+




