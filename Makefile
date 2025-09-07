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

RUN := buildah run $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
NPM := $(RUN) npm install --global
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
WGET := wget -q --no-check-certificate --timeout=10 --tries=3
TAR  := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C


#LISTS
CLI_VIA_DNF := eza fd-find fzf gh pass ripgrep stow wl-clipboard zoxide
LSP_VIA_DNF := ShellCheck shfmt
# https://github.com/artempyanykh/marksman/releases
LSP_VIA_RELEASES := artempyanykh/marksman
LSP_VIA_NPM := bash-language-server  @github/copilot-language-server
DNF_PKGS := $(CLI_VIA_DNF) $(LSP_VIA_DNF)

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
getName = $(basename $(notdir $1))

default: dnf_lsp_pkgs gh_releases
	echo '##[ $@ ]##'
	echo 'image built'
ifdef GITHUB_ACTIONS
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest
endif

init: .env
	echo '##[ $@ ]##'

latest/tbx-build-tools.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://${FROM_IMAGE}:latest | jq '.' > $@

.env: latest/tbx-build-tools.json
	echo '##[ $@ ]##'
	FROM=$$(cat $< | jq -r '.Name')
	printf "FROM=%s\n" "$$FROM" | tee $@
	buildah pull "$$FROM" &> /dev/null
	echo -n "WORKING_CONTAINER=" | tee -a .env
	buildah from "$$FROM" | tee -a .env

files/nvim.tar.gz:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz" -O $@

##[[ NEOVIM ]]#
neovim: nvim
	echo '✅ neovim task completed'

nvim: info/neovim.md
info/neovim.md: files/nvim.tar.gz
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p /etc/xdg/nvim/{plugin,lsp,queries,parser}
	NAME=$(basename $(notdir $@))
	TARGET=files/$${NAME}/usr/local
	mkdir -p $${TARGET}
	$(TAR) $${TARGET} -f $<
	$(ADD) files/$${NAME} &>/dev/null
	# CHECK:
	$(RUN) nvim -v
	$(RUN) whereis nvim
	$(RUN) which nvim
	# Write to file
	VERSION=$$($(RUN) nvim -v | grep -oP 'NVIM \K.+' | cut -d'-' -f1 )
	SUM='The text editor with a focus on extensibility and usability'
	printf "| %-10s | %-13s | %-83s |\n" "$${NAME}" "$${VERSION}" "$${SUM}" | tee -a $@
	echo '✅ latest pre-release neovim installed'

plugins:
	$(ADD) scripts/ /usr/local/bin/
	$(RUN) /usr/local/bin/nvim_plugins
	$(RUN) ls /usr/local/share/nvim/site/pack/core/opt | tee $@

node_pkgs: info/node_pkgs.md
info/node_pkgs.md:
	echo '##[ $@ ]##'
	$(NPM) $(LSP_VIA_NPM)
	# Checks
	$(RUN) which bash-language-server 
	$(RUN) whereis bash-language-server
	$(RUN) bash-language-server  --version

dnf_lsp_pkgs: info/lsp_tooling_via_dnf.md
info/lsp_tooling_via_dnf.md:
	echo '##[ $@ ]##'
	$(INSTALL) $(LSP_VIA_DNF)

gh_releases: lua-language-server marksman harper

lua-language-server: info/lua-language-server.md

latest/lua-language-server.json:
	echo '##[ $(basename $(notdir $@)) ]##'
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	REPO=luals/lua-language-server
	$(WGET) https://api.github.com/repos/$${REPO}/releases/latest -O $@

files/lua-language-server.tar.gz: latest/lua-language-server.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) $(shell $(call bdu,linux-x64.tar.gz,$<)) -O $@

info/lua-language-server.md: files/lua-language-server.tar.gz
	mkdir -p $(dir $@)
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=lua-language-server
	TARGET=files/$${NAME}
	mkdir -p $${TARGET}
	$(TAR_NO_STRIP) $${TARGET} -f $<
	$(ADD) $${TARGET} /usr/local/$${NAME}
	# $(RUN) ls -al /usr/local/
	$(RUN) ln -sf /usr/local/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
	$(RUN) ls -al /usr/local/bin
	$(RUN) which $${NAME}
	$(RUN) whereis $${NAME}
	$(RUN) $${NAME} --version

marksman: latest/marksman.json
latest/marksman.json:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	mkdir -p $(dir $@)
	REPO=artempyanykh/marksman
	# https://github.com/Automattic/harper/releases
	$(WGET) https://api.github.com/repos/$${REPO}/releases/latest -O $@

harper: latest/harper.json
latest/harper.json:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	mkdir -p $(dir $@)
	REPO=Automattic/harper
	# https://github.com/Automattic/harper/releases
	$(WGET) https://api.github.com/repos/$${REPO}/releases/latest -O $@

# DNF
dnf_lsp_pkgs: info/lsp-tooling.md
	echo '##[ $@ ]##'
	echo '✅ LSP servers added'
	echo '✅ Additional formaters and linters added'

info/lsp-tooling.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) $(LSP_VIA_DNF)
	printf "\n$(HEADING2) %s\n\n" "Handpicked CLI tools available in the toolbox" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	buildah run $(WORKING_CONTAINER) sh -c  'dnf info -q --installed $(LSP_VIA_DNF) | \
	   grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	   paste  - - -  | sort -u ' | \
	   awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | tee -a $@

dnf_cli_pkgs: info/cli-tools.md
	echo '✅ CLI tools added'

info/cli-tools.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) $(CLI_VIA_DNF)
	printf "\n$(HEADING2) %s\n\n" "Handpicked CLI tools available in the toolbox" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	buildah run $(WORKING_CONTAINER) sh -c  'dnf info -q --installed $(CLI_VIA_DNF) | \
	   grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	   paste  - - -  | sort -u ' | \
	   awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | tee -a $@

pull:
	echo '##[ $@ ]##'
	podman pull ghcr.io/grantmacken/tbx-coding:latest
