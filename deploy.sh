#!/bin/bash

# Azure VM Deployment Script using Bicep
# This script automates the deployment of Azure VM infrastructure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="bicep-rg"
LOCATION="eastus"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="parameters.json"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Azure VM Deployment Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if Azure CLI is installed
echo -e "${YELLOW}Checking Azure CLI installation...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

echo -e "${GREEN}✓ Azure CLI installed${NC}"
echo ""

# Check if Azure CLI is logged in
echo -e "${YELLOW}Checking Azure CLI login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure CLI${NC}"
    echo "Please run: az login"
    exit 1
fi

echo -e "${GREEN}✓ Azure CLI logged in${NC}"
echo ""

# Display current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${YELLOW}Current subscription:${NC} ${SUBSCRIPTION}"
echo -e "${YELLOW}Subscription ID:${NC} ${SUBSCRIPTION_ID}"
echo ""

# Check if Bicep is installed
echo -e "${YELLOW}Checking Bicep CLI installation...${NC}"
if ! az bicep version &> /dev/null; then
    echo -e "${YELLOW}Bicep CLI not found. Installing...${NC}"
    az bicep install
    echo -e "${GREEN}✓ Bicep CLI installed${NC}"
else
    echo -e "${GREEN}✓ Bicep CLI installed${NC}"
    BICEP_VERSION=$(az bicep version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo -e "${YELLOW}  Version:${NC} ${BICEP_VERSION}"
fi
echo ""

# Check if template file exists
echo -e "${YELLOW}Checking for Bicep template file...${NC}"
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: Template file '$TEMPLATE_FILE' not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Template file found: ${TEMPLATE_FILE}${NC}"
echo ""

# Check if parameters file exists
echo -e "${YELLOW}Checking for parameters file...${NC}"
if [ ! -f "$PARAMETERS_FILE" ]; then
    echo -e "${RED}Error: Parameters file '$PARAMETERS_FILE' not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Parameters file found: ${PARAMETERS_FILE}${NC}"
echo ""

# Validate Bicep template
echo -e "${YELLOW}Validating Bicep template...${NC}"
if az bicep build --file "$TEMPLATE_FILE" &> /dev/null; then
    echo -e "${GREEN}✓ Bicep template is valid${NC}"
else
    echo -e "${RED}Error: Bicep template validation failed${NC}"
    az bicep build --file "$TEMPLATE_FILE"
    exit 1
fi
echo ""

# Check if resource group exists
echo -e "${YELLOW}Checking if resource group exists...${NC}"
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}Resource group '${RESOURCE_GROUP}' already exists${NC}"
    read -p "$(echo -e ${YELLOW}Do you want to continue with existing resource group? [Y/n]: ${NC})" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Deployment cancelled.${NC}"
        exit 0
    fi
else
    # Create resource group
    echo -e "${YELLOW}Creating resource group '${RESOURCE_GROUP}' in '${LOCATION}'...${NC}"
    az group create --name $RESOURCE_GROUP --location $LOCATION --output none
    echo -e "${GREEN}✓ Resource group created${NC}"
fi
echo ""

# Deploy Bicep template
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Starting Deployment...${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${YELLOW}Deploying Bicep template to resource group '${RESOURCE_GROUP}'...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters $PARAMETERS_FILE \
    --query "properties.provisioningState" \
    --output tsv 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment completed successfully${NC}"
    echo ""
    
    # Verify deployment
    echo -e "${YELLOW}Verifying deployment...${NC}"
    echo ""
    
    echo -e "${YELLOW}Virtual Machines:${NC}"
    az vm list -g $RESOURCE_GROUP -o table
    echo ""
    
    echo -e "${YELLOW}Virtual Networks:${NC}"
    az network vnet list -g $RESOURCE_GROUP --query "[].{Name:name, AddressSpace:addressSpace.addressPrefixes[0], Location:location}" -o table
    echo ""
    
    echo -e "${YELLOW}Network Interfaces:${NC}"
    az network nic list -g $RESOURCE_GROUP --query "[].{Name:name, PrivateIP:ipConfigurations[0].privateIPAddress}" -o table
    echo ""
    
    # Get VM details
    VM_NAME=$(az vm list -g $RESOURCE_GROUP --query "[0].name" -o tsv)
    if [ -n "$VM_NAME" ]; then
        echo -e "${YELLOW}VM Details:${NC}"
        az vm show -g $RESOURCE_GROUP -n $VM_NAME \
            --query "{Name:name, Location:location, Size:hardwareProfile.vmSize, Status:provisioningState, OS:storageProfile.imageReference.offer, AdminUser:osProfile.adminUsername}" \
            -o table
        echo ""
    fi
    
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ Deployment Successful!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "${YELLOW}Resource Group:${NC} ${RESOURCE_GROUP}"
    echo -e "${YELLOW}Location:${NC} ${LOCATION}"
    echo ""
    echo -e "${YELLOW}To view resources in Azure Portal:${NC}"
    echo "https://portal.azure.com/#@/resource/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/overview"
    echo ""
    echo -e "${YELLOW}To delete all resources, run:${NC}"
    echo "./cleanup.sh"
    echo ""
else
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}✗ Deployment Failed${NC}"
    echo -e "${RED}======================================${NC}"
    echo ""
    echo -e "${RED}Error details:${NC}"
    echo "$DEPLOYMENT_OUTPUT"
    exit 1
fi
