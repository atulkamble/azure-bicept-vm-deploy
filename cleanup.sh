#!/bin/bash

# Azure VM Cleanup Script
# This script removes all resources created by the Bicep deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

RESOURCE_GROUP="bicep-rg"

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}Azure VM Cleanup Script${NC}"
echo -e "${YELLOW}======================================${NC}"
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
echo -e "${YELLOW}Current subscription: ${NC}${SUBSCRIPTION}"
echo ""

# Check if resource group exists
echo -e "${YELLOW}Checking if resource group '${RESOURCE_GROUP}' exists...${NC}"
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✓ Resource group found${NC}"
    echo ""
    
    # List resources in the group
    echo -e "${YELLOW}Resources to be deleted:${NC}"
    az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type}" -o table
    echo ""
    
    # Confirmation prompt
    read -p "$(echo -e ${RED}Are you sure you want to delete all resources in \'$RESOURCE_GROUP\'? [y/N]: ${NC})" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting resource group '${RESOURCE_GROUP}' and all its resources...${NC}"
        az group delete --name $RESOURCE_GROUP --yes --no-wait
        
        echo ""
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}✓ Cleanup initiated successfully!${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo ""
        echo -e "${YELLOW}Note: Resource deletion is running in the background.${NC}"
        echo -e "${YELLOW}To check status, run:${NC}"
        echo "az group show --name $RESOURCE_GROUP"
        echo ""
    else
        echo -e "${YELLOW}Cleanup cancelled.${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}Resource group '${RESOURCE_GROUP}' not found. Nothing to clean up.${NC}"
fi
