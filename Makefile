include inc/meta.mk

WORKING_CONTAINER := fedora-toolbox-working-container
include inc/define.mk

TOOLS := make stow bat fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide ledger sqlite # w3m
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel

# packages installed via dnf - these are listed in the README.md table
DNF_LIST := $(TOOLS) gh golang nodejs uv ShellCheck shfmt
NPM_LIST :=  bash-language-server copilot-language-server vscode-langservers-extracted \
			 yaml-language-server pi-coding-agent tree-sitter-cli
RELEASE_BINARY_LIST := neovim harper-ls # lua-language-server
UV_TOOL_LIST :=  tombi  mbake
PKGS_LIST := $(NPM_LIST) $(RELEASE_BINARY_LIST)
# MD_LIST = google-cloud-cli
# OTP := erlang erlang-rebar3 elixir gleam

default: TBX-README.md
	# printf '✅ %s toolbox built from: %s\n' $@ $(WORKING_CONTAINER)
	# buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx:latest
	# buildah push ghcr.io/grantmacken/tbx-$@:latest
	# printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@

TBX-README.md: init dnf_installs npm_installs binary_installs uv_installs
	echo '##[ $@ ]##'
	$(file >> $@,The following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(DNF_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	for pkg in $(PKGS_LIST)
	do
	NAME=$$(cat info/$${pkg}.md | grep -oP '^Name:\s\K.+' || true)
	VER=$$(cat info/$${pkg}.md | grep -oP '^Version:\s\K.+' || true)
	SUM=$$(cat info/$${pkg}.md | grep -oP '^Summary:\s\K.+' || true)
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done
	
latest/fedora-toolbox.json:
	mkdir -p $(dir $@)
	echo '##[ $@ ]##'
	skopeo inspect docker://registry.fedoraproject.org/fedora-toolbox:latest | jq '.' > $@

init: latest/fedora-toolbox.json
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	buildah from "$${FROM_REGISTRY}:latest"
	buildah config \
	--label summary='a bespoke toolbox' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 \
	--env ELIXIR_ERL_OPTIONS="+fnu" $(WORKING_CONTAINER)
	echo '✅ Base image pulled and working container created'
	mkdir -p info
	$(ADD) files/ $(DIR_BIN)/ &>/dev/null

dnf_installs: tool_lists gh runtime_list coding_list

tool_lists:
	$(RUN) dnf update -y &>/dev/null
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	$(INSTALL) $(TOOLS) &>/dev/null

gh:
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &> /dev/null

runtime_list:
	$(INSTALL) golang nodejs uv &>/dev/null

coding_list:
	$(INSTALL) ShellCheck shfmt &>/dev/null

##########################################################################

npm_installs: $(NPM_LIST)

bash-language-server: info/bash-language-server.md
info/bash-language-server.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(NPM_VIEW) $${PKG} | jq '.')
	# From the veiw extract 'name', 'version', 'description'
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	# install the package globally and use the latest version
	$(NPM_INSTALL) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	$(RUN) $${PKG} --version &> /dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})

pi-coding-agent: info/pi-coding-agent.md
info/pi-coding-agent.md:
	JSON=$$($(NPM_VIEW) @earendil-works/pi-coding-agent | jq '.')
	$(NPM_VIEW) @earendil-works/pi-coding-agent | jq '.name'
	NAME=$(basename $(notdir $@))
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM='minimal agent harness'
	$(NPM_INSTALL) --ignore-scripts @earendil-works/pi-coding-agent
	# success|failure check
	$(RUN) pi --version &> /dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})

copilot-language-server: info/copilot-language-server.md
info/copilot-language-server.md:
	PKG=$(basename $(notdir $@))
	JSON=$$($(NPM_VIEW) @github/copilot-language-server | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM_INSTALL) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# TODO
	$(call to_info,$${PKG},$${VER},$${SUM})

tree-sitter-cli: info/tree-sitter-cli.md
info/tree-sitter-cli.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(NPM_VIEW) $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM_INSTALL) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# Note: the binary is named `tree-sitter` not the package name
	$(RUN) tree-sitter --version &> /dev/null
	$(call to_info,$${NAME},$${VER},$${SUM})

vscode-langservers-extracted: info/vscode-langservers-extracted.md
info/vscode-langservers-extracted.md:
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	JSON=$$($(NPM_VIEW) $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM_INSTALL) $${NAME}@$${VER} &> /dev/null
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
	JSON=$$($(NPM_VIEW) $${PKG} | jq '.')
	NAME=$$(echo $$JSON | jq -r '.name')
	VER=$$(echo $$JSON | jq -r '."dist-tags".latest')
	SUM=$$(echo $$JSON | jq -r '.description')
	$(NPM_INSTALL) $${NAME}@$${VER} &> /dev/null
	# success|failure check
	# TODO
	$(call to_info,$${NAME},$${VER},$${SUM})

####################################################

binary_installs: $(RELEASE_BINARY_LIST)

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

# harper-ls
harper-ls: info/harper-ls.md

latest/harper-ls.json:
	$(WGET) https://api.github.com/repos/Automattic/harper/releases/latest -O- | jq '.' > $@

info/harper-ls.md: latest/harper-ls.json
	PKG=$(basename $(notdir $@))
	SRC=$(shell $(call bduName,"harper-ls-x86_64-unknown-linux-gnu.tar.gz",$<))
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

lua-language-server: info/lua-language-server.md

latest/lua-language-server.json:
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/LuaLS/lua-language-server/releases/latest -O- | jq '.' > $@

info/lua-language-server.md: latest/lua-language-server.json
	mkdir -p $(dir $@)
	# echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	SRC=$(shell $(call bduContains,linux-x64.tar.gz,$<))
	TARGET="files/$${PKG}/usr/local/$${PKG}"
	mkdir -p "$${TARGET}"
	$(WGET) $${SRC} -O- | $(TAR_NO_STRIP) $${TARGET}
	# the exec script in /usr/local/bin/lua-language-server will point to it
	# these scripts are added in init target
	# # success|failure check
	$(RUN) which $${PKG} &> /dev/null
	$(RUN) whereis $${PKG} &> /dev/null
	$(RUN) $${PKG} --version &> /dev/null
	# extract 'name', 'version', 'summary'
	# get version from the binary
	VER=$$($(RUN) lua-language-server --version)
	$(call to_info,$${PKG},$${VER},'Lua language server')

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
#

##########################################################################

uv_installs:  $(UV_TOOL_LIST)

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

