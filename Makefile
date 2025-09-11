SHELL=/usr/bin/bash
.SHELLFLAGS := -euo pipefail -c
# -e Exit immediately if a pipeline fails
# -u Error if there are unset variables and parameters
# -o option-name Set the option corresponding to option-name
#
# https://mason-registry.dev/registry/list
#
.ONESHELL:
.DELETE_ON_ERROR:
.SECONDARY:

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
unexport MAKEFLAGS

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)
HEADING3 := $(HEADING2)$(HEADING1)

include .env

FROM_IMAGE := ghcr.io/grantmacken/tbx-runtimes
NAME := tbx-coding
WORKING_CONTAINER ?= $(NAME)-working-container
TBX_IMAGE :=  ghcr.io/grantmacken/$(NAME)
# actions
RUN     := buildah run $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
SH      := $(RUN) sh -c
# LINK    := $(RUN) ln -s $(shell which host-spawn)
ADD     := buildah add --chmod 755 $(WORKING_CONTAINER)
RW_ADD := buildah add --chmod  644 $(WORKING_CONTAINER)
WGET    := wget -q --no-check-certificate --timeout=10 --tries=3

DIR_FILETYPE := /etc/xdg/nvim/after/filetype
DIR_LSP      := /etc/xdg/nvim/lsp
DIR_BIN      := /usr/local/bin
LSP_CONF_URL := https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp/

TAR     := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

NPM      := $(RUN) npm install --global
NPM_LIST := $(RUN) npm list -g --depth=0

#LISTS
CLI_VIA_DNF := eza fd-find fzf pass ripgrep stow wl-clipboard zoxide
LSP_VIA_DNF := ShellCheck shfmt
# https://github.com/artempyanykh/marksman/releases
VIA_RELEASES := artempyanykh/marksman
VIA_NPM      := bash-language-server yaml-language-server vscode-langservers-extracted stylelint-lsp
VIA_AT_NPM   :=  @github/copilot-language-server @ast-grep/cli
# @githubnext/copilot-cl

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
lsp_conf_url := https://raw.githubusercontent.com/neovim/nvim-lspconfig/refs/heads/master/lsp

default:  xdg gh_releases # parsers_queries dnf_pkgs npm_pkgs nvim_plugins

ifdef GITHUB_ACTIONS
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest
endif

init: .env
	# echo '##[ $@ ]##'
	# the runtime should have
	$(RUN) which make &> /dev/null
	$(RUN) which npm &> /dev/null
	$(RUN) which luarocks &> /dev/null
	$(RUN) mkdir -p $(DIR_FILETYPE) $(DIR_LSP)

latest/tbx-build-tools.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://${FROM_IMAGE}:latest | jq '.' > $@

.env: latest/tbx-build-tools.json
	# echo '##[ $@ ]##'
	FROM=$$(cat $< | jq -r '.Name')
	printf "FROM=%s\n" "$$FROM" | tee $@
	buildah pull "$$FROM" &>  /dev/null
	echo -n "WORKING_CONTAINER=" | tee -a .env
	buildah from "$$FROM" | tee -a .env

# link:
# 	$(LINK) /usr/local/bin/firefox
# 	$(LINK) /usr/local/bin/podman
# 	$(LINK) /usr/local/bin/buildah
# 	$(LINK) /usr/local/bin/skopeo

gh_releases: nvim lua-language-server marksman harper

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

nvim_plugins:
	# echo '##[ $@ ]##'
	$(ADD) scripts/ /usr/local/bin/
	$(RUN) /usr/local/bin/nvim_plugins &> /dev/null
	$(RUN) ls /usr/local/share/nvim/site/pack/core/opt | tee $@
	echo '✅ selected nvim plugins installed'

xdg: copilot

copilot:
	URL=$(LSP_CONF_URL)/$@.lua
	$(RW_ADD) $$URL $(DIR_LSP)/$@.lua
	$(RUN) ls -al $(DIR_LSP)



lua-language-server: info/lua-language-server.md

latest/lua-language-server.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/luals/lua-language-server/releases/latest -O $@

files/lua-language-server.tar.gz: latest/lua-language-server.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) $(shell $(call bdu,linux-x64.tar.gz,$<)) -O $@

