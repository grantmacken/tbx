# tbx-coding: a toolbox for coding

This tbx-coding toolbox container image is built **from**
 - the tbx-runtimes toolbox image which is is built **from**
 - the tbx-build-tools toolbox image which is is built **from**
 - the fedora toolbox container image.

This tbx-coding toolbox includes a selection of development tools focused on coding, including neovim, language servers, linters, and formatters.
## Features
 - Neovim: A modern and extensible text editor.
 - Language Servers: Support for various programming languages to provide features like auto-completion, go-to-definition, and real-time error checking.
 - Linters and Formatters: Tools to help maintain code quality and consistency.

## Usage
To install the toolbox container image, use the following command:
```bash
podman pull ghcr.io/grantmacken/tbx-coding:latest
toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
toolbox enter coding
```

Once inside the toolbox, you can start using neovim and other installed tools for your coding projects.

