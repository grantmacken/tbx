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
FROM_IMAGE := ghcr.io/grantmacken/tbx-build-tools
NAME := tbx-runtimes
WORKING_CONTAINER ?= $(NAME)-working-container

RUN := buildah run $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
WGET := wget -q --no-check-certificate --timeout=10 --tries=3
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)

WGET := wget -q --no-check-certificate --timeout=10 --tries=3

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

default: runtimes
	echo '##[ $@ ]##'
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest

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

##[[ RUNTIMES ]]##
runtimes: info/runtimes.md
info/runtimes.md: nodejs # otp rebar3 elixir gleam
	mkdir -p $(dir $@)
	printf "\n$(HEADING2) %s\n\n" "Runtimes and associated languages" | tee $@
	# cat << EOF | tee -a $@
	# Included in this toolbox are the latest releases of the Erlang, Elixir and Gleam programming languages.
	# The Erlang programming language is a general-purpose, concurrent, functional programming language
	# and **runtime** system. It is used to build massively scalable soft real-time systems with high availability.
	# The BEAM is the virtual machine at the core of the Erlang Open Telecom Platform (OTP).
	# The included Elixir and Gleam programming languages also run on the BEAM.
	# BEAM tooling included is the latest versions of the Rebar3 and the Mix build tools.
	# The latest nodejs **runtime** is also installed, as Gleam can compile to javascript as well a Erlang.
	# EOF
	# $(call tr,"Name","Version","Summary",$@)
	# $(call tr,"----","-------","----------------------------",$@)
	# cat info/otp.md    | tee -a $@
	# cat info/rebar3.md | tee -a $@
	# cat info/elixir.md | tee -a $@
	# cat info/gleam.md  | tee -a $@
	# cat info/nodejs.md | tee -a $@

##[[ NODEJS ]]##
nodejs: info/nodejs.md
	echo '✅ latest nodejs added'

latest/nodejs.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	wget -q 'https://api.github.com/repos/nodejs/node/releases/latest' -O $@

info/nodejs.md: latest/nodejs.json
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	VER=$$(jq -r '.tag_name' $< )
	mkdir -p files/nodejs/usr/local
	wget -q https://nodejs.org/download/release/$${VER}/node-$${VER}-linux-x64.tar.gz -O- |
	tar xz --strip-components=1 -C files/nodejs/usr/local
	buildah add --chmod 755  $(WORKING_CONTAINER) files/nodejs &>/dev/null
	echo -n 'checking node version...'
	NODE_VER=$$(buildah run $(WORKING_CONTAINER) node --version | tee)
	$(call tr,node,$${NODE_VER},Nodejs runtime, $@)
	echo -n 'checking npm version...'
	NPM_VER=$$(buildah run $(WORKING_CONTAINER) npm --version | tee)
	$(call tr,npm,$${NPM_VER},Node Package Manager, $@)

pull:
	echo '##[ $@ ]##'
	podman pull ghcr.io/grantmacken/tbx-runtimes:latest

