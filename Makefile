SHELL=/usr/bin/bash
.SHELLFLAGS := -euo pipefail -c
# -e Exit immediately if a pipeline fails
# -u Error if there are unset variables and parameters
# -o option-name Set the option corresponding to option-name
.ONESHELL:
.DELETE_ON_ERROR:
.SECONDARY:

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
unexport MAKEFLAGS

# Colors
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[0;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
WHITE=\033[0;37m
NC=\033[0m # No Color

WORKING_CONTAINER := tbx-runtimes-working-container
# actions
RUN     := buildah run $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
SH      := $(RUN) sh -c
# LINK    := $(RUN) ln -s $(shell which host-spawn)
ADD    := buildah add --chmod 755 $(WORKING_CONTAINER)
RW_ADD := buildah add --chmod  644 $(WORKING_CONTAINER)
WGET   := wget -q --no-check-certificate --timeout=10 --tries=3
# everything is site dir
DIR_SITE   := /usr/share/nvim/site
DIR_BIN    := /usr/local/bin
DIR_MASON  := /usr/local/share/mason

# URL_LSPCONFIG := https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/
TAR           := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

NPM      := $(RUN) npm install --global
LUAROCKS := $(RUN) luarocks install --global
# NPM_LIST := $(RUN) npm list -g --depth=0 --json

tr = printf "| %-18s | %-8s | %-85s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

lsp_confs := $(wildcard site/lsp/*.lua)
lsp_targs := $(patsubst site/lsp/%.lua,info/site/lsp/%.md,$(lsp_confs))

ft_confs  := $(wildcard site/after/filetype/*.lua)
ft_targs := $(patsubst  site/after/ftplugin/*.lua, info/after/ftplugin/%.md,$(ft_confs))

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)
HEADING3 := $(HEADING2)$(HEADING1)

# BASH_LIST := nodejs-bash-language-server ShellCheck shfmt
RELEASE_BINARY_LIST :=  neovim lua-language-server # harper-ls
DNF_LIST     :=  google-cloud-cli # ShellCheck shfmt
UV_TOOL_LIST :=  tombi specify-cli mbake
# @mistweaverco/kulala-ls
NPM_LIST := bash-language-server \
			# copilot \
			# copilot-language-server \
			# tree-sitter-cli \
			# vscode-langservers-extracted \
			# yaml-language-server

ROCKS_LIST := busted nlua
PKGS_LIST := $(NPM_LIST) # $(DNF_LIST) $(RELEASE_BINARY_LIST) $(UV_TOOL_LIST) # $(ROCKS_LIST) #  

## Helper to write info files in a consistent format
define to_info
    printf "Name: %s\n"    "$(1)" > $@
	printf "Version: %s\n" "$(2)" >> $@
	printf "Summary: %s\n" "$(3)" >> $@
endef

default: info/README.md

rem:
	echo '##[ $@ ]##'
	buildah commt $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-coding
	buildah push ghcr.io/grantmacken/tbx-coding:latest
	echo '✅ ghcr.io/grantmacken/tbx-coding:latest built and pushed'

info/README.md: init $(PKGS_LIST)
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# create or overwrite README.md
	# preamble
	printf "# %s\n\n" "tbx-coding: a toolbox for coding" | tee $@
	printf "A toolbox container image with cli tools, neovim, lsp servers, linters and formaters.\n\n" | tee -a $@
	printf "## %s\n\n" "Installed applications" | tee -a $@
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(PKGS_LIST)
	do
	NAME=$$(cat info/$${pkg}.md | grep -oP '^Name:\s\K.+' || true)
	VER=$$(cat info/$${pkg}.md | grep -oP '^Version:\s\K.+' || true)
	SUM=$$(cat info/$${pkg}.md | grep -oP '^Summary:\s\K.+' || true)
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done

init:
	echo '##[ $@ ]##'
	buildah pull ghcr.io/grantmacken/tbx-runtimes &>/dev/null
	buildah from ghcr.io/grantmacken/tbx-runtimes &>/dev/null
	$(ADD) scripts/ $(DIR_BIN)/ &>/dev/null
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label description='a toolbox with cli tools, neovim, lsp servers, linters and formaters' \
	--label org.opencontainers.image.source='https://github.com/grantmacken/tbx-coding' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 \
	--env UV_TOOL_BIN_DIR=/usr/local/bin \
	--env UV_TOOL_DIR=/var/lib/uv_tools \
	$(WORKING_CONTAINER)
	mkdir -p info
	mkdir -p latest
	# update dnf repos
	$(RUN) dnf update -y &>/dev/null

# release binaries:
# neovim lua-language-server harper-ls

neovim: info/neovim.md
info/neovim.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	TARGET=files/$${PKG}/usr/local
	mkdir -p $${TARGET}
	SRC='https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz'
	$(WGET) $${SRC} -O- | $(TAR) $${TARGET}
	$(ADD) files/$${PKG} &> /dev/null
	# success|failure check
	$(RUN) nvim --version &> /dev/null
	$(RUN) whereis nvim &> /dev/null
	$(RUN) which nvim &> /dev/null
	# get version from the binary
	VER=$$($(RUN) nvim -v | grep -oP 'NVIM v\K\d+\.\d+\.\d+' )
	$(call to_info,$${PKG},$${VER},Neovim text editor)

lua-language-server: info/lua-language-server.md
latest/lua-language-server.json:
	$(WGET) https://api.github.com/repos/LuaLS/lua-language-server/releases/latest -O- | jq '.' > $@

info/lua-language-server.md: latest/lua-language-server.json
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	SRC=$(shell $(call bdu,linux-x64.tar.gz,$<))
	TARGET=files/$${PKG}/usr/local/$${PKG}
	mkdir -p $${TARGET}
	$(WGET) $${SRC} -O- | $(TAR_NO_STRIP) $${TARGET}
	$(ADD) files/$${PKG} &> /dev/null
	# note the lua-language-server binary is in bin/ subdir
	# the exec script in /usr/local/bin/lua-language-server will point to it 
	# these scripts are added in init target
	# success|failure caheck
	$(RUN) which $${PKG}  &> /dev/null
	$(RUN) $${PKG} --version &> /dev/null
	# extract 'name', 'version', 'summary'
	# get version from the binary
	VER=$$($(RUN) lua-language-server --version)
	$(call to_info,$${PKG},$${VER},'Lua language server')

#uv tools: 
# tombi 
# mbake 
# specify-cli

define uv_tool_info
# extract 'name', 'version', 'summary'
	LINE=$$($(RUN) uv tool list | grep $(1) )
	# extract 'name', 'version', 'summary'
	NAME=$$(echo $$LINE | cut -d' ' -f1)
	VER=$$(echo $$LINE  | cut -d' ' -f2)
	SUM='$(2)'
	$(call to_info,$${NAME},$${VER},$${SUM})
endef

tombi: info/tombi.md
info/tombi.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	$(RUN) uv tool install $${PKG} &> /dev/null
	# success|failure check
	$(RUN) which tombi &> /dev/null
	$(RUN) tombi --version &> /dev/null
	# extract 'name', 'version', 'summary'
	# VER=$$($(RUN) tombi --version | cut -d' ' -f2)
	$(call uv_tool_info,$${PKG},TOML Toolkit)
	# $(call to_info,$${PKG},$${VER},'TOML Toolkit')

specify-cli: info/specify-cli.md
info/specify-cli.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	$(RUN) uv tool install $${PKG} --from git+https://github.com/github/spec-kit.git &> /dev/null
	# success|failure check
	$(RUN) which specify &> /dev/null
	$(RUN) whereis specify &> /dev/null
	$(call uv_tool_info,$${PKG},GitHub Spec Tool)

mbake: info/mbake.md
info/mbake.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	$(RUN) uv tool install $${PKG} &> /dev/null
	# success|failure check
	$(RUN) which mbake || true
	$(RUN) mbake --version || true
	# extract 'name', 'version', 'summary'
	$(call uv_tool_info,$${PKG},Makefile formatter and linter)

# npm packages:
# bash-language-server
# copilot
# copilot-language-server
# tree-sitter-cli
# vscode-langservers-extracted
# yaml-language-server
define npm_install
	JSON=$$($(RUN) npm view --json $(1) | jq '.')
	# From the veiw extract 'name', 'version', 'description'
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	# install the package globally and use
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) $${NAME} --version &>/dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})
endef

define npm_install_info
	JSON=$$($(RUN) npm view --json $(1) | jq '.')
	# From the veiw extract 'name', 'version', 'description'
	$(call to_info,
	$$(echo $${JSON} | jq -r '.name'),
	$$(echo $${JSON} | jq -r '."dist-tags".latest'),
	$$(echo $${JSON} | jq -r '.description'))
endef

bash-language-server: info/bash-language-server.md
info/bash-language-server.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	$(call npm_install,$${PKG})
	# success|failure check
	$(RUN) bash-language-server --version &> /dev/null
	$(call npm_install_info,$${PKG})
	echo '✅ $(basename $(notdir $@)) installed'

copilot: info/copilot.md
info/copilot.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	JSON=$$($(RUN) npm view --json @github/copilot | jq '.')
	# extract 'name', 'version', 'description' into to a table row
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) copilot --version
	# Write to file
	printf "Name: %s\n" "$${NAME}" > $@
	printf "Version: %s\n" "$${VER}" >> $@
	printf "Summary: %s\n" "$${SUM}" >> $@

copilot-language-server: info/copilot-language-server.md
info/copilot-language-server.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	JSON=$$($(RUN) npm view --json @github/copilot-language-server | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# TODO
	# Write to file
	printf "Name: %s\n" "$${NAME}" > $@
	printf "Version: %s\n" "$${VER}" >> $@
	printf "Summary: %s\n" "$${SUM}" >> $@

tree-sitter-cli: info/tree-sitter-cli.md
info/tree-sitter-cli.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	JSON=$$($(RUN) npm view --json tree-sitter-cli | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) tree-sitter --version
	# Write to file
	printf "Name: %s\n" "$${NAME}" > $@
	printf "Version: %s\n" "$${VER}" >> $@
	printf "Summary: %s\n" "$${SUM}" >> $@

vscode-langservers-extracted: info/vscode-langservers-extracted.md
info/vscode-langservers-extracted.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	JSON=$$($(RUN) npm view --json vscode-langservers-extracted | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	#  "vscode-css-language-server": "bin/vscode-css-language-server",
	#  "vscode-eslint-language-server": "bin/vscode-eslint-language-server",
	#  "vscode-html-language-server": "bin/vscode-html-language-server",
	#  "vscode-json-language-server": "bin/vscode-json-language-server",
	#  "vscode-markdown-language-server": "bin/vscode-markdown-language-server"
	# Write to file
	printf "Name: %s\n" "$${NAME}"   > $@
	printf "Version: %s\n" "$${VER}" >> $@
	printf "Summary: %s\n" "$${SUM}" >> $@

yaml-language-server: info/yaml-language-server.md
info/yaml-language-server.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	JSON=$$($(RUN) npm view --json tree-sitter-cli | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	#$(RUN) tree-sitter --version
	# Write to file
	printf "Name: %s\n" "$${NAME}" | tee $@
	printf "Version: %s\n" "$${VER}" | tee -a $@
	printf "Summary: %s\n" "$${SUM}" | tee -a $

# dnf packages:
# google-cloud-cli
# ShellCheck
# shfmt
#
define dnf_installed_info
  	LINES=$$($(RUN) dnf info --installed $(1))
	# extract 'name', 'version', 'summary'
	VER=$$(echo "$${LINES}" | grep -oP '^Version\s+:\s+\K.+' || true)
	SUM=$$(echo "$${LINES}" | grep -oP '^Summary\s+:\s+\K.+' || true)
	# consistent write to file format
	$(call to_info,$(1),$${VER},$${SUM})
endef

google-cloud-cli: info/google-cloud-cli.md
info/google-cloud-cli.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	# add the repo
	$(RUN) mkdir -p /etc/yum.repos.d
	$(ADD) files/google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo &> /dev/null
	$(INSTALL) libxcrypt-compat $${PKG} &> /dev/null
	# success|failure check
	# Note the binary is named 'gcloud'
	$(RUN) gcloud --version &> /dev/null
	$(RUN) whereis gcloud &> /dev/null
	$(RUN) which gcloud &> /dev/null
	$(call dnf_installed_info,$${PKG})

ShellCheck: info/ShellCheck.md
info/ShellCheck.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	$(INSTALL) $${PKG} &> /dev/null
	# success|failure check
	# Note the binary is named 'sheckcheck'
	$(RUN) which shellcheck &> /dev/null
	$(RUN) shellcheck --version &> /dev/null
	$(call dnf_installed_info,$${PKG})

shfmt: info/shfmt.md
info/shfmt.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	$(INSTALL) $${PKG} &> /dev/null
	# verify installation
	$(RUN) whereis $${PKG} &> /dev/null
	$(RUN) which $${PKG} &> /dev/null
	$(RUN) $${PKG} --version &> /dev/null
	$(call dnf_installed_info,$${PKG})

# luarocks packages: 
# busted 
# nlua

busted: info/busted.md
info/busted.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	$(LUAROCKS) $${PKG} &> /dev/null
	# verify installation
	$(RUN) which $${PKG} || true
	$(RUN) $${PKG} --version || true
	# extract 'name', 'version', 'summary'
	$(RUN) luarocks show --porcelain $${NAME} | grep -oP '^busted.+' || true
	LINE=$$($(RUN) luarocks show  $${NAME} | grep -oP '^busted.+')
	NAME=$$(echo $${LINE} | cut -d' ' -f1 || true)
	VER=$$(echo $${LINE} | cut -d' ' -f2 || true)
	SUM=$$(echo $${LINE} | cut -d'-' -f2 || true)
	$call to_info,$${NAME},$${VER},$${SUM}

nlua: info/nlua.md
info/nlua.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	mkdir -p $(dir $@)
	$(LUAROCKS) $${NAME} &> /dev/null
	# verify installation
	$(RUN) which $${NAME} || true
	LINES=$$($(RUN) luarocks show  --porcelain $${NAME} | head -n 3)
	echo "$${LINES}"
	# extract 'name', 'version', 'summary'
	NAME=$$(echo $${LINES} | grep -oP '^package\s+\K.+' || true)
	VER=$$(echo $${LINES} | grep -oP '^version\s+\K.+' || true)
	SUM=$$(echo $${LINES} | grep -oP '^summary\s+\K.+' || true)
	$(call to_info,$${NAME},$${VER},$${SUM})

pull:
	echo '##[ $@ ]##'
	host-spawn
	podman pull ghcr.io/grantmacken/tbx-coding:latest
	# toolbox list --containers
	# toolbox list --images
	#toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
	exit
