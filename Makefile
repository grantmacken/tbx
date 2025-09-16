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
ADD     := buildah add --chmod 755 $(WORKING_CONTAINER)
RW_ADD := buildah add --chmod  644 $(WORKING_CONTAINER)
WGET    := wget -q --no-check-certificate --timeout=10 --tries=3

# everything is site dir
DIR_SITE   := /usr/share/nvim/site
DIR_BIN    := /usr/local/bin
DIR_MASON  := /usr/local/share/mason

URL_LSPCONFIG := https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/
TAR          := tar xz --strip-components=1 -C
# TAR_NO_STRIP := tar xz -C

NPM      := $(RUN) npm install --global
NPM_LIST := $(RUN) npm list -g --depth=0

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

lsp_confs := $(wildcard site/lsp/*.lua)
lsp_targs := $(patsubst site/lsp/%.lua,info/site/lsp/%.md,$(lsp_confs))

ft_confs  := $(wildcard site/after/filetype/*.lua)
ft_targs := $(patsubst  site/after/ftplugin/*.lua, info/after/ftplugin/%.md,$(ft_confs))

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)
HEADING3 := $(HEADING2)$(HEADING1)

default: init nvim mason npm # plugins treesitter plugins lsp_confs ft_confs

ifdef GITHUB_ACTIONS
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \:
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	# REM
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest
endif

init:
	# echo '##[ $@ ]##'
	buildah pull ghcr.io/grantmacken/tbx-runtimes &>/dev/null
	buildah from ghcr.io/grantmacken/tbx-runtimes
	# the runtime should have
	$(RUN) which make &> /dev/null
	$(RUN) which npm &> /dev/null
	$(RUN) which luarocks &> /dev/null
	$(RUN) mkdir -p $(DIR_SITE)
	$(ADD) scripts/ $(DIR_BIN)/

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

mason_registry:
	echo '##[ $@ ]##'
	# create the dir mason uses to store packages
	$(RUN) mkdir -p $(DIR_MASON)
	$(RUN) nvim_mason_registry &>/dev/null
	echo '✅ mason registry loaded'

mason: mason_registry
	echo '##[ $@ ]##'
	# run the script that install mason packages
	$(RUN) nvim_mason &>/dev/null #  2>&1 >/dev/null
	# take a look at what is installed
	$(RUN) ls $(DIR_MASON)/bin
	# link installed packages to $(DIR_BIN)
	# use SH here to allow for globbing
	$(SH) 'ln -s $(DIR_MASON)/bin/* $(DIR_BIN)/'
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
	$(RUN)  nvim_treesitter &>/dev/null
	$(RUN) ls  $(DIR_SITE)/parser | grep -oP '^\w+'
	echo '✅ selected treesitter parsers and queries added'

plugins:
	# echo '##[ $@ ]##'
	$(RUN) nvim_plugins &> /dev/null
	$(RUN) ls $(DIR_SITE)/pack/core/opt
	echo '✅ selected nvim plugins installed'

# files in $(DIR_SITE)/lsp
lsp_confs: lsp_local lsp_urls
	$(RUN) ls $(DIR_SITE)/lsp
	echo '✅ Installed all lsp confs'

lsp_local: $(lsp_targs)
	echo '✅ preconfigured local lsp configs installed'

LSPCONFIGS := copilot.lua
lsp_urls:
	for conf in $(LSPCONFIGS)
	do
	$(RW_ADD) $(URL_LSPCONFIG)/$$conf  $(DIR_SITE)/lsp/$$conf
	done

## @see https://github.com/neovim/nvim-lspconfig/tree/master/lsp
info/site/lsp/%.md: site/lsp/%.lua
	echo '##[ lsp: $* ]]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p $(DIR_SITE)/lsp
	$(RW_ADD) $< $(DIR_SITE)/lsp/$*

ft_confs: $(ft_targs)
	echo '✅ Installed preconfigured filetype confs'

info/site/ftplugin/%.md: site/after/ftplugin/%.lua
	echo '##[ lsp: $* ]]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p $(DIR_SITE)/after/ftplugin
	$(RW_ADD) $< $(DIR_SITE)/after/ftplugin/$*
	$(RUN) ls -al $(DIR_SITE)/ftplugin/$*
	echo '✅ lsp: $*' | tee $@

pull:
	echo '##[ $@ ]##'
	hostspawn
	podman pull ghcr.io/grantmacken/tbx-coding:latest
	toolbox list --containers
	# toolbox list --images
	toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
	exit
