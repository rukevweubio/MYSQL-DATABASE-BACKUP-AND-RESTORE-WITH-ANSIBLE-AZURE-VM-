
!/bin/bash
RESOURCE_GROUP="MyBackupResourceGroup"
LOCATION="eastus"
STORAGE_ACCOUNT="mysqlbackupstorage123"
CONTAINER_NAME="mysqlbackups"

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

# Get connection string
CONNECTION_STRING=$(az storage account show-connection-string \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --output tsv)

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --connection-string $CONNECTION_STRING
