module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
  suffix  = ["meta"]
}

locals {
  count = 1
}

resource "random_pet" "main" {
  count     = local.count
  length    = 2
  separator = "-"
}

resource "tfe_agent_pool" "main" {
  name                = "Azure"
  organization_scoped = true
}

resource "tfe_agent_token" "main" {
  count         = local.count
  agent_pool_id = tfe_agent_pool.main.id
  description   = "Azure agent pool token for ${random_pet.main[count.index].id}"
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group.name
  location = "westeurope"
}

resource "azurerm_user_assigned_identity" "main" {
  name                = module.naming.user_assigned_identity.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_container_group" "main" {
  count               = local.count
  name                = "${module.naming.container_group.name}-${random_pet.main[count.index].id}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  os_type             = "Linux"
  ip_address_type     = "Public"
  restart_policy      = "Always"
  zones               = [tostring(count.index + 1)]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  container {
    name   = "agent"
    image  = "ghcr.io/mdmsua/tfc-agent:latest"
    cpu    = 1
    memory = 1

    ports {
      port     = 443
      protocol = "TCP"
    }

    secure_environment_variables = {
      TFC_AGENT_TOKEN = tfe_agent_token.main[count.index].token
    }

    environment_variables = {
      TFC_AGENT_NAME = random_pet.main[count.index].id
    }
  }
}

output "subscription_id" {
  value = data.azurerm_client_config.main.subscription_id
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "identity_name" {
  value = azurerm_user_assigned_identity.main.name
}
