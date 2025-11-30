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
	pushd build-tools && $(MAKE) .env && $(MAKE) && popd
	pushd runtimes && $(MAKE) && popd
	rm -f README.md # remove if exists to avoid git add errors
	cat build-tools/README.md > README.md
	cat runtimes/README.md >> README.md
	cat README.md
	# git add README.md
	#git commit -m "Update README.md from Makefile build" README.md || echo "No changes to commit"



# help: ## show available make targets
# 	cat $(MAKEFILE_LIST) |
# 	grep -oP '^[a-zA-Z_-]+:.*?## .*$$' |
# 	sort |
# 	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
#
# workflow: ## use gh to run the  workflow in GitHub Actions
# 	echo -e "$(CYAN)Triggering the default.yml in GitHub Actions...$(NC)"
# 	gh workflow run default.yml
# 	echo -e "$(CYAN)Running the full workflow...$(NC)"
# 	## watch the workflow until it completes
# 	gh run watch
#
# watch: ## use gh to watch the last dispatch workflow in GitHub Actions
# 	# get the last workflow run id
# 	last_run_id=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
# 	echo -e "$(CYAN)Watching the last workflow run with id: $(last_run_id)...$(NC)"
# 	gh run watch $(last_run_id)

