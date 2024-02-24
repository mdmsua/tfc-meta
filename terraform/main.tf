module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
  suffix  = ["meta"]
}

resource "tfe_agent_pool" "main" {
  name                = "Azure"
  organization_scoped = true
}

resource "tfe_agent_token" "main" {
  agent_pool_id = tfe_agent_pool.main.id
  description   = "Azure agent pool token"
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group.name
  location = "westeurope"
}

resource "azurerm_container_group" "main" {
  name                = module.naming.container_group.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  os_type             = "Linux"
  ip_address_type     = "Public"
  restart_policy      = "Always"
  zones               = ["1", "2", "3"]

  identity {
    type = "SystemAssigned"
  }

  container {
    name         = "main"
    image        = "ghcr.io/mdmsua/tfc-agent:latest"
    cpu          = 2
    cpu_limit    = 4
    memory       = 2
    memory_limit = 4

    secure_environment_variables = {
      TFC_AGENT_TOKEN = tfe_agent_token.main.token
    }
  }
}

output "identity_principal_id" {
  value = azurerm_container_group.main.identity.0.principal_id
}
