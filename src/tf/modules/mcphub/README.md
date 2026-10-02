# MCPHub identity and secrets

This module follows the same two-phase OIDC bootstrap as Sparky and Tandoor. It owns the Zitadel project, access role, OIDC client, OpenBao policy, Kubernetes auth role, and generated secrets.

## OIDC bootstrap

1. Apply with `bootstrap_oidc_client_secret = true` and `rotate_oidc_client_secret = false`. This creates a NONE-auth client, regenerates its secret through the ephemeral resource, and writes it to OpenBao without storing the payload in OpenTofu state.
2. Set `bootstrap_oidc_client_secret = false` and apply again, without changing `secret_versions.oidc`. This switches the client to POST authentication and stops evaluating the ephemeral secret resource.

The initial configuration is phase one. Complete phase two before testing sign-in or applying unrelated changes. Do not rerun plans with a generation flag still enabled after successful generation: the provider can regenerate a secret even when no OpenBao write is pending.

The callback is `https://mcp.levizitting.com/api/auth/better/oauth2/callback/zitadel`. MCPHub's generic OAuth provider uses `client_secret_post`, so the final method is `OIDC_AUTH_METHOD_TYPE_POST` rather than the BASIC method used by Sparky and Tandoor. The MCPHub deployment enables PKCE S256. Verify both in the browser login flow.

For intentional OIDC rotation, enable `rotate_oidc_client_secret`, increment `secret_versions.oidc`, apply once, then disable the flag before further plans. Coordinate the Kubernetes Secret refresh and application restart. Generation and the OpenBao write are not transactional; recover a failed write before restoring login.

## Secret contract

| OpenBao KV v2 path | Properties |
| --- | --- |
| `applications/mcphub/runtime` | `jwtSecret`, `betterAuthSecret`, `credentialEncryptionKey`, `adminPassword` |
| `applications/mcphub/oidc` | `providerId`, `clientId`, `clientSecret`, `issuerUrl` |
| `applications/mcphub/backup` | `resticPassword` |

Generated values use ephemeral resources and write-only `data_json_wo`, with reads disabled. The encryption key is 32 random bytes encoded as base64. The `mcphub-secrets` OpenBao role is bound to service account `mcphub-secrets` in namespace `mcphub`, with read-only access to `applications/data/mcphub/*` and token lookup/renew permissions.

Do not increment runtime or backup versions for ordinary changes. Runtime rotation replaces the encryption key, which makes existing personal bindings unreadable unless they are migrated. Preserve the original key separately from database backups. Changing `adminPassword` does not reset an existing MCPHub account. Coordinate a restic password change before replacing the backup secret.

## User access

Grant each trial user the `access` role in the dedicated `MCPHub` Zitadel project. `project_role_check = true` rejects users with no role in this project. Existing Sparky or Tandoor grants do not grant MCPHub access. Zitadel access does not make a user an MCPHub administrator.
