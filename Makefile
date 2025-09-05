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
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
WGET := wget -q --no-check-certificate --timeout=10 --tries=3
TAR  := tar xz --strip-components=1 -C
#LISTS
CLI := eza fd-find fzf gh pass ripgrep stow wl-clipboard zoxide

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

default: neovim # cli
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
neovim: nvim xtra
	echo '✅ neovim task completed'

nvim: info/neovim.md
info/neovim.md: files/nvim.tar.gz
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	NAME=$(basename $(notdir $@))
	TARGET=files/$${NAME}/usr/local
	mkdir -p $${TARGET}
	tar xz --strip-components=1 -C $${TARGET} -f $<
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

xtra: info/mason_packages.md
	$(ADD) scripts/ /usr/local/bin/
	$(RUN) ls /usr/local/bin

	# $(RUN) /usr/local/bin/nvim_plugins
	# $(RUN) ls /usr/local/share/nvim/site/pack/core/opt | tee $@
	# $(ADD) $(<) /usr/local/bin/mason_packages



plugins: info/nvim_plugins.md
info/nvim_plugins.md: scripts/nvim_plugins
	echo '##[ $@ ]##'
	$(ADD) $(<) /usr/local/bin/nvim_plugins
	$(RUN) /usr/local/bin/nvim_plugins
	$(RUN) ls /usr/local/share/nvim/site/pack/core/opt | tee $@
	echo '✅ neovim plugins installed'

packages: info/mason_packages.md
info/mason_packages.md: scripts/mason_packages 
	echo '##[ $@ ]##'
	$(ADD) $(<) /usr/local/bin/mason_packages
	$(RUN) ls -al /usr/local/bin/
	$(RUN) /usr/local/bin/mason_packages | tee $@
	echo '✅ language servers for neovim installed'
#
# info/nvim_ts.md: scripts/nvim_ts
# 	$(ADD) $(<) /usr/local/bin/nvim_ts
# 	$(RUN) ls -al /usr/local/bin/
# 	$(RUN) /usr/local/bin/nvim_ts

cli: info/cli-tools.md
	echo '##[ $@ ]##'
	echo '✅ CLI tools added'

info/cli-tools.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) $(CLI)
	printf "\n$(HEADING2) %s\n\n" "Handpicked CLI tools available in the toolbox" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	buildah run $(WORKING_CONTAINER) sh -c  'dnf info -q --installed $(CLI) | \
	   grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	   paste  - - -  | sort -u ' | \
	   awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | tee -a $@

pull:
	echo '##[ $@ ]##'
	podman pull ghcr.io/grantmacken/tbx-coding:latest
