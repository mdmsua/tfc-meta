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
    type = "SystemAssigned"
  }

  container {
    name         = "main"
    image        = "ghcr.io/mdmsua/tfc-agent:latest"
    cpu          = 2
    cpu_limit    = 2
    memory       = 2
    memory_limit = 2

    ports {
      port     = 443
      protocol = "TCP"
    }

    secure_environment_variables = {
      TFC_AGENT_TOKEN = tfe_agent_token.main[count.index].token
    }
  }
}

output "identity_principal_id" {
  value = [azurerm_container_group.main[*].identity.0.principal_id]
}
