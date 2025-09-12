# tbx-coding toolbox container

```
podman pull ghcr.io/grantmacken/tbx-coding:latest
toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
toolbox enter coding
```

Provides Available Tools for the Neovim text editor

Installed in the toolbox is

 - neovim: The latest prerelease version
 - binaries of selected LSP servers, formatters and linters.
 - selected neovim plugins
 - selected treesitter parsers and queries
 - some preconfigured lsp and filetype config files


This toolbox is built **from** 2 other containers.
These containers are built in sequence.

```
 tbx-build-tools --> tbx-runtimes -- tbx-coding
```
This means that all the tools in tbx-build-tools and tbx-runtimes are available in the 
tbx-coding toolbox container.


## runtimes

The tbx-runtimes image as the name suggests, provides selected runtimes and runtime package managers

 - node runtime
   - nodejs
   - npm: aka Node Package Manager
 - beam runtime
   - OTP/Erlang with rebar3
   - Elixir with the hex package manager
   - Gleam - has own built in language server and uses hex

This tbx-runtimes image is built from the `ghcr.io/grantmacken/tbx-build-tools:latest` container image.

## build tools 

The tbx-build-toolbox container provides three tooling categories

 - cli tools
 - build tools
 - devel headers

 ### cli tools 








