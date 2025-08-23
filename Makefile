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

FROM_IMAGE := ghcr.io/grantmacken/tbx-build-tools
NAME := tbx-coding
WORKING_CONTAINER ?= $(NAME)-working-container
TBX_IMAGE :=  ghcr.io/grantmacken/$(NAME)

RUN := buildah run $(WORKING_CONTAINER)
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
#LISTS
CLI := eza fd-find fzf gh wl-clipboard zoxide

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
	
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
neovim: info/neovim.md
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
	VERSION=$$($(RUN) nvim -v | grep -oP 'NVIM \K.+' | cut -d'-' -f1 )
	SUM='The text editor with a focus on extensibility and usability'
	printf "| %-10s | %-13s | %-83s |\n" "$${NAME}" "$${VERSION}" "$${SUM}" | tee -a $@
	
	
