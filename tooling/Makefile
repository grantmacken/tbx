include ../inc/meta.mk
WORKING_CONTAINER := fedora-toolbox-working-container
include ../inc/define.mk
TOOLS := make stow bat fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide ledger w3m
# atuin
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
PKGS_LIST := gh google-cloud-cli $(TOOLS)

README.md: build-tools
	echo '##[ $@ ]##'
	cat preamble.md > $@
	$(file >> $@,The following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(PKGS_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	echo '✅ README.md created'

latest/fedora-toolbox.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://registry.fedoraproject.org/fedora-toolbox:latest | jq '.' > $@

init: latest/fedora-toolbox.json
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	buildah from "$${FROM_REGISTRY}:latest"
	buildah config \
	--label summary='a bespoke toolbox' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	echo '✅ Base image pulled and working container created'

build-tools: init lists gh google-cloud-cli
	# verify that the container is working and has the expected tools
	$(RUN) which ledger &>/dev/null
	printf '✅ %s toolbox built from: %s\n'  $@ $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-$@:latest
	buildah push ghcr.io/grantmacken/tbx-$@:latest
	printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@

lists:
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	$(INSTALL) $(TOOLS) &>/dev/null

gh:
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &>  /dev/null

google-cloud-cli: files/google-cloud-cli.tar.gz
	mkdir -p files/google-cloud-cli
	$(TAR) google-cloud-cli -f $<
	$(ADD) files/google-cloud-cli /usr/local/share/google-cloud-cli
	$(RUN) /usr/local/share/google-cloud-cli/install.sh --quiet
	# success|failure check
	$(RUN) gcloud --version &> /dev/null
	$(RUN) whereis gcloud &> /dev/null
	$(RUN) which gcloud &> /dev/null


	$(TAR) files/google-cloud-cli.tar.gz /files/google-cloud-cli
	ls -l /files/google-cloud-cli
	false
	# $(ADD) files/google-cloud-cli /usr/local/share/google-cloud-cli
	# $(RUN) /usr/local/google-cloud-cli/install.sh --quiet
	# # success|failure check
	# # Note the binary is named 'gcloud'
	# $(RUN) gcloud --version &> /dev/null
	# $(RUN) whereis gcloud &> /dev/null
	# $(RUN) which gcloud &> /dev/null

files/google-cloud-cli.tar.gz:
	mkdir -p $(dir $@)
	SRC="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"
	echo "Source URL: $${SRC}"
	# wget the file and save it to the specified location. use progress bar and retry on failure. suppress output except for errors.
	$(WGET) $${SRC} -O $@
