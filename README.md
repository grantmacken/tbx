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

This toolbox is built from the `ghcr.io/grantmacken/tbx-runtimes:latest` container image.

The tbx-runtimes image as the name suggest provides selected runtimes and runtime package managers

 - node runtime
   - nodejs
   - npm: aka Node Package Manager
 - beam runtime
   - OTP/Erlang with rebar3
   - Elixir with the hex package manager
   - Gleam - has own built in language server and uses hex













