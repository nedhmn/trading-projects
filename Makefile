# Set shell to Git Bash
SHELL := C:/Program\ Files/Git/bin/bash.exe
.SHELLFLAGS := -c

CURRENT_DIR := $(PWD)

# Build target
build:
	R --quiet -e "rmarkdown::render('apps/$(filename)/main.Rmd', output_file = 'README.md', knit_root_dir = '$(CURRENT_DIR)')"

# Renv commands
renv-snapshot:
	R --quiet -e "renv::snapshot()"

renv-restore:
	R --quiet -e "renv::restore()"

renv-update:
	R --quiet -e "renv::update()"

renv-status:
	R --quiet -e "renv::status()"

# Help
help:
	@echo "Commands:"
	@echo "  make build filename=<name>  Build README for app"
	@echo "  make renv-snapshot         Save current environment"
	@echo "  make renv-restore          Restore from lockfile"
	@echo "  make renv-update           Update packages"
	@echo "  make renv-status           Check environment status"

.PHONY: build renv-snapshot renv-restore renv-update renv-status help
