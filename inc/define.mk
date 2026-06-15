
RUN     := buildah run $(WORKING_CONTAINER)
SH      := $(RUN) sh -c

INSTALL := $(RUN) dnf install -y
# INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
INFO    := $(RUN) dnf info
# LINK    := $(RUN) ln -s $(shell which host-spawn)
ADD    := buildah add --chmod 755 $(WORKING_CONTAINER)
RW_ADD := buildah add --chmod  644 $(WORKING_CONTAINER)
WGET   := wget -q --no-check-certificate --timeout=10 --tries=3
# everything is site dir
# DIR_SITE   := /usr/share/nvim/site
DIR_BIN    := /usr/local/bin
TAR          := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)

max_field := $(shell echo -n 'copilot-language-server' | wc -c)
tr = printf "| %-$(max_field)s | %-8s | %-85s |\n" "$(1)" "$(2)" "$(3)" | tee $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

## Helper to write info files in a consistent format
define to_info
	printf "Name: %s\n"    "$(1)" >> $@
	printf "Version: %s\n" "$(2)" >> $@
	printf "Summary: %s\n" "$(3)" >> $@
	printf "✅ %s installed \n" "$(1)"
endef

define dnf_installed_info
LINES=$$($(RUN) dnf info --installed $(1))
# extract 'name', 'version', 'summary'
VER=$$(echo "$${LINES}" | grep -oP '^Version\s+:\s+\K.+' || true)
SUM=$$(echo -e "$${LINES}" | grep -oP '^Summary\s+:\s+\K.+' || true)
$(file >>$(2), printf "| %-$(max_field)s | %-8s | %-85s |\n" "$(1)" "$${VER}" "$${SUM}")
endef

define dnf_to_table_row
	PKGNAME=$$($(RUN) rpm -q --whatprovides --qf '%{NAME}\n' $(1) 2>/dev/null | head -1 || true)
	if [ -n "$${PKGNAME}" ] && LINES=$$($(RUN) dnf info --installed $${PKGNAME} 2>/dev/null); then
	VER=$$(echo "$${LINES}" | grep -oP '^Version\s+:\s+\K(\d+\.){1,2}\d+' || true)
	SUM=$$(echo "$${LINES}" | grep -oP '^Summary\s+:\s+\K.+' | iconv -f UTF-8 -t ASCII//TRANSLIT || true)
	$(call tr,$(1),$${VER},$${SUM},$(2))
	else
	$(call tr,$(1),'Not installed','Not available',$(2))
	fi
endef

define uv_tool_info
# extract 'name', 'version', 'summary'
	LINE=$$($(RUN) uv tool list | grep $(1) )
	# extract 'name', 'version', 'summary'
	NAME=$$(echo $$LINE | cut -d' ' -f1)
	VER=$$(echo $$LINE  | cut -d' ' -f2)
	SUM='$(2)'
	$(call to_info,$${NAME},$${VER},$${SUM})
endef
