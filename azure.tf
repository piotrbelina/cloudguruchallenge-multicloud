resource "azurerm_resource_group" "rg" {
  name     = var.azure_resource_group_name
  location = var.azure_resource_group_location
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "acg-challenge-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_free_tier = true

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "aws_ssm_parameter" "cosmosdb_endpoint" {
  name  = "acg_challenge_cosmosdb_endpoint"
  type  = "String"
  value = azurerm_cosmosdb_account.db.endpoint
}

resource "aws_ssm_parameter" "cosmosdb_primary_key" {
  name  = "acg_challenge_cosmosdb_primary_key"
  type  = "SecureString"
  value = azurerm_cosmosdb_account.db.primary_key
}