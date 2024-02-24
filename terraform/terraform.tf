terraform {
  cloud {
    workspaces {
      name = "meta"
    }
  }
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.52.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli              = false
  use_oidc             = true
  client_id_file_path  = var.tfc_azure_dynamic_credentials.default.client_id_file_path
  oidc_token_file_path = var.tfc_azure_dynamic_credentials.default.oidc_token_file_path
}
