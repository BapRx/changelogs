HELM_CHANGELOG_VERSION=0.1.1
TMPDIR ?= $(CURDIR)/tmp
SHELL=/bin/bash

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: help test update-readme

update-readme: ## Update README.md
	@for repo in $$(grep "path = " .gitmodules | cut -d" " -f3 | sed 's|repositories/||g'); do \
        grep -q $$repo README.md || echo "- [$$repo](https://baprx.github.io/changelogs/$$repo)" >>README.md; \
	done

install-helm-changelog: ## Download and extract the helm-changelog binary
	@mkdir -p $(TMPDIR) && rm -rf $(TMPDIR)/helm-changelog*
	@curl -fLsC - -o $(TMPDIR)/helm-changelog.tar.gz https://github.com/BapRx/helm-changelog/releases/download/v${HELM_CHANGELOG_VERSION}/helm-changelog_${HELM_CHANGELOG_VERSION}_linux_amd64.tar.gz
	@tar zxvf $(TMPDIR)/helm-changelog.tar.gz -C $(TMPDIR) helm-changelog > /dev/null

update-submodules: ## Init and/or update submodules
	@git submodule update --remote --recursive --init

generate-changelogs: ## Generate the changelogs
	@find . -type f -name Changelog.md -delete
	@git submodule foreach $(TMPDIR)/helm-changelog -v info

generate-pages: ## Generate the static website pages
	@cd ./repositories; \
	find . -type f -name Changelog.md -not -empty | while read line; do \
	directory_name=$$(dirname $$line); \
	chart_name=$$(basename $$directory_name); \
	repository=$$(echo $$directory_name | cut -d/ -f 2-3); \
	if [ ! -d "../_changelogs/$${repository//\//_}/" ]; then \
		mkdir -p "../_changelogs/$${repository//\//_}/"; \
		echo -e "---\nhas_children: true\nlayout: default\npermalink: /$${repository}\ntitle: $${repository}\n---\n\n# $${repository}" >"../_changelogs/$${repository//\//_}/index.md"; \
	fi; \
	sed -i '1i---\nlayout: default\nparent: '$${repository}'\npermalink: /'$${repository}'/'$${chart_name}'\nrender_with_liquid: false\ntitle: '$${chart_name}'\n---\n' $$line; \
	sed -i "s/^# Change Log$$/# $${chart_name}/" $$line; \
	mv $$line "../_changelogs/$${repository//\//_}/$${chart_name}.md"; \
	done

serve: ## Serve the static website
	@bundle exec jekyll serve

test: install-helm-changelog update-submodules generate-changelogs generate-pages serve ## Build changelogs for the repositories configured in .gitmodules

all: test
