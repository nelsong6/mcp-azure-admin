# mcp-azure-personal infrastructure

Terraform that provisions this MCP server's Azure-side identity and
permissions:

| Resource | Purpose |
| --- | --- |
| `azurerm_user_assigned_identity.mcp` (in `mcp-server/`) | The UAMI everything else binds to. Display name is `mcp-azure-personal-identity` — also used as the Postgres role name for Entra-auth connections. |
| `azurerm_federated_identity_credential.pod` | Binds the K8s SA `mcp-azure-personal/mcp-azure` to the UAMI via the AKS OIDC issuer. |
| `azurerm_role_assignment.granted["subscription-operator"]` | Subscription-scope Contributor. The MCP's ARM tools call against this. |
| `azurerm_role_assignment.granted["romaine-kv-secrets-officer"]` | Data-plane Key Vault Secrets Officer on `romaine-kv`. |
| `azurerm_cosmosdb_sql_role_assignment.infra_serverless_contributor` | Cosmos data-plane Built-in Data Contributor on `infra-cosmos-serverless`. |
| `azurerm_key_vault_secret.mi_client_id` (in `mcp-server/`) | Publishes the UAMI's client ID so the chart's ExternalSecret can sync it into `AZURE_CLIENT_ID` on the pod. |
| `azurerm_postgresql_flexible_server_active_directory_administrator.tank_operator_db` | Registers the UAMI as an Entra AD admin on `tank-operator-db` so the `pg_query` tool can read the session registry. New in this PR. |

State is stored in `nelsontofu` blob container `tfstate` under key
`mcp-azure-personal.tfstate` (see `.github/workflows/tofu.yml`).

## Migration from tank-operator/infra

These resources used to be declared in `nelsong6/tank-operator/infra/mcp.tf`
inside the `mcp_azure_personal` module call. Ownership moves into this
repo without disturbing the running Azure resources, atomically across two
CI applies:

1. **Merge this PR.** Its CI runs `tofu apply` against an empty state for
   this stack. `infra/imports.tf` declares `import` blocks for the six
   pre-existing Azure resources (UAMI, FIC, the two ARM role assignments,
   the KV secret holding the UAMI client ID, and the Cosmos data-plane
   role assignment), so apply adopts them into this state instead of
   trying to create them. The
   `azurerm_postgresql_flexible_server_active_directory_administrator.tank_operator_db`
   resource is genuinely new — that's the only Azure-side change.
2. **Then merge [nelsong6/tank-operator#508](https://github.com/nelsong6/tank-operator/pull/508).** Its CI runs `tofu apply` and the
   `removed { lifecycle { destroy = false } }` blocks in its `mcp.tf`
   forget the resources from tank-operator's state without destroying
   them in Azure.

Doing them in the wrong order leaves the resources briefly orphaned in
both states (still alive in Azure, owned by neither tofu state) —
harmless and self-healing on the next apply, but worth avoiding.

After the imports apply successfully, `infra/imports.tf` can be deleted
in a follow-up PR. OpenTofu treats it as a no-op on subsequent plans
once the addresses are already in state, so leaving it in place is also
safe.
