include ../inc/meta.mk
WORKING_CONTAINER := tbx-runtimes-working-container
include ../inc/define.mk

DNF_LIST     :=  ShellCheck shfmt #  libunwind # google-cloud-cli
UV_TOOL_LIST :=  tombi  mbake # specify-cli
NPM_LIST := bash-language-server \
			copilot \
			copilot-language-server \
			tree-sitter-cli \
			vscode-langservers-extracted \
			yaml-language-server

# removed:
# fauce
# tape

RELEASE_BINARY_LIST :=  neovim  harper-ls
PKGS_LIST := $(RELEASE_BINARY_LIST) $(UV_TOOL_LIST) $(NPM_LIST)
NVIM_CONFIG_LIST := nvim_plugins nvim_treesitters

default: README.md
	echo '##[ $@ ]##'
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-coding
	buildah push ghcr.io/grantmacken/tbx-coding:latest
	echo '✅ ghcr.io/grantmacken/tbx-coding:latest built and pushed'

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
	mkdir -p latest
	# update dnf repos
	$(RUN) dnf update -y &>/dev/null
	echo '✅ Base image pulled and working container created'

README.md: init lua-language-server  # dnf_list pkgs_list nvim_config
	echo '##[ $@ ]##'

xxxxx:
	mkdir -p $(dir $@)
	cat preamble.md > $@
	echo $@
	$(file >> $@,the following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(PKGS_LIST) $(NVIM_CONFIG_LIST)
	do
	NAME=$$(cat info/$${pkg}.md | grep -oP '^Name:\s\K.+')
	VER=$$(cat info/$${pkg}.md | grep -oP '^Version:\s\K.+')
	SUM=$$(cat info/$${pkg}.md | grep -oP '^Summary:\s\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done
	for pkg in $(DNF_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	echo '✅ README.md created'

pkgs_list: $(PKGS_LIST)

dnf_list:
	echo '##[ $@ ]##'
	$(RUN) dnf update -y &>/dev/null
	$(INSTALL) $(DNF_LIST) &>/dev/null
	echo '✅ DNF packages installed'

nvim_config: info/nvim_plugins.md info/nvim_treesitters.md
	echo '##[ $@ ]##'
	$(RUN) mkdir -p /etc/xdg/nvim
	$(ADD) files/sysinit.vim  /etc/xdg/nvim/sysinit.vim &> /dev/null
	$(RUN) ls -la /etc/xdg/nvim/sysinit.vim
	echo '✅ Neovim configuration completed'

info/nvim_plugins.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	$(RUN) nvim_plugins
	$(call to_info,nvim-plugins,1.0.0,'Neovim plugins installed via nvim_plugins script')

info/nvim_treesitters.md:
	# $(RUN) tree -L 3 /usr/local/share/nvim/site/pack
	$(RUN) nvim_treesitters &> /dev/null
	$(call to_info,nvim-treesitters,1.0.0,'Neovim treesitter parsers installed via nvim_treesitters script')
	# $(RUN) tree -L 4 /usr/local/share/nvim/site
	# echo '##[ $(basename $(notdir $@)) ]##'

# release binaries:
# neovim
# lua-language-server
# TODO harper-ls

neovim: info/neovim.md
info/neovim.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	TARGET=files/$${PKG}/usr/local
	mkdir -p $${TARGET}
	SRC='https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz'
	$(WGET) $${SRC} -O- | $(TAR) $${TARGET} &> /dev/null
	$(ADD) files/$${PKG} &> /dev/null
	# success|failure check
	$(RUN) nvim --version &> /dev/null
	$(RUN) whereis nvim &> /dev/null
	$(RUN) which nvim &> /dev/null
	# get version from the binary
	VER=$$($(RUN) nvim -v | grep -oP 'NVIM v\K\d+\.\d+\.\d+' )
	$(call to_info,$${PKG},$${VER},Neovim text editor)

lua-language-server: info/lua-language-server.md

latest/lua-language-server.json:
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/LuaLS/lua-language-server/releases/latest -O- | jq '.' > $@

info/lua-language-server.md: latest/lua-language-server.json
	PKG=$(basename $(notdir $@))
	echo " - installing $${PKG}"
	mkdir -p $(dir $@)
	TARGET=files/$${PKG}
	mkdir -p $${TARGET}
	VER=$$(jq -r '.name' $<)
	echo " - Version: $${VER}"
	SRC=$$(jq -r '.tarball_url' $<)
	echo " - Download Url: $${SRC}"
	$(WGET) $${SRC} -O- | $(TAR) $${TARGET}
	ls -al $${TARGET}
	$(ADD) files/$${PKG} /usr/local/ &> /dev/null
	$(RUN) tree -L 3 /usr/local/$${PKG} || true
	$(RUN) cd /usr/local/$${PKG} && ./make.sh
	# # note the lua-language-server binary is in /usr/local/$${PKG}/bin/ subdir
	$(RUN) ls -al /usr/local/$${PKG}/bin
	# success|failure check
	touch $@

xinfo/lua-language-server.md: xlatest/lua-language-server.json
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	echo " - Binary Name:  $${PKG}"
	SRC=$(shell $(call bdu,linux-x64.tar.gz,$<))
	echo " - Download Url: $${SRC}"
	TARGET=files/$${PKG}/usr/local/$${PKG}
	mkdir -p $${TARGET}
	$(WGET) $${SRC} -O- | $(TAR_NO_STRIP) $${TARGET} &> /dev/null
	$(ADD) files/$${PKG} &> /dev/null
	# note the lua-language-server binary is in /usr/local/$${PKG}/bin/ subdir
	# the exec script in /usr/local/bin/lua-language-server will point to it
	# these scripts are added in init target
	$(RUN) ls -al /usr/local/bin
	# success|failure caheck
	$(RUN) which $${PKG} || true
	$(RUN) whereis $${PKG} || true
	$(RUN) $${PKG} --version || true
	# extract 'name', 'version', 'summary'
	# get version from the binary
	VER=$$($(RUN) lua-language-server --version)
	$(call to_info,$${PKG},$${VER},'Lua language server')
	echo '✅ Lua Language Server installed'

# harper-ls
harper-ls: info/harper-ls.md

latest/harper-ls.json:
	echo ' - fetching latest release info: ##[  $(basename $(notdir $@)) ]##'
	$(WGET) https://api.github.com/repos/Automattic/harper/releases/latest -O- | jq '.' > $@

info/harper-ls.md: latest/harper-ls.json
	# echo ' - installing  latest version: ##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	SRC=$(shell $(call bdu,"harper-ls-x86_64-unknown-linux-gnu",$<))
	# echo " - download url: $${SRC}"
	TARGET="files/$${PKG}/usr/local/bin"
	mkdir -p $${TARGET}
	$(WGET) $${SRC} -O- | $(TAR_NO_STRIP) $${TARGET} &> /dev/null
	$(ADD) files/$${PKG} &> /dev/null
	# success|failure caheck
	$(RUN) which $${PKG} &> /dev/null
	$(RUN) whereis $${PKG} &> /dev/null
	$(RUN) $${PKG} --version &> /dev/null
	# extract 'name', 'version', 'summary'
	# get version from the binary
	VER=$$($(RUN) harper-ls --version | cut -d' ' -f2)
	$(call to_info,$${PKG},$${VER},'Harper Language Server Grammar Checker')

#uv tools:
# tombi
# mbake
# specify-cli

tombi: info/tombi.md
info/tombi.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	$(RUN) uv tool install $${PKG} &> /dev/null
	# success|failure check
	$(RUN) which $${PKG} &> /dev/null
	$(RUN) $${PKG} --version &> /dev/null
	# $(RUN) uv tool list | grep $${PKG}
	$(call uv_tool_info,$${PKG},"TOML Formatter, Linter, and Language Server")

# specify-cli: info/specify-cli.md
# info/specify-cli.md:
# 	# echo '##[ $(basename $(notdir $@)) ]##'
# 	PKG=$(basename $(notdir $@)) 
# 	$(RUN) uv tool install $${PKG} --from git+https://github.com/github/spec-kit.git &> /dev/null
# 	# success|failure check
# 	# Note: the binary is named 'specify' not 'specify-cli'
# 	$(RUN) which specify &> /dev/null
# 	$(RUN) whereis specify &> /dev/null
# 	$(call uv_tool_info,$${PKG},GitHub Spec Tool)

mbake: info/mbake.md
info/mbake.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@)) 
	$(RUN) uv tool install $${PKG} &> /dev/null
	# success|failure check
	$(RUN) which $${PKG} &> /dev/null
	$(RUN) $${PKG} --version &> /dev/null
	# extract 'name', 'version', 'summary'
	$(call uv_tool_info,$${PKG},Makefile formatter and linter)

# npm packages:
# bash-language-server
# copilot
# copilot-language-server
# faucet
# tape
# tree-sitter-cli
# vscode-langservers-extracted
# yaml-language-server

bash-language-server: info/bash-language-server.md
info/bash-language-server.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json $${PKG} | jq '.')
	# From the veiw extract 'name', 'version', 'description'
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	# install the package globally and use the latest version
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) $${PKG} --version &> /dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})

