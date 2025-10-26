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

| Name                    | Version  | Summary                                                                               |
| ----                    | -------  | -------                                                                               |
| neovim                  | 0.12.0   | Neovim text editor                                                                    |
| lua-language-server     | 3.15.0   | 'Lua language server'                                                                 |
| harper-ls               | 0.70.0   | 'Harper Language Server Grammar Checker'                                              |
| busted                  | 2.2.0-1  | Elegant Lua unit testing                                                              |
| nlua                    | 0.3.2-1  | Neovim as Lua interpreter                                                             |
| tombi                   | v0.6.39  | "TOML Formatter                                                                       |
| specify-cli             | v0.0.20  | GitHub Spec Tool                                                                      |
| mbake                   | v1.4.3   | Makefile formatter and linter                                                         |
| bash-language-server    | 5.6.0    | A language server for Bash                                                            |
| copilot                 | 0.0.351  | GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal. |
| copilot-language-server | 1.388.0  | Your AI pair programmer                                                               |
| faucet                  | 0.0.4    | human-readable TAP summarizer                                                         |
| tape                    | 5.9.0    | tap-producing test harness for node and browsers                                      |
| tree-sitter-cli         | 0.25.10  | CLI for generating fast incremental parsers                                           |
| vscode-langservers      | 4.10.0   | HTML/CSS/JSON/ESLint language servers extracted from [vscode](https://github.com/Microsoft/vscode). |
| yaml-language-server    | 1.19.2   | YAML language server                                                                  |
| google-cloud-cli        | 544.0.0  | Google Cloud CLI                                                                      |
| ShellCheck              | 0.10.0   | Shell script analysis tool                                                            |
| shfmt                   | 3.7.0    | Shell formatter                                                                       |
