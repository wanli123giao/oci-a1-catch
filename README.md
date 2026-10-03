# oci-a1-catch

Oracle Cloud A1 (2 OCPU / 12GB / 150GB, Ubuntu 24.04, us-chicago-1) capacity catcher.

Runs [hitrov/oci-arm-host-capacity](https://github.com/hitrov/oci-arm-host-capacity) on GitHub Actions schedule. Upstream pinned to commit `ea70acaf`. Workflow self-disables after a successful launch.

All credentials live in repo Actions Secrets. Delete the gist and rotate the API key if decommissioning.