copilot: info/copilot.md
info/copilot.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json @github/copilot | jq '.')
	# extract 'name', 'version', 'description' into to a table row
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global  $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) $${PKG} --version &> /dev/null
	$(call to_info,$${PKG},$${VER},$${SUM})

copilot-language-server: info/copilot-language-server.md
info/copilot-language-server.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json @github/copilot-language-server | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# TODO
	$(call to_info,$${PKG},$${VER},$${SUM})

faucet: info/faucet.md
info/faucet.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# TODO
	$(call to_info,$${NAME},$${VER},$${SUM})

tape: info/tape.md
info/tape.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) tape --version &> /dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})

tree-sitter-cli: info/tree-sitter-cli.md
info/tree-sitter-cli.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# Note: the binary is named `tree-sitter` not the package name
	$(RUN) tree-sitter --version &> /dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})

vscode-langservers-extracted: info/vscode-langservers-extracted.md
info/vscode-langservers-extracted.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	#  "vscode-css-language-server": "bin/vscode-css-language-server",
	#  "vscode-eslint-language-server": "bin/vscode-eslint-language-server",
	#  "vscode-html-language-server": "bin/vscode-html-language-server",
	#  "vscode-json-language-server": "bin/vscode-json-language-server",
	#  "vscode-markdown-language-server": "bin/vscode-markdown-language-server"
	$(call to_info,vscode-langservers,$${VER},$${SUM})

