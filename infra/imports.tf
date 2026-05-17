# ============================================================================
# State migration: import existing Azure resources into this stack's state
# ============================================================================
# These resources currently exist in Azure and are managed by tank-operator's
# tofu state. On first apply of this stack, the import blocks below tell
# OpenTofu to adopt them into this state without recreating them. The
# companion PR on tank-operator (mcp-azure-personal-moved-out) uses
# `removed { lifecycle { destroy = false } }` blocks to forget them from
# its state without destroying them in Azure. Net result: ownership moves
# atomically across two CI applies, no `tofu state rm`, no `tofu import`
# from a laptop.
#
# After the first successful apply that processes these imports, the
# blocks can be deleted in a follow-up PR. OpenTofu treats them as no-ops
# on subsequent plans once the address is already in state, so leaving
# them in place is also safe.
#
# IDs pulled from tank-operator's own state at branch
# mcp-azure-personal-moved-out's last plan (workflow run 26002694653).

import {
  to = module.mcp_azure_personal.azurerm_user_assigned_identity.mcp
  id = "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/infra/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mcp-azure-personal-identity"
}

import {
  to = module.mcp_azure_personal.azurerm_federated_identity_credential.pod
  id = "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/infra/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mcp-azure-personal-identity/federatedIdentityCredentials/aks-mcp-azure-personal"
}

import {
  to = module.mcp_azure_personal.azurerm_role_assignment.granted["subscription-operator"]
  id = "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/providers/Microsoft.Authorization/roleAssignments/8baf3b12-2283-faef-f27c-2ce4a3e2977b"
}

import {
  to = module.mcp_azure_personal.azurerm_role_assignment.granted["romaine-kv-secrets-officer"]
  id = "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/infra/providers/Microsoft.KeyVault/vaults/romaine-kv/providers/Microsoft.Authorization/roleAssignments/ec24c057-0be9-16ee-6b20-1e63e36f7ee5"
}

# azurerm_key_vault_secret imports take the data-plane URL with the
# current version GUID, not the ARM resource ID. Version
# 40e89e056d8044a0bc7117bb5afd5576 is the one currently in tank-operator's
# state; if it's rotated before this PR's apply runs, refresh the version
# segment from `az keyvault secret show --vault-name romaine-kv --name
# mcp-azure-personal-mi-client-id --query id -o tsv` (or the equivalent
# MCP call).
import {
  to = module.mcp_azure_personal.azurerm_key_vault_secret.mi_client_id
  id = "https://romaine-kv.vault.azure.net/secrets/mcp-azure-personal-mi-client-id/40e89e056d8044a0bc7117bb5afd5576"
}

import {
  to = azurerm_cosmosdb_sql_role_assignment.infra_serverless_contributor
  id = "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/infra/providers/Microsoft.DocumentDB/databaseAccounts/infra-cosmos-serverless/sqlRoleAssignments/6588e231-5620-f6e5-8cef-4bb6e9e13cf8"
}
