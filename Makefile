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

default:
	# pushd build-:tools && $(MAKE) && popd
	# sleep 60 # wait for image to settle
	# pushd runtimes && $(MAKE) && popd
	# sleep 60 # wait for image to settle
	pushd coding && $(MAKE) && popd

