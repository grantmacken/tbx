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

## hardcoded working container
WORKING_CONTAINER := tbx-build-tools-working-container
RUN := buildah run $(WORKING_CONTAINER)
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
INFO    := $(RUN) dnf info --installed
WGET := wget -q --no-check-certificate --timeout=10 --tries=3
TAR  := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
tarball = jq -r '.tarball_url' $1

DNF_LIST := golang luajit nodejs uv
OTP := otp rebar3 elixir gleam
LUA := luajit luarocks

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)

default:  info/README.md # python golang nodejs $(LUA) $(OTP) python

rem:
	echo '##[ $@ ]##'
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-runtimes
	buildah push ghcr.io/grantmacken/tbx-runtimes:latest
	echo '✅ ghcr.io/grantmacken/tbx-runtimes:latest built and pushed'

info/README.md: init $(DNF_LIST) luarocks  $(OTP)
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# create or overwrite README.md
	printf "\n$(HEADING2) %s\n\n" "Runtimes and associated languages" | tee $@
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","----------------------------", $@)
	# Write to file - extract 'name', 'version', 'summary' into a table row
	# for each installed package in the DNF_LIST variable
	# usea cat info/{package}.md files to fill in the README.md
	for pkg in $(DNF_LIST)
	do
	NAME=$$(cat info/$${pkg}.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(cat info/$${pkg}.md | grep -oP '^Version\s+:\s+\K.+')
	SUM=$$(cat info/$${pkg}.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done
	# luarocks
	LINE=$$($(RUN) luarocks | grep -oP '^Lua.+')
	NAME=$$(echo $$LINE | grep -oP '^Lua\w+')
	VER=$$(echo $$LINE | grep -oP '^Lua\w+\s\K.+' | cut -d, -f1)
	SUM=$$(echo $$LINE | grep -oP '^Lua\w+\s\K.+' | cut -d, -f2)
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# ## erlang otp
	# NAME=$$($(RUN) dnf info erlang | grep -oP '^Name\s+:\s+\K.+')
	# SUM=$$($(RUN)  dnf info erlang | grep -oP '^Summary\s+:\s+\K.+')
	# $(RUN) erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell
	# VER=$$(jq -r '.tag_name' latest/otp.json | cut -d'-' -f2)
	# $(call tr,$${NAME},$${VER},$${SUM},$@)
	# # rebar3
	# LINE=$$($(RUN) rebar3 --version | grep -oP '^rebar3.+')
	# NAME=$$(echo $$LINE | cut -d' ' -f1)
	# VER=$$(echo $$LINE | cut -d' ' -f2)
	# SUM="Erlang build tool"
	# $(call tr,$${NAME},$${VER},$${SUM},$@)
	# # elixir
	# LINE=$$( $(RUN) elixir --version | grep -oP '^Elixir.+')
	# NAME=$$(echo "$${LINE}" | cut -d' ' -f1)
	# VER=$$(echo "$${LINE}" | cut -d' ' -f2)
	# SUM=$$($(RUN) dnf info elixir | grep -oP '^Summary\s+:\s+\K.+')
	# $(call tr,$${NAME},$${VER},$${SUM},$@)
	# # gleam
	# LINE=$$($(RUN) gleam --version)
	# NAME=$$(echo $$LINE | cut -d' ' -f1)
	# VER=$$(echo $$LINE | cut -d' ' -f2)
	# SUM="Gleam programming language"
	# $(call tr,$${NAME},$${VER},$${SUM},$@)
	# $(call tr,Elixir,$${VER},Elixir programming language, $@)
	# VER=$$(buildah run $(WORKING_CONTAINER) mix --version | grep -oP 'Mix \K.+' | cut -d' ' -f1)
	# $(call tr,Mix,$${VER},Elixir build tool, $@)

xxxxx:
	cat << EOF | tee -a $@
	Included in this toolbox are the latest releases of the Erlang, Elixir and Gleam programming languages.
	The Erlang programming language is a general-purpose, concurrent, functional programming language
	and **runtime** system. It is used to build massively scalable soft real-time systems with high availability.
	The BEAM is the virtual machine at the core of the Erlang Open Telecom Platform (OTP).
	The included Elixir and Gleam programming languages also run on the BEAM.
	BEAM tooling included is the latest versions of the Rebar3 and the Mix build tools.
	The latest nodejs **runtime** is also installed, as Gleam can compile to javascript as well a Erlang.
	EOF

init:
	buildah pull ghcr.io/grantmacken/tbx-build-tools &>/dev/null
	buildah from ghcr.io/grantmacken/tbx-build-tools
	buildah config \
	--label summary='a toolbox with programming language runtimes' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 \
	--env ELIXIR_ERL_OPTIONS="+fnu" $(WORKING_CONTAINER)
	mkdir -p info
	$(RUN) dnf update -y &>/dev/null

uv: info/uv.md
info/uv.md:
	echo '##[ $@ ]##'
	$(INSTALL) uv &>/dev/null
	# verify installation
	$(RUN) which uv &> /dev/null
	$(INFO) uv > $@

golang: info/golang.md
info/golang.md:
	echo '##[ $@ ]##'
	$(RUN) dnf copr enable -y @go-sig/golang-rawhide &>/dev/null
	$(INSTALL) golang &>/dev/null
	# verify installation
	$(RUN) go version &> /dev/null
	$(INFO) golang > $@

##[[ NODEJS ]]##

nodejs: info/nodejs.md
info/nodejs.md:
	echo '##[ $@ ]##'
	$(INSTALL) nodejs &>/dev/null
	# success|failure check
	$(RUN) node --version &>/dev/null
	$(INFO) nodejs > $@

luajit: info/luajit.md
info/luajit.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) luajit-devel luajit &>/dev/null
	# success|failure check
	$(RUN) luajit -v &>/dev/null
	$(INFO) luajit > $@

latest/luarocks.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/luarocks/luarocks/tags -O- | jq '.[0]' > $@

luarocks: latest/luarocks.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	mkdir -p files/luarocks
	SRC=$$(jq -r '.tarball_url' $<)
	$(RUN) mkdir -p 	/tmp/luarocks /etc/xdg/luarocks
	$(WGET) $${SRC} -O- | tar xz --strip-components=1 -C files/luarocks &>/dev/null
	$(ADD) files/luarocks /tmp/luarocks &>/dev/null
	$(RUN) sh -c 'cd /tmp/luarocks && ./configure \
		--lua-version=5.1 \
		--with-lua-interpreter=luajit \
		--sysconfdir=/etc/xdg \
		--force-config \
		--with-lua-include=/usr/include/luajit-2.1' &>/dev/null
	# $(RUN) sh -c 'cd /tmp && make bootstrap' &>/dev/null
	$(RUN) sh -c 'cd /tmp/luarocks && make && make install' &>/dev/null
	$(RUN) rm -fR tmp/luarocks
	# success|failure check
	$(RUN) luarocks --version &>/dev/null

# rust:
# 	echo '##[ $@ ]##'
# 	curl https://sh.rustup.rs -sSf | sh -s -- -y
# 	export PATH="$HOME/.cargo/bin:$PATH"
# 	$(RUN) dnf copr enable @rust-sig/rust-nightly
# 	$(INSTALL) rust
# 	$(RUN) mkdir -p /usr/local/cargo
# 	$(RUN) cargo install cargo-binstall --root /usr/local/cargo
# 	$(RUN) ls /usr/local/cargo/bin/
# 	$(RUN) ln -sf /usr/local/cargo/bin/cargo-binstall /usr/local/bin/cargo-binstall
# 	$(RUN) cargo-binstall --help
	# $(RUN) cargo-binstall --no-confirm --no-symlinks --root /usr/local/cargo lux-cli
	# $(RUN) ls /usr/local/cargo/bin/
	# $(RUN) ln -sf /usr/local/cargo/bin/* /usr/local/bin/
	# $(RUN) lx --help

latest/otp.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/otp/releases/latest -O $@

otp: info/otp.md
info/otp.md: latest/otp.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p /tmp/otp
	VER=$$(jq -r '.name' $< | cut -d' ' -f2)
	echo "Erlang/OTP Version: $${VER}"
	SRC="https://github.com/erlang/otp/releases/download/OTP-$${VER}/otp_src_$${VER}.tar.gz"
	$(WGET) $${SRC} -O- | $(TAR) files/otp &>/dev/null
	$(ADD) files/otp /tmp/otp &>/dev/null
	$(RUN) sh -c 'cd /tmp/otp && ./configure \
		--prefix=/usr/local \
		--enable-threads \
		--enable-shared-zlib \
		--enable-ssl=dynamic-ssl-lib \
		--enable-jit \
		--enable-kernel-poll \
		--without-debugger \
		--without-observer \
		--without-wx \
		--without-et \
		--without-megaco \
		--without-cosEvent \
		--without-odbc' &>/dev/null
	$(RUN) sh -c 'cd /tmp/otp && make && make install' &>/dev/null
	$(RUN) rm -fR /tmp/otp

latest/elixir.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/elixir-lang/elixir/releases/latest -O $@

elixir: latest/elixir.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	TAGNAME=$$(jq -r '.tag_name' $<)
	SRC=https://github.com/elixir-lang/elixir/archive/$${TAGNAME}.tar.gz
	mkdir -p files/elixir && $(WGET) $${SRC} -O- | $(TAR) files/elixir &>/dev/null
	$(RUN) mkdir -p /tmp/elixir
	$(ADD) files/elixir /tmp/elixir &>/dev/null
	$(RUN) sh -c 'cd /tmp/elixir && make && make install' &>/dev/null
	$(RUN) rm -fR /tmp/elixir
	# success|failure check
	$(RUN) elixir --version
	$(RUN) mix --version


##[[ rebar3 ]]##
rebar3: info/rebar3.md

latest/rebar3.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/rebar3/releases/latest -O $@

info/rebar3.md: latest/rebar3.json
	# echo '##[ $@ ]##'
	SRC=$(shell $(call bdu,rebar3,$<))
	$(ADD) $${SRC} /usr/local/bin/rebar3 &>/dev/null
	# success|failure check
	$(RUN) rebar3 --version &>/dev/null

##[[ GLEAM ]]##
gleam: info/gleam.md

latest/gleam.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/gleam-lang/gleam/releases/latest -O- |
	jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-musl.tar.gz"))' > $@

files/gleam.tar: latest/gleam.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(RUN) rm -f /usr/local/bin/gleam
	SRC=$$(jq -r '.browser_download_url' $<)
	$(WGET) $${SRC} -O- | gzip -d > $@

info/gleam.md: files/gleam.tar
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(ADD) $< /usr/local/bin/  &>/dev/null
	## success|failure check
	$(RUN) gleam --version &>/dev/null
	## extract version number


pull:
	podman pull ghcr.io/grantmacken/tbx-runtimes:latest

