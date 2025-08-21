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
WORKING_CONTAINER ?= fedora-toolbox-working-container
FED_IMAGE := registry.fedoraproject.org/fedora-toolbox
TBX_IMAGE := ghcr.io/grantmacken/tbx-build-tools

RUN := buildah run $(WORKING_CONTAINER)
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)

WGET := wget -q --no-check-certificate --timeout=10 --tries=3

BUILDING := make gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := gettext-devel \
 glibc-devel \
 libevent-devel \
 ncurses-devel \
 openssl-devel \
 perl-devel \
 readline-devel \
 zlib-devel

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

default: host-spawn build-tools
	echo '##[ $@ ]##'
	$(RUN) which wget
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest
	
init: .env
	echo '##[ $@ ]##'

.env: latest/fedora-toolbox.json
	echo '##[ $@ ]##'
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	FROM_VERSION=$$(cat $< | jq -r '.Labels.version')
	FROM_NAME=$$(cat $< | jq -r '.Labels.name')
	printf "FROM_NAME=%s\n" "$$FROM_NAME" | tee $@
	printf "FROM_REGISTRY=%s\n" "$$FROM_REGISTRY" | tee -a $@
	printf "FROM_VERSION=%s\n" "$$FROM_VERSION" | tee -a $@
	buildah pull "$$FROM_REGISTRY:$$FROM_VERSION" &> /dev/null
	echo -n "WORKING_CONTAINER=" | tee -a .env
	buildah from "$${FROM_REGISTRY}:$${FROM_VERSION}" | tee -a .env
	
latest/fedora-toolbox.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://${FED_IMAGE}:latest | jq '.' > $@
	
## HOST-SPAWN
host-spawn: info/host-spawn.md
latest/host-spawn.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	wget -q https://api.github.com/repos/1player/host-spawn/releases/latest -O $@

info/host-spawn.md: latest/host-spawn.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	SRC=$$(jq -r ".assets[] | select(.browser_download_url | contains(\"x86_64\")) | .browser_download_url" $<)
	echo $${SRC}
	$(ADD) $${SRC} /usr/local/bin/host-spawn &>/dev/null
	echo -n 'checking host-spawn version...'
	VER=$$($(RUN) host-spawn --version | tee )
	printf "\n$(HEADING2) %s\n\n" "Do More With host-spawn" | tee -a $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	$(call tr,host-spawn,$${VER},Run commands on your host machine from inside toolbox,$@)
	echo >> $@
	cat << EOF | tee -a $@
	The host-spawn tool is a wrapper around the toolbox command that allows you to run
	commands on your host machine from inside the toolbox.
	To use the host-spawn tool, either run the following command: host-spawn <command>
	Or just call host-spawn with no argument and this will pop you into you host shell.
	When doing this remember to pop back into the toolbox with exit.
	EOF
	printf "Checkout the %s for more information.\n\n" "[host-spawn repo](https://github.com/1player/host-spawn)" | tee -a $@

build-tools: info/build-tools.md

info/build-tools.md:
	echo '##[ $@ ]##'
	$(RUN) dnf update -y 
	for item in $(DEPS)
	do
	$(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y $${item} &>/dev/null
	done
	printf "\n$(HEADING2) %s\n\n" "Selected Build Tooling for Make Installs" | tee $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	$(RUN) sh -c  'dnf info -q installed $(BUILDING) | \
	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	paste  - - -  | sort -u ' | \
	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
	tee -a $@
	
	
files/nvim.tar.gz:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz" -O $@
	
	
	
##[[ NEOVIM ]]#
neovim: info/neovim.md
info/neovim.md: files/nvim.tar.gz
	echo '##[ $@ ]##'
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
	
	
