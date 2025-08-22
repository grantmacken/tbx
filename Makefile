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
TBX_IMAGE := ghcr.io/grantmacken/tbx-cli-tools
WORKING_CONTAINER ?= tbx-cli-tools-working-container

RUN := buildah run $(WORKING_CONTAINER)

CLI := eza fd-find fzf gh wl-clipboard zoxide

WGET := wget -q --no-check-certificate --timeout=10 --tries=3

WORKING_CONTAINER ?= tbx-build-tools-working-container

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
	
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
	
	
info/cli-tools.md:
	mkdir -p $(dir $@)
	RUN $(WORKING_CONTAINER) dnf upgrade -y --minimal &>/dev/null
	for item in $(CLI)
	do
	$(RUN) $(WORKING_CONTAINER) dnf install \
		--allowerasing \
		--skip-unavailable \
		--skip-broken \
		--no-allow-downgrade \
		-y \
		$${item} &>/dev/null
	done
	printf "\n$(HEADING2) %s\n\n" "Handpicked CLI tools available in the toolbox" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	buildah run $(WORKING_CONTAINER) sh -c  'dnf info -q installed $(CLI) | \
	   grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	   paste  - - -  | sort -u ' | \
	   awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | tee -a $@
	

