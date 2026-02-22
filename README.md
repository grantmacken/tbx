The following applications are included in this toolbox: 
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

 In addition to the CLI tools provided by the Fedora toolbox, we have included the following The CLI tools:


| Name                    | Version  | Summary                                                                               |
| ----                    | -------  | -------                                                                               |
| gh                      | 2.87.2   | GitHub's official command line tool.                                                  |
| make                    | 4.4.1    | A GNU tool which simplifies the build process for users                               |
| stow                    | 2.4.1    | Manage the installation of software packages from source                              |
| bat                     | 0.25.0   | Cat(1) clone with wings                                                               |
| fd-find                 | 10.3.0   | Fd is a simple, fast and user-friendly alternative to find                            |
| fzf                     | 0.67.0   | A command-line fuzzy finder written in Go                                             |
| host-spawn              | 1.6.2    | Run commands on your host from inside your toolbox or flatpak sandbox                 |
| jq                      | 1.8.1    | Command-line JSON processor                                                           |
| ripgrep                 | 14.1.1   | Line-oriented search tool                                                             |
| wl-clipboard            | 2.2.1    | Command-line copy/paste utilities for Wayland                                         |
| zoxide                  | 0.9.8    | Smarter cd command for your terminal                                                  |
# runtimes

```
podman pull ghcr.io/grantmacken/tbx-runtimes:latest
toolbox list --containers
toolbox rm runtimes -f || true
toolbox create --image ghcr.io/grantmacken/tbx-runtimes:latest runtimes
toolbox enter runtimes
```

The runtimes container provides runtimes for various programming languages.

## The beam and associated language and tooling

Included in this toolbox are the latest releases of the Erlang, Elixir and Gleam programming languages.
The Erlang programming language is a general-purpose, concurrent, functional programming language
and **runtime** system. It is used to build massively scalable soft real-time systems with high availability.
The BEAM is the virtual machine at the core of the Erlang Open Telecom Platform (OTP).
The included Elixir and Gleam programming languages also run on the BEAM.
BEAM tooling included is the latest versions of the Rebar3 and the Mix build tools.
The gleam programming language is also included.
Gleam is a statically typed language for building scalable and maintainable applications.
It compiles to efficient Erlang code that runs on the BEAM virtual machine.
It can also can compile to JavaScript for building web applications.
Which is why we also include Nodejs in this toolbox.

## nodejs
Also included in this toolbox is the nodejs runtime and associated tooling.
Nodejs is a JavaScript runtime built on Chrome's V8 JavaScript engine.
Included is the latest version of Nodejs along with the npm package manager.

## Python runtime and tooling
Python is is already included in the Fedora base image.
We add the uv package manager for Python.
The uv package manager is a fast dependency resolver and package manager for Python.
It is designed to be a modern alternative to pip and poetry.

| Name                    | Version  | Summary                                                                               |
| ----                    | -------  | -------                                                                               |
| erlang                  | 26.2.5.17 | General-purpose programming language and runtime environment                          |
| rebar3                  | 3.26.0   | Tool for working with Erlang projects                                                 |
| elixir                  | 1.19.5   | A modern approach to programming for the Erlang VM                                    |
| gleam                   | 1.14.0   | Gleam programming language                                                            |
| golang                  | 1.25.7   | The Go Programming Language                                                           |
| nodejs                  | 22.22.0  | JavaScript runtime                                                                    |
| uv                      | 0.9.30   | An extremely fast Python package installer and resolver, written in Rust              |
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
| harper-ls               | 1.8.0    | 'Harper Language Server Grammar Checker'                                              |
| lua-language-server     | 3.15.0   | 'Lua language server'                                                                 |
| tombi                   | v0.7.31  | "TOML Formatter                                                                       |
| mbake                   | v1.4.5   | Makefile formatter and linter                                                         |
| bash-language-server    | 5.6.0    | A language server for Bash                                                            |
| copilot                 | 0.0.414  | GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal. |
| copilot-language-server | 1.430.0  | Your AI pair programmer                                                               |
| tree-sitter-cli         | 0.26.5   | CLI for generating fast incremental parsers                                           |
| vscode-langservers      | 4.10.0   | HTML/CSS/JSON/ESLint language servers extracted from [vscode](https://github.com/Microsoft/vscode). |
| yaml-language-server    | 1.20.0   | YAML language server                                                                  |
| ShellCheck              | 0.11.0   | Shell script analysis tool                                                            |
| shfmt                   | 3.7.0    | Shell formatter                                                                       |
