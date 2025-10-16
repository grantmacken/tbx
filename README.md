
# ghcr.io/grantmacken/tbx-build-tools
A Fedora Toolbox image with CLI tools and build tools
Built From: fedora-toolbox

Version:    42

Registry:   registry.fedoraproject.org/fedora-toolbox

This toolbox contains a selection of CLI tools and build tools to help with
development and building software from source. 
It is the foundation for other toolboxes I use for development.
It is the first toolbox I create when setting up a new system.
# The toolbox contains ... 


## Selected CLI Tools

| Name           | Version  | Summary                                                                             |
| ----           | -------  | ----------------------------                                                        |
| bat            | 0.25.0   | Cat(1) clone with wings                                                             |
| fd-find        | 10.2.0   | Fd is a simple, fast and user-friendly alternative to find                          |
| fzf            | 0.65.2   | A command-line fuzzy finder written in Go                                           |
| host-spawn     | 1.6.1    | Run commands on your host from inside your toolbox or flatpak sandbox               |
| jq             | 1.7.1    | Command-line JSON processor                                                         |
| ripgrep        | 14.1.1   | Line-oriented search tool                                                           |
| stow           | 2.4.1    | Manage the installation of software packages from source                            |
| wl-clipboard   | 2.2.1    | Command-line copy/paste utilities for Wayland                                       |
| zoxide         | 0.9.8    | Smarter cd command for your terminal                                                |

## Selected Build Tooling for Make Installs

| Name           | Version  | Summary                                                                             |
| ----           | -------  | ----------------------------                                                        |
| autoconf       | 2.72     | A GNU tool for automatically configuring source code                                |
| gcc            | 15.2.1   | Various compilers (C, C++, Objective-C, ...)                                        |
| gcc-c++        | 15.2.1   | C++ support for GCC                                                                 |
| make           | 4.4.1    | A GNU tool which simplifies the build process for users                             |
| pcre2          | 10.45    | Perl-compatible regular expression library                                          |
| pkgconf        | 2.3.0    | Package compiler and linker metadata toolkit                                        |

## Selected Development files for BUILD

| Name           | Version  | Summary                                                                             |
| ----           | -------  | ----------------------------                                                        |
| gettext-devel  | 0.23.1   | Development files for gettext                                                       |
| glibc-devel    | 2.41     | Object files for development using standard C libraries.                            |
| libevent-devel | 2.1.12   | Development files for libevent                                                      |
| libicu         | 76.1     | International Components for Unicode - libraries                                    |
| ncurses-devel  | 6.5      | Development files for the ncurses library                                           |
| openssl-devel  | 3.2.6    | Files for development of applications which will use OpenSSL                        |
| perl-devel     | 5.40.3   | Header files for use in perl development                                            |
| readline-devel | 8.2      | Files needed to develop programs which use the readline library                     |
