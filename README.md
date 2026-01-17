<div align="center">
<h1>🚀 MyApp</h1>
<p><strong>Built with ❤️ by <a href="https://github.com/atulkamble">Atul Kamble</a></strong></p>

<p>
<a href="https://codespaces.new/atulkamble/template.git">
<img src="https://github.com/codespaces/badge.svg" alt="Open in GitHub Codespaces" />
</a>
<a href="https://vscode.dev/github/atulkamble/template">
<img src="https://img.shields.io/badge/Open%20with-VS%20Code-007ACC?logo=visualstudiocode&style=for-the-badge" alt="Open with VS Code" />
</a>
<a href="https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/atulkamble/template">
<img src="https://img.shields.io/badge/Dev%20Containers-Ready-blue?logo=docker&style=for-the-badge" />
</a>
<a href="https://desktop.github.com/">
<img src="https://img.shields.io/badge/GitHub-Desktop-6f42c1?logo=github&style=for-the-badge" />
</a>
</p>

<p>
<a href="https://github.com/atulkamble">
<img src="https://img.shields.io/badge/GitHub-atulkamble-181717?logo=github&style=flat-square" />
</a>
<a href="https://www.linkedin.com/in/atuljkamble/">
<img src="https://img.shields.io/badge/LinkedIn-atuljkamble-0A66C2?logo=linkedin&style=flat-square" />
</a>
<a href="https://x.com/atul_kamble">
<img src="https://img.shields.io/badge/X-@atul_kamble-000000?logo=x&style=flat-square" />
</a>
</p>

<strong>Version 1.0.0</strong> | <strong>Last Updated:</strong> January 2026
</div>



## 🚀 Azure VM Deployment using **Bicep Language** (Step-by-Step)

![Image](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/n-tier/images/single-vm-diagram.svg)

![Image](https://www.coforge.com/hs-fs/hubfs/bicep-code.png?height=554\&name=bicep-code.png\&width=658)

![Image](https://www.mssqltips.com/wp-content/images-tips/6407_azure-vm-deployment.001.png)

![Image](https://learn.microsoft.com/en-us/azure/azure-compute-fleet/media/vm-attribute/attribute-based-vm-selection-diagram.png)

This guide shows **how to deploy an Azure Virtual Machine using Bicep**, Microsoft’s native **Infrastructure as Code (IaC)** language for **Microsoft Azure**.

---

## 🔹 What is Bicep?

* Declarative IaC language (simpler than ARM JSON)
* Compiles to ARM templates
* Native Azure support
* Ideal for **DevOps, CI/CD, Terraform alternative learners**

---

## 🏗️ Architecture (Basic VM Setup)

```
Resource Group
 ├── Virtual Network (VNet)
 │    └── Subnet
 │         └── Network Interface (NIC)
 │              └── Virtual Machine (Linux)
 └── Network Security Group (NSG)
```

---

## ✅ Prerequisites

* Azure Subscription
* Azure CLI installed
* Bicep CLI (comes with Azure CLI ≥ 2.20)

```bash
az login
az bicep install
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

## 📁 Project Structure

```
azure-vm-bicep/
 ├── main.bicep
 ├── parameters.bicep
 └── README.md
```

---

## 🧩 main.bicep (Complete VM Deployment)

```bicep
param location string = 'eastus'
param vmName string = 'demo-vm'
param adminUsername string = 'azureuser'
@secure()
param adminPassword string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'demo-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
```

---

## 🧩 parameters.bicep

```bicep
param location = 'eastus'
param vmName = 'cloudnautic-vm'
param adminUsername = 'atul'
param adminPassword = 'P@ssw0rd123!'
```

> 🔐 **Best Practice**: Use Azure Key Vault for passwords in production

---

## 🚀 Deploy the VM

```bash
az group create \
  --name bicep-rg \
  --location eastus

az deployment group create \
  --resource-group bicep-rg \
  --template-file main.bicep \
  --parameters parameters.bicep
```

---

## 🔍 Verify Deployment

```bash
az vm list -g bicep-rg -o table
az vm show -g bicep-rg -n cloudnautic-vm
```

---

## 🧠 Key Bicep Concepts Used

| Concept      | Purpose                |
| ------------ | ---------------------- |
| `param`      | Input variables        |
| `resource`   | Azure resources        |
| `@secure()`  | Secure parameters      |
| `properties` | Resource configuration |
| `id`         | Resource linking       |

---

## ⭐ Best Practices

* Use **modules** for VNet, VM, NSG
* Store secrets in **Azure Key Vault**
* Use **Bicep linter**
* Integrate with **GitHub Actions / Azure DevOps**
* Enable **Managed Identity**

---
