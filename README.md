# tbx-coding: a toolbox for coding

This tbx-coding toolbox container image is built **from**
 - the tbx-runtimes toolbox image which is built **from**
 - the tbx-build-tools toolbox image which is built **from**
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

Once inside the toolbox, you can start Using neovim and other installed tools for your coding projects.

| Name                    | Version  | Summary                                                                               |
| ----                    | -------  | -------                                                                               |
| neovim                  | 0.12.0   | Neovim text editor                                                                    |
| harper-ls               | 1.1.0    | 'Harper Language Server Grammar Checker'                                              |
| lua-language-server     | 3.15.0   | 'Lua language server'                                                                 |
| tombi                   | v0.7.0   | "TOML Formatter                                                                       |
| mbake                   | v1.4.3   | Makefile formatter and linter                                                         |
| bash-language-server    | 5.6.0    | A language server for Bash                                                            |
| copilot                 | 0.0.365  | GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal. |
| copilot-language-server | 1.399.0  | Your AI pair programmer                                                               |
| tree-sitter-cli         | 0.25.10  | CLI for generating fast incremental parsers                                           |
| vscode-langservers      | 4.10.0   | HTML/CSS/JSON/ESLint language servers extracted from [vscode](https://github.com/Microsoft/vscode). |
| yaml-language-server    | 1.19.2   | YAML language server                                                                  |
| nvim-plugins            | 1.0.0    | 'Neovim plugins installed via nvim_plugins script'                                    |
| nvim-treesitters        | 1.0.0    | 'Neovim treesitter parsers installed via nvim_treesitters script'                     |
| ShellCheck              | 0.11.0   | Shell script analysis tool                                                            |
| shfmt                   | 3.7.0    | Shell formatter                                                                       |
