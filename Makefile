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
INFO    := $(RUN) dnf info
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
# TAR_NO_STRIP := tar xz -C

NPM      := $(RUN) npm install --global
LUAROCKS := $(RUN) luarocks install --global
# NPM_LIST := $(RUN) npm list -g --depth=0 --json

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

lsp_confs := $(wildcard site/lsp/*.lua)
lsp_targs := $(patsubst site/lsp/%.lua,info/site/lsp/%.md,$(lsp_confs))

ft_confs  := $(wildcard site/after/filetype/*.lua)
ft_targs := $(patsubst  site/after/ftplugin/*.lua, info/after/ftplugin/%.md,$(ft_confs))

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)
HEADING3 := $(HEADING2)$(HEADING1)

DNF_LIST := neovim google-cloud-cli
NPM_LIST := tree-sitter-cli # copilot copilot-language-server # @mistweaverco/kulala-ls
ROCKS_LIST := busted nlua

default: info/README.md

rem:
	echo '##[ $@ ]##'
	buildah commt $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-coding
	buildah push ghcr.io/grantmacken/tbx-coding:latest
	echo '✅ ghcr.io/grantmacken/tbx-coding:latest built and pushed'

info/README.md: init $(NPM_LIST) #$(ROCKS_LIST) #  DNF_LIST$
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# create or overwrite README.md
	# preamble
	printf "# %s\n\n" "tbx-coding: a toolbox for coding" | tee $@
	printf "A toolbox container image with cli tools, neovim, lsp servers, linters and formaters.\n\n" | tee -a $@
	printf "## %s\n\n" "Installed applications" | tee -a $@

npm_table:
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","----------------------------", $@)
	for pkg in $(NPM_LIST)
	do
	NAME=$$(cat info/$${pkg}.md | grep -oP '^package\s+\K.+')
	VER=$$(cat info/$${pkg}.md | grep -oP '^version\s+\K.+')
	SUM=$$(cat info/$${pkg}.md | grep -oP '^summary\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done

rocks_table: 
	for rock in $(ROCKS_LIST)
	do
	NAME=$$(cat info/$${rock}.md | grep -oP '^package\s+\K.+')
	VER=$$(cat info/$${rock}.md | grep -oP '^version\s+\K.+')
	SUM=$$(cat info/$${rock}.md | grep -oP '^summary\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done

dnf_table:
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","----------------------------", $@)
	for pkg in $(DNF_LIST)
	do
	NAME=$$(cat info/$${pkg}.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(cat info/$${pkg}.md | grep -oP '^Version\s+:\s+\K.+')
	SUM=$$(cat info/$${pkg}.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done
	# Write to file - extract 'name', 'version', 'summary' into a table row
	# If app is available via dnf repo, then extract table row from info/*.md file
	# If app is not installed via dnf, then use info/*.md for name and summary but extract version from installed
	# binary `--version` output
	# Otherwise ... use hacks
	# neovim
	# SUM=$$(cat info/neovim.md | grep -oP '^Name\s+:\s+\K.+')
	# VER=$$($(RUN) nvim -v | grep -oP 'NVIM \K.+' | cut -d'-' -f1 )
	# SUM=$$(cat info/neovim.md | grep -oP '^Summary\s+:\s+\K.+')
	# $(call tr,$${NAME},$${VER},$${SUM},$@)

xxdefault: init nvim mason google-cloud-cli uv_tool luarocks npm
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest
	echo '✅ ghcr.io/grantmacken/tbx-coding:latest built and pushed'
	# neovim
	cat info/neovim.md  | tee -a README.md || true
	# uv_tool
	cat info/uv_tool.md  | tee -a README.md || true
	# mason lsp servers, linters and formaters
	# npm packages
	cat info/npm.md  | tee -a README.md  || true
	# mason lsp servers, linters and formaters
	cat info/luarocks.md  | tee -a README.md  || true
	cat info/uv_tool.md   | tee -a README.md  || true
	# google-cloud-cli
	cat info/google-cloud-cli.md | tee -a README.md	 || true

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
	$(RUN) dnf update -y &>/dev/null

neovim: info/neovim.md
info/neovim.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	TARGET=files/neovim/usr/local
	mkdir -p $${TARGET}
	$(WGET) 'https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz' -O- |
	tar xz --strip-components=1 -C $${TARGET}
	$(ADD) files/neovim &> /dev/null
	$(RUN) ls /usr/local/bin &> /dev/null
	# success|failure check
	VER=$$($(RUN) nvim -v | grep -oP 'NVIM v\K\d+\.\d+\.\d+' )
	echo "Updating neovim version to $$VER in $@"
	$(INFO) neovim | sed "s/^Version.*$$/Version : $${VER}/" >  $@
	echo '✅ neovim installed'

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
	# $(RUN) ls $(DIR_MASON)/bin
	# get version of each binary
	BINS=$$($(RUN) ls $(DIR_MASON)/bin)
	for bin in $$BINS
	do
	echo "$$bin:"
	VER=$(shell $(RUN) $$bin --version 2>/dev/null || $$bin -v 2>/dev/null || echo "unknown")
	# some version strings are long, so just get the first line
	VER=$$(echo "$$VER" | head -n 1)
	# print the version
	echo "$$VER"
	done
	# link installed packages to $(DIR_BIN)
	# use SH here to allow for globbing
	$(SH) 'ln -s $(DIR_MASON)/bin/* $(DIR_BIN)/'
	# check bin dir
	# $(RUN) ls -l /usr/local/bin
	echo '✅ selected mason lsp	 servers, linters and formaters installed'

copilot: info/copilot.md
info/copilot.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	$(NPM) @github/copilot &> /dev/null
	# check it is installed
	$(RUN) $${NAME} --version

tree-sitter-cli: info/tree-sitter-cli.md
info/tree-sitter-cli.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	$(NPM) $${NAME} &> /dev/null
	# # also install lsp server not on mason registry
	# $(NPM) @mistweaverco/kulala-ls || true
	# # install github copilot cli
	# $(NPM) @github/copilot || true
	# check it is installed
	$(RUN) whereis tree-sitter || true
	$(RUN) tree-sitter --version || true
	LINES=$$( $(RUN) npm list -g  --depth=0 --long $${NAME} | grep -oP '.+\K\w+.+')
	echo "$${LINES}"
	# $(RUN) npm view -g $${NAME} | tee $@
	# extract 'name', 'version', 'summary' of exec into to a table row

aasassss:
	# $(RUN) which kulala-ls || true
	# $(RUN) which copilot || true
	# Write to file
	# $(NPM_LIST) | jq -r '.dependencies' || true
	# $(NPM_LIST) | tail -n +2 | while read line
	# do
	# NAME=$$(echo $$line | awk -F@ '{print $$1}' | xargs)
	# VER=$$(echo $$line | awk -F@ '{print $$2}' | xargs)
	# [ -n "$$NAME" ] && printf "| %-10s | %-13s | %-83s |\n" "$$NAME" "$$VER" "Node.js package" | tee -a info/neovim.md;
	# done
	# echo '✅ selected npm packages installed' | tee -a info/$@.md

uv_tool: ## uv tool is a cli to install and manage universal-variant tools
	mkdir -p info
	echo '##[ $@ ]##'
	$(RUN) uv tool install specify-cli --from git+https://github.com/github/spec-kit.git &> /dev/null
	# check it is installed
	$(RUN) which specify || true
	$(RUN) whereis specify || true
	$(RUN) uv tool list | grep specify || true
	# extract 'name', 'version', 'summary' of exec into to a table row
	NAME=specify
	VER=$$($(RUN) uv tool list | grep -oP 'specify.+\K[\d\.]+')
	SUM='A tool to help you specify your software projects'
	printf "| %-10s | %-13s | %-83s |\n" "$$NAME" "$$VER" "$$SUM" | tee info/uv_tool.md
	echo '✅ uv_tool installed'

google-cloud-cli: info/google-cloud-cli.md
info/google-cloud-cli.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	mkdir -p $(dir $@)
	# add the repo
	$(RUN) mkdir -p /etc/yum.repos.d/
	$(ADD) files/google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo &> /dev/null
	$(INSTALL) libxcrypt-compat google-cloud-sdk &> /dev/null
	# verify installation
	$(RUN) which gcloud &> /dev/null
	$(INFO) --installed google-cloud-cli > $@

busted: info/busted.md
info/busted.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	mkdir -p $(dir $@)
	$(LUAROCKS) $${NAME} &> /dev/null
	# verify installation
	$(RUN) which $${NAME} &> /dev/null
	$(RUN) whereis busted
	$(RUN) luarocks show --porcelain $${NAME} > $@

nlua: info/nlua.md
info/nlua.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	NAME=$(basename $(notdir $@))
	mkdir -p $(dir $@)
	$(LUAROCKS) $${NAME} &> /dev/null
	# verify installation
	$(RUN) which $${NAME} &> /dev/null
	$(RUN) luarocks show --porcelain $${NAME} > $@

	# Write to file

## luarocks is a package manager for lua modules
luarocks:## install busted and nlua
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# install busted testing framework
	$(RUN) luarocks install --global busted  &>/dev/null
	# install nlua neovim lua interpreter
	# $(RUN) luarocks install --global nlua &>/dev/null
	# # link installed packages to $(DIR_BIN)
	# $(SH) 'ln -sf /usr/local/lib/luarocks/bin/busted $(DIR_BIN)/busted'
	# $(SH) 'ln -sf /usr/local/lib/luarocks/bin/nlua $(DIR_BIN)/nlua'
	# # verify installation
	# $(RUN) which busted &> /dev/null
	# $(RUN) which nlua &> /dev/null
	# # Write to file
	# $(RUN) luarocks list --porcelain | while read name version summary
	# do
	# [ -n "$$name" ] && printf "| %-10s | %-13s | %-83s |\n" "$$name" "$$version" "$$summary" | tee -a info/luarocks.md
	# done

commit: ## use gopilot to add commit message since last commit
	copilot -p "add commit message since last commit" --allow-all-tools --add-dir $(CURDIR)

view:
	gh repo view --branch tbx-coding

push: ## use gh to watch the  workflow in GitHub Actions
	echo '##[ $@ ]##'
	git push -f origin tbx-coding
	# wait a few seconds for the run to be registered
	sleep 20
	echo -e "$(CYAN)Watch the workflow in GitHub Actions...$(NC)"
	# get the last run id
	# gh run list --branch tbx-coding --limit 1 | awk '{print $$1}'
	RUN_ID=$$(gh run list --branch tbx-coding --limit 1 --json databaseId | jq '.[0].databaseId')
	# check if completed
	STATUS=$$(gh run view $$RUN_ID --json status | jq -r '.status')
	if [ "$$STATUS" = "completed" ]
	then
	# check if success
	CONCLUSION=$$(gh run view $$RUN_ID --json conclusion | jq -r '.conclusion')
	if [ "$$CONCLUSION" = "success" ]
	then
	echo -e "$(GREEN)The last run ($$RUN_ID) is already completed successfully! Exiting.$(NC)"
	exit 0
	else
	echo -e "$(RED)The last run ($$RUN_ID) has completed but did not complete successfully. Status: $$CONCLUSION$(NC)"
	# show the logs
	gh run view $$RUN_ID --log | grep -oP '^.+Stop|^.+error.+$$'
	exit 1
	fi
	fi
	# if not completed, watch it
	gh run watch $$RUN_ID
	# confirm it is completed
	STATUS=$$(gh run view $$RUN_ID --json conclusion | jq -r '.conclusion')
	if [ "$$STATUS" = "success" ]; then
		echo -e "$(GREEN)The run ($$RUN_ID) completed successfully!$(NC)"
	else
		echo -e "$(RED)The run ($$RUN_ID) did not complete successfully. Status: $$STATUS$(NC)"
		exit 1
	fi

pull:
	echo '##[ $@ ]##'
	host-spawn
	podman pull ghcr.io/grantmacken/tbx-coding:latest
	# toolbox list --containers
	# toolbox list --images
	#toolbox create --image ghcr.io/grantmacken/tbx-coding:latest coding
	exit
