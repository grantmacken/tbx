
## build tools 

```
podman pull ghcr.io/grantmacken/tbx-build-tools:latest
toolbox list --containers
toolbox rm building -f || true
toolbox create --image ghcr.io/grantmacken/tbx-build-tools:latest building
toolbox enter building
```


The tbx-build-toolbox container provides three tooling categories

 - cli tools
 - build tools
 - devel headers

 ### cli tools 


