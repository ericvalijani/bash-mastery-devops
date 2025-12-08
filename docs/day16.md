# Day 16: Rootless Container Scripting with Buildah & Podman

> **Goal**: Replace Docker daemon with **secure, rootless, daemonless** workflows — the way Red Hat, Google, and security-conscious companies build containers in 2025.

## Why Buildah + Podman?
| Feature             | Docker        | Buildah + Podman       |
|---------------------|---------------|------------------------|
| Needs daemon        | Yes           | No                     |
| Needs root          | Yes           | No (rootless)          |
| OCI compliant       | Yes           | Yes                    |
| Scriptable          | Medium        | Excellent              |
| Security (CVEs)     | High risk     | Minimal                |

## Production Script: `container-builder.sh`
- Builds image with **Buildah**
- Runs with **Podman**
- Pushes to registry (GHCR/Quay)
- Signs with **Cosign** (keyless)
- Cleans up everything
- 100% idempotent & reproducible

## Test:
```bash
# Set registry login 
podman login ghcr.io

# Run the script
./scripts/advanced/day16/container-builder.sh

# Output:
# Building ghcr.io/username/myapp:20251118-ab12c3d...
# Pushing...
# Signing with Cosign...
# SUCCESS: Secure container pipeline completed
```
