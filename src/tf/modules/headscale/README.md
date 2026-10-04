# Mastodon on nothotdog

`tag:mastodon` identifies the Raspberry Pi running Mastodon and Caddy. Only
`group:infra` owns this tag. The `mastodon` user owns the enrollment key; a
registered tagged node uses its tags as its identity, not this user's identity.

The public edge can reach the Pi's Caddy on TCP 80 and 443. Levi's devices can
also reach those ports and TCP 22 for ordinary SSH. This does not enable
Tailscale SSH for the Pi or grant access to its database, Redis, or ports 9998
and 9999. There are no Mastodon route or exit-node auto-approvals. Keep subnet
route and exit-node advertisements disabled on the Pi.

`headscale_mastodon_auth_key` exposes the SSM path
`/homelab/headscale/mastodon/nothotdog-auth-key` in `ssm_paths`, not the secret.
The key is single-use, valid for one hour, and non-ephemeral. Increment its
`auth_key_rotation_version` only when a new enrollment key is needed.
Non-ephemeral enrollment prevents ephemeral-node cleanup; it does not disable
node-key expiry.

The public-edge repository pins Headscale v0.29.4. That version clears node-key
expiry when a new node registers with a tagged pre-auth key or with approved
requested tags. See [the registration code](https://github.com/juanfont/headscale/blob/v0.29.4/hscontrol/state/state.go#L1913-L1974).
For dashboard enrollment, confirm the node has `tag:mastodon` and no node-key
expiry. Merely adding a tag to an existing node preserves its expiry, as covered
by [the expiry tests](https://github.com/juanfont/headscale/blob/v0.29.4/hscontrol/state/auth_tagged_expiry_test.go#L1547-L1619).
The key's one-hour validity is separate from the registered node's expiry.
