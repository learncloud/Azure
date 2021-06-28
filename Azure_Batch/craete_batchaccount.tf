provider azurerm {
    version = "~>2.0"
        features {}
}
 
resource "azurerm_resource_group" "rg" {
  name     = var.resourcename
  location = var.location
  tags     = var.tags 
}
 
resource "azurerm_storage_account" "strg" {
  name                     = "jhbatchstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
 
resource "azurerm_storage_share" "strgfile" {
  name                 = "jhfiles"
  storage_account_name = azurerm_storage_account.strg.name
  quota                = 100
}
 
resource "azurerm_batch_account" "example" {
  name                 = "jhbatchtest"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  pool_allocation_mode = "BatchService"
  storage_account_id   = azurerm_storage_account.strg.id
 
  tags = {
    env = "test"
  }
}