yaml-language-server: info/yaml-language-server.md
info/yaml-language-server.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(RUN) npm view --json $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(RUN) npm install --global $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# TODO
	$(call to_info,$${NAME},$${VER},$${SUM})

# dnf packages:
# google-cloud-cli
# ShellCheck
# shfmt
#
google-cloud-cli: info/google-cloud-cli.md
info/google-cloud-cli.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	# add the repo
	$(RUN) mkdir -p /etc/yum.repos.d
	$(ADD) files/google-cloud-sdk.repo /etc/yum.repos.d/google-cloud-sdk.repo &> /dev/null
	$(INSTALL) libxcrypt-compat $${PKG} &> /dev/null
	# success|failure check
	# Note the binary is named 'gcloud'
	$(RUN) gcloud --version &> /dev/null
	$(RUN) whereis gcloud &> /dev/null
	$(RUN) which gcloud &> /dev/null
	$(call dnf_installed_info,$${PKG})




# ShellCheck: info/ShellCheck.md
# info/ShellCheck.md:
# 	# echo '##[ $(basename $(notdir $@)) ]##'
# 	PKG=$(basename $(notdir $@))
# 	$(INSTALL) $${PKG} &> /dev/null
# 	# success|failure check
# 	# Note the binary is named 'sheckcheck'
# 	$(RUN) which shellcheck &> /dev/null
# 	$(RUN) shellcheck --version &> /dev/null
# 	$(call dnf_installed_info,$${PKG})
#
# shfmt: info/shfmt.md
# info/shfmt.md:
# 	# echo '##[ $(basename $(notdir $@)) ]##'
# 	PKG=$(basename $(notdir $@))
# 	$(INSTALL) $${PKG} &> /dev/null
# 	# verify installation
# 	$(RUN) whereis $${PKG} &> /dev/null
# 	$(RUN) which $${PKG} &> /dev/null
# 	$(RUN) $${PKG} --version &> /dev/null
# 	$(call dnf_installed_info,$${PKG})

# luarocks packages:
# busted
# nlua

# busted: info/busted.md
# info/busted.md:
# 	# echo '##[ $(basename $(notdir $@)) ]##'
# 	PKG=$(basename $(notdir $@))
# 	$(RUN) luarocks install --global $${PKG} &> /dev/null
# 	# verify installation
# 	$(RUN) which $${PKG} &> /dev/null
# 	$(RUN) $${PKG} --version &> /dev/null
# 	LINES=$$($(RUN) luarocks show --porcelain $${PKG})
# 	# extract 'name', 'version', 'summary'
# 	VER=$$(echo "$${LINES}" | grep -oP '^version\s\K.+')
# 	SUM=$$(echo "$${LINES}" | grep -oP '^summary\s\K.+')
# 	$(call to_info,$${PKG},$${VER},$${SUM})
#
# nlua: info/nlua.md
# info/nlua.md:
# 	# echo '##[ $(basename $(notdir $@)) ]##'
# 	PKG=$(basename $(notdir $@))
# 	$(RUN) luarocks install --global $${PKG} &> /dev/null
# 	# verify installation
# 	$(RUN) which $${PKG} &> /dev/null
# 	# $(RUN) $${PKG} --version || true
# 	LINES=$$($(RUN) luarocks show --porcelain $${PKG})
# 	# extract 'name', 'version', 'summary'
# 	VER=$$(echo "$${LINES}" | grep -oP '^version\s\K.+')
# 	SUM=$$(echo "$${LINES}" | grep -oP '^summary\s\K.+')
# 	$(call to_info,$${PKG},$${VER},$${SUM})