info/lua-language-server.md: files/lua-language-server.tar.gz
	mkdir -p $(dir $@)
	TARGET=files/lua-language-server
	mkdir -p $${TARGET}
	$(TAR_NO_STRIP) $${TARGET} -f $<
	$(ADD) $${TARGET} /usr/local/lua-language-server
	# $(RUN) ls -al /usr/local/
	$(RUN) ln -sf /usr/local/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
	# abort if error checks:
	$(RUN) which lua-language-server &> /dev/null
	$(RUN) lua-language-server --version &> /dev/null
	echo '✅ lua-language-server installed' | tee $@
	# echo '✅ lsp config for lua-langauge-server added'
	# $(RUN) mkdir -p /etc/xdg/nvim/after/filetype
	$(RW_ADD) etc/xdg/nvim/lsp/lua_ls.lua
	$(RUN) ls -al $(DIR_LSP)/lua_ls.lua
	# echo '✅ enabled lua-language-server for lua files'
	# echo '✅ enabled treesitter for lua files'
	#
	
marksman: latest/marksman.json

latest/marksman.json:
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/artempyanykh/marksman/releases/latest -O $@

files/marksman.tar.gz: latest/marksman.json
	mkdir -p $(dir $@)
	$(WGET) $(shell $(call bdu,linux-x64.tar.gz,$<)) -O $@

info/marksman.md: files/marksman.tar.gz
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	TARGET=files/$(basename $(notdir))
	mkdir -p $$TARGET
	echo $$TARGET





harper: latest/harper.json
latest/harper.json:
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/Automattic/harper/releases/latest -O $@

# DNF
dnf_pkgs: dnf_gh dnf_cli_pkgs dnf_lsp_pkgs 
	echo '✅ Completed DNF installs'

dnf_gh:
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &>  /dev/null
	$(RUN) dnf info -q --installed gh

dnf_cli_pkgs: info/cli-tools.md
	echo '✅ CLI tools added'

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

###############
##    NPM    ##
###############

npm_pkgs: info/npm_pkgs.md
	echo '✅ NPM packages installed'

info/npm_pkgs.md:
	# echo '##[ $@ ]##'
	$(NPM) $(VIA_NPM) &> /dev/null
	$(NPM) $(VIA_AT_NPM) &> /dev/null
	$(NPM_LIST)

TS_ROCKS := \
awk \
bash \
comment \
css \
csv \
diff \
djot \
dtd \
ebnf \
elixir \
erlang \
git_config \
gitignore \
gleam \
gnuplot \
html \
http \
javascript \
jq \
json \
just \
latex \
ledger \
make \
markdown_inline \
mermaid \
nginx \
printf \
readline \
regex \
ssh_config \
toml \
xml \
yaml

ROCKS  := $(patsubst %,tree-sitter-%,$(TS_ROCKS))
ROCKS_BINARIES := https://nvim-neorocks.github.io/rocks-binaries
ROCKS_PATH := /usr/local/rocks
ROCKS_LIB_PATH := $(ROCKS_PATH)/lib/luarocks/rocks-5.1
LR_OPTS := --tree $(ROCKS_PATH) --server $(ROCKS_BINARIES) --no-doc  --deps-mode one
SHOW_OPTS := --tree $(ROCKS_PATH)

parsers_queries:
	$(RUN) mkdir -p /etc/xdg/nvim/parser
	$(RUN) mkdir -p /etc/xdg/nvim/queries
	for ROCK in $(ROCKS)
	do
	$(RUN) luarocks install $(LR_OPTS) $$ROCK &> /dev/null
	VER=$$($(RUN) luarocks show --mversion --tree $(ROCKS_PATH) $$ROCK)
	DIR=$(ROCKS_LIB_PATH)/$$ROCK/$$VER
	$(SH) "cp $$DIR/parser/* /etc/xdg/nvim/parser/"
	$(SH) "cp -r $$DIR/queries/* /etc/xdg/nvim/queries/"
	done
	$(RUN) luarocks purge --tree $(ROCKS_PATH) &> /dev/null
	# $(RUN) tree /etc/xdg/nvim
	echo '✅ selected treesitter parsers and queries added'

pull:
	echo '##[ $@ ]##'
	hostspawn
	podman pull ghcr.io/grantmacken/tbx-coding:latest
	toolbox list --containers
	# toolbox list --images
	toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
	exit
