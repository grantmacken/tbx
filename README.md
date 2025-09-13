# tbx

```
podman pull ghcr.io/grantmacken/tbx-build-tools:latest
toolbox list --containers
toolbox rm building -f || true
toolbox create --image ghcr.io/grantmacken/tbx-build-tools:latest building
toolbox enter building
```

```
podman pull ghcr.io/grantmacken/tbx-runtimes:latest
toolbox list --containers
toolbox rm runtimes -f || true
toolbox create --image ghcr.io/grantmacken/tbx-runtimes runtimes
toolbox enter runtimes
```

```
podman pull ghcr.io/grantmacken/tbx-coding:latest
toolbox list --containers
toolbox rm runtimes -f || true
toolbox create --image ghcr.io/grantmacken/tbx-coding coding
toolbox enter coding
```
