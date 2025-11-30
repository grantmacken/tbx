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
INFO    := $(RUN) dnf info
WGET := wget -q --no-check-certificate --timeout=10 --tries=3
TAR  := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
tarball = jq -r '.tarball_url' $1

DNF_LIST := golang nodejs uv # luajit 
OTP := erlang erlang-rebar3 elixir gleam

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)

## Helper to write info files in a consistent format
define to_info
    printf "Name: %s\n"    "$(1)" > $@
	printf "Version: %s\n" "$(2)" >> $@
	printf "Summary: %s\n" "$(3)" >> $@
	printf "✅ %s installed \n" "$(1)"
endef

define dnf_installed_info
  	LINES=$$($(RUN) dnf info --installed $(1))
	# extract 'name', 'version', 'summary'
	VER=$$(echo "$${LINES}" | grep -oP '^Version\s+:\s+\K.+' || true)
	SUM=$$(echo "$${LINES}" | grep -oP '^Summary\s+:\s+\K.+' || true)
	# consistent write to file format
	$(call to_info,$(1),$${VER},$${SUM})
endef


default:  README.md
	echo '##[ $@ ]##'
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-runtimes
	buildah push ghcr.io/grantmacken/tbx-runtimes:latest
	echo '✅ ghcr.io/grantmacken/tbx-runtimes:latest built and pushed'

README.md: init $(DNF_LIST) $(OTP) # luarocks
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# create or overwrite README.md
	printf "\n$(HEADING2) %s\n\n" "Erlang/OTP and run on the Beam languages" | tee $@
	cat << EOF | tee -a $@
	Included in this toolbox are the latest releases of the Erlang, Elixir and Gleam programming languages.
	The Erlang programming language is a general-purpose, concurrent, functional programming language
	and **runtime** system. It is used to build massively scalable soft real-time systems with high availability.
	The BEAM is the virtual machine at the core of the Erlang Open Telecom Platform (OTP).
	The included Elixir and Gleam programming languages also run on the BEAM.
	BEAM tooling included is the latest versions of the Rebar3 and the Mix build tools.
	EOF
	echo "" | tee -a $@
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","----------------------------", $@)
	# ## erlang otp
	NAME=$$(cat info/erlang.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(jq -r '.name' latest/erlang.json | cut -d' ' -f2)
	SUM=$$(cat info/erlang.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# erlang-rebar3
	NAME=rebar3
	VER=$$(jq -r '.tag_name' latest/erlang-rebar3.json | cut -d'v' -f2)
	SUM=$$(cat info/erlang-rebar3.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# elixir
	NAME=$$(cat info/elixir.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(jq -r '.tag_name' latest/elixir.json | cut -d'v' -f2)
	SUM=$$(cat info/elixir.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# gleam
	LINE=$$($(RUN) gleam --version)
	NAME=$$(echo $$LINE | cut -d' ' -f1)
	VER=$$(echo $$LINE | cut -d' ' -f2)
	SUM="Gleam programming language"
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# TODO:  mix
	# $(call tr,Mix,$${VER},Elixir build tool, $@)
	printf "\n$(HEADING2) %s\n\n" "Other runtimes and associated languages" | tee -a $@
	# The latest nodejs **runtime** is also installed, as Gleam can compile to javascript as well a Erlang.
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
	# LINE=$$($(RUN) luarocks | grep -oP '^Lua.+')
	# NAME=$$(cat info/luarocks.md | grep -oP '^Name\s+:\s+\K.+')
	# VER=$$($(RUN) luarocks --version | head -1 | cut -d' ' -f2)
	# SUM=$$(cat info/luarocks.md | grep -oP '^Summary\s+:\s+\K.+')
	# $(call tr,$${NAME},$${VER},$${SUM},$@)


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
	$(INFO) --installed uv > $@

golang: info/golang.md
info/golang.md:
	echo '##[ $@ ]##'
	$(RUN) dnf copr enable -y @go-sig/golang-rawhide &>/dev/null
	$(INSTALL) golang &>/dev/null
	# verify installation
	$(RUN) go version &> /dev/null
	$(INFO) --installed golang > $@

##[[ NODEJS ]]##

nodejs: info/nodejs.md
info/nodejs.md:
	echo '##[ $@ ]##'
	$(INSTALL) nodejs &>/dev/null
	# success|failure check
	$(RUN) node --version &>/dev/null
	$(INFO) --installed nodejs > $@

luajit: info/luajit.md
info/luajit.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) luajit-devel luajit &>/dev/null
	# success|failure check
	$(RUN) luajit -v &>/dev/null
	$(INFO) --installed luajit > $@

##[[ LUAROCKS ]]##
luarocks: info/luarocks.md
latest/luarocks.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/luarocks/luarocks/tags -o- | jq '.[0]' > $@

info/luarocks.md: latest/luarocks.json
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
	$(INFO) luarocks > $@

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

latest/erlang.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/otp/releases/latest -O $@

erlang: info/erlang.md
info/erlang.md: latest/erlang.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	mkdir -p files/otp
	$(RUN) mkdir -p /tmp/otp
	VER=$$(jq -r '.name' $< | cut -d' ' -f2)
	echo "Erlang/OTP Version: $${VER}"
	SRC="https://github.com/erlang/otp/releases/download/OTP-$${VER}/otp_src_$${VER}.tar.gz"
	echo "Source URL: $${SRC}"
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
	# success|failure check
	$(RUN) erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell &>/dev/null
	$(INFO) erlang > $@
	$(RUN) rm -fR /tmp/otp

##[[ ELIXIR ]]##
elixir: info/elixir.md

latest/elixir.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/elixir-lang/elixir/releases/latest -O $@

info/elixir.md: latest/elixir.json
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
	$(INFO) elixir > $@


##[[ rebar3 ]]##
erlang-rebar3: info/erlang-rebar3.md

latest/erlang-rebar3.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/rebar3/releases/latest -O $@

info/erlang-rebar3.md: latest/erlang-rebar3.json
	echo '##[ $(basename $(notdir $@)) ]##'
	SRC=$(shell $(call bdu,rebar3,$<))
	$(ADD) $${SRC} /usr/local/bin/rebar3 &>/dev/null
	# success|failure check
	$(RUN) rebar3 --version &>/dev/null
	$(INFO) erlang-rebar3 > $@

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

