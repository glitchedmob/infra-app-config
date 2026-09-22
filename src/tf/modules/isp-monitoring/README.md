# ISP monitoring identity and secrets

Creates a ZITADEL project and confidential OIDC client for the shared ISP-dashboard oauth2-proxy. The existing ZITADEL user with email `me@levizitting.com` receives the `access` role. The callback is `https://speedtest.levizitting.com:8443/oauth2/callback`.

OpenBao stores three write-only secret payloads under `applications/isp-monitoring`:

- `runtime`: Tracker application key, initial local admin password, and run-only scheduler API token.
- `oidc`: ZITADEL client ID/secret, issuer URL, and proxy cookie secret.
- `backup`: Restic repository password.

Only the `isp-monitoring-secrets` service account in the `isp-monitoring` namespace may read these paths through Kubernetes auth. Increment the corresponding secret version only for an intentional rotation. The ZITADEL provider's generated client secret is retained in protected OpenTofu state; secret payloads written to OpenBao use write-only attributes.

Preserve the runtime application key and backup password for restores. Updating `adminPassword` does not change an existing Tracker account's password.
