# infra-app-config

Manages post-bootstrap configuration for LZ edge-hosted applications.

Currently owns: Headscale users, ACL policy, and pre-auth key lifecycle.

## Scope
- Owns: Headscale user resources for humans, infrastructure nodes, and GitHub Actions identities.
- Owns: Headscale ACL/tag policy and route approval rules.
- Owns: pre-auth key generation and storage in AWS SSM Parameter Store.

## Structure
- `src/tf/`: OpenTofu resources for users, ACL policy, and auth key modules.
- `src/tf/modules/headscale-pre-auth-key/`: Reusable module for key generation and SSM writes.
- `.github/workflows/`: Plan/validate/apply automation for this stack.

## Run
```bash
make help
make tf-init
make tf-plan
make tf-apply
make tf-output
```

## Operating constraints
- Apply after Headscale is reachable (deployed by [`glitchedmob/infra-public-edge`](https://github.com/glitchedmob/infra-public-edge)).
