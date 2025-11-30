## build tools 

```
podman pull ghcr.io/grantmacken/tbx-build-tools:latest
toolbox list --containers
toolbox rm building -f || true
toolbox create --image ghcr.io/grantmacken/tbx-build-tools:latest building
toolbox enter building
```


The building toolbox container provides three tooling categories
 - build tools: gcc, gcc-c++, pcre2, autoconf, and pkgconf
 - development headers and libraries
 - CLI tools


