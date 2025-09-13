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
WORKING_CONTAINER := tbx-runtimes-working-container
TBX_IMAGE :=  ghcr.io/grantmacken/tbx-coding
# actions
RUN     := buildah run $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
SH      := $(RUN) sh -c
# LINK    := $(RUN) ln -s $(shell which host-spawn)
# SPAWN    := 
ADD     := buildah add --chmod 755 $(WORKING_CONTAINER)
RW_ADD := buildah add --chmod  644 $(WORKING_CONTAINER)
WGET    := wget -q --no-check-certificate --timeout=10 --tries=3

# XDG_DATA_DIRS
# everything is site dir
DIR_NVIM    := /usr/local/share/nvim/site
DIR_BIN     := /usr/local/bin

LSP_CONF_URL := https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/

TAR     := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

NPM      := $(RUN) npm install --global
NPM_LIST := $(RUN) npm list -g --depth=0

LSP_CONF_URL := https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

lsp_confs := $(wildcard xdg/nvim/lsp/*.lua)
lsp_targs := $(patsubst xdg/nvim/lsp/%.lua,info/lsp/%.md,$(lsp_confs))

ft_confs  := $(wildcard xdg/nvim/after/filetype/*.lua)
ft_targs := $(patsubst xdg/nvim/after/filetype/*.lua, info/filetype/%.md,$(ft_confs))

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)
HEADING3 := $(HEADING2)$(HEADING1)

default: init nvim treesitter  mason # plugins lsp_confs filetype_confs

ifdef GITHUB_ACTIONS
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	# REM
	# buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	# buildah push $(TBX_IMAGE):latest
endif

init:
	# echo '##[ $@ ]##'
	buildah pull ghcr.io/grantmacken/tbx-runtimes &>  /dev/null
	buildah from ghcr.io/grantmacken/tbx-runtimes
	# the runtime should have
	$(RUN) which make &> /dev/null
	$(RUN) which npm &> /dev/null
	$(RUN) which luarocks &> /dev/null
	$(RUN) mkdir -p $(DIR_NVIM)

# link:
# 	$(SPAWN) $(DIR_BIN)/firefox
# 	$(SPAWN) $(DIR_BIN)/bin/podman
# 	$(SPAWN) $(DIR_BIN)/buildah
# 	$(SPAWN) $(DIR_BIN/skopeo

nvim: info/neovim.md
	echo '✅ latest pre-release neovim installed'

files/nvim.tar.gz:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz" -O $@

info/neovim.md: files/nvim.tar.gz
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	NAME=$(basename $(notdir $@))
	TARGET=files/$${NAME}/usr/local
	mkdir -p $${TARGET}
	$(TAR) $${TARGET} -f $<
	$(ADD) files/$${NAME} &> /dev/null
	# CHECKS silent:
	$(RUN) nvim -v &> /dev/null
	$(RUN) whereis nvim &> /dev/null
	$(RUN) which nvim &> /dev/null
	# Write to file
	VERSION=$$($(RUN) nvim -v | grep -oP 'NVIM \K.+' | cut -d'-' -f1 )
	SUM='The text editor with a focus on extensibility and usability'
	printf "| %-10s | %-13s | %-83s |\n" "$${NAME}" "$${VERSION}" "$${SUM}" | tee -a $@
	# add the nvim scripts
	$(ADD) scripts/ $(DIR_BIN)/
	# $(RUN) ls -al $(DIR_BIN)

mason_registry:
	echo '##[ $@ ]##'
	# create the dir mason uses to store packages
	$(RUN) mkdir -p /usr/local/share/mason
	$(RUN) nvim_mason_registry &>/dev/null
	$(RUN) ls /usr/local/share/mason
	echo '✅ mason registry added'

mason: mason_registry
	echo '##[ $@ ]##'
	# run the script that install mason packages
	$(RUN) nvim_mason &>/dev/null #  2>&1 >/dev/null
	# take a look at what is installed
	$(RUN) ls /usr/local/share/mason/bin
	# link installed packages to $(DIR_BIN)
	# use SH to allow for globbing
	$(SH) 'ln -s /usr/local/share/mason/bin/* $(DIR_BIN)/'
	# check bin dir
	# $(RUN) ls -l /usr/local/bin
	echo '✅ selected mason lsp	 servers, linters and formaters installed'

npm:
	echo '##[ $@ ]##'
	# dependency for treesitter
	$(NPM) tree-sitter-cli &>/dev/null
	# also install lsp server not on mason registry
	$(NPM) @mistweaverco/kulala-ls &>/dev/null
	echo '✅ selected npm packages installed'

treesitter: npm
	echo '##[ $@ ]##'
	# create the dir where ts parser as queries will be installed
	# run the script that install treesitter parsers and queries
	$(RUN) nvim_treesitter || true
	$(RUN) tree /usr/local/share/nvim
	echo '✅ selected treesitter parsers and queries added'

plugins:
	# echo '##[ $@ ]##'
	$(RUN) nvim_plugins  /dev/null
	# $(RUN) ls /usr/local/share/nvim/site/pack/core/opt | tee $@
	echo '✅ selected nvim plugins installed'

# files in $(DIR_NVIM)/lsp
lsp_confs: lsp_local lsp_urls
	$(RUN) ls -al $(DIR_NVIM)/lsp
	echo '✅ Installed all lsp confs'

lsp_local: $(lsp_targs)
	echo '✅ preconfigured local lsp configs installed'

LSPCONFIGS := copilot.lua 
lsp_urls:
	for conf in $(LSPCONFIGS)
	do
	$(RW_ADD) $(LSP_CONF_URL)/$$conf  $(DIR_NVIM)/lsp/$$conf
	done
 
# https://github.com/neovim/nvim-lspconfig/tree/master/lsp

info/lsp/%.md: xdg/nvim/lsp/%.lua
	echo '##[ lsp: $* ]]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p $(DIR_NVIM)/lsp
	$(RW_ADD) $< $(DIR_NVIM)/lsp/$*


filetype_confs: $(ft_targs)
	echo '✅ Installed preconfigured filetype confs'

info/filetype/%.md: xdg/nvim/after/filetype/%.lua
	echo '##[ lsp: $* ]]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p $(DIR_NVIM)/lsp
	$(RW_ADD) $< $(DIR_NVIM)/lsp/$*
	$(RUN) ls -al $(DIR_NVIM)/lsp/$*
	echo '✅ lsp: $*' | tee $@

# $(RW_ADD) xdg/nvim/after/filetype/lua.lua $(DIR_FILETYPE)/lua.lua

info/cli-tools.md:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) $(CLI_VIA_DNF) &> /dev/null
	printf "\n$(HEADING2) %s\n\n" "Handpicked CLI tools available in the toolbox" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	$(SH) 'dnf info -q --installed $(CLI_VIA_DNF) | \
	   grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	   paste  - - -  | sort -u ' | \
	   awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | tee -a $@

dnf_lsp_pkgs: info/lsp-tooling.md
	echo '##[ $@ ]##'
	echo '✅ LSP servers added'
	echo '✅ Additional formaters and linters added'

info/lsp-tooling.md:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) $(LSP_VIA_DNF) &> /dev/null
	printf "\n$(HEADING2) %s\n\n" "dnf installed LSP tooling available in the toolbox" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	buildah run $(WORKING_CONTAINER) sh -c  'dnf info -q --installed $(LSP_VIA_DNF) | \
	   grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	   paste  - - -  | sort -u ' | \
	   awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | tee -a $@

pull:
	echo '##[ $@ ]##'
	hostspawn
	podman pull ghcr.io/grantmacken/tbx-coding:latest
	toolbox list --containers
	# toolbox list --images
	toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
	exit
