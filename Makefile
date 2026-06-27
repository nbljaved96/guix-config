# Source-of-truth direction:
#   * `make sync`  captures the live system INTO the repo
#                  (/etc/config.scm + profiles  ->  this repo).
#   * `make apply-*` pushes the repo OUT to the live system
#                  (this repo  ->  /etc/config.scm + reconfigure).
# Treat the repo as canonical: edit here, then `apply`. Use `sync`
# only to import ad-hoc changes you made directly on the machine.
#
# Target families:
#   sync-*       live system  ->  repo (capture)
#   apply-*      repo  ->  live system (install/reconfigure)
#   check-*      validate without touching the live system
#   distrobox-*  container image / sandbox management
#
# Run `make help` to list every target with its description. To document
# a target in that listing, add a `## <description>` comment on its rule
# line (the text after `##` is what `help` prints).

HOSTNAME := $(shell hostname)
GUIX_SYSTEM := $(shell grep '^ID=guix' /etc/os-release)
NIX := $(shell command -v nix >/dev/null 2>&1 && echo nix)

# Host config file for the current machine (empty on unknown hosts).
ifeq ($(HOSTNAME), thinkpad)
HOST_CONFIG := config-thinkpad.scm
endif
ifeq ($(HOSTNAME), pc)
HOST_CONFIG := config-pc.scm
endif

.PHONY: help all sync sync-guix sync-nix \
        check-guix-system \
        apply-guix-system apply-guix-profile apply-nix-profile \
        distrobox distrobox-build distrobox-recreate

help: ## Show this help (list of targets and what they do)
	@echo "Usage: make <target>    (default target: sync)"
	@echo
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

all: sync ## Alias for `sync` (the default target)

sync: sync-guix sync-nix ## Capture live system state into the repo (guix + nix)

sync-guix: ## Capture /etc/config.scm, channels symlink, and current Guix profile manifest
ifeq ($(HOSTNAME), thinkpad)
	cat /etc/config.scm > config-thinkpad.scm
else
	# not thinkpad
endif
ifeq ($(HOSTNAME), pc)
	cat /etc/config.scm > config-pc.scm
else
	# not pc
endif
	@echo ""
# cat /etc/xremap.yaml > xremap.yaml
	# Guix: Configure channels
	ln -sf ~/guix-config/channels.scm ~/.config/guix/channels.scm
	# Guix: Get current profile
	# The following command doesn't work:
	# guile ./scripts/sort-manifest.scm  current-profile-manifest > current-profile-manifest
	#
	# Can't read from same file as bash due to the 'redirection'
	# truncates the output file to zero length, therefore we need
	# to use 'sponge' from moreutils that sponges up all the output
	# from the pipe before opening the output file for writing
	#
	# guile ./scripts/sort-manifest.scm  current-profile-manifest | sponge current-profile-manifest
	guile ./scripts/sort-manifest.scm > current-profile-manifest
	@echo ""

sync-nix: ## Capture Nix channels symlink and current Nix profile manifest (if nix is installed)
ifdef NIX
	# Nix: Configure channels
	ln -sf ~/guix-config/nix-config/nix-channels ~/.nix-channels
	# Nix: Get current profile
	cat ~/.nix-profile/manifest.nix > ./nix-config/manifest.nix
	bash ./scripts/extract-nix-packages.sh
else
	# Not a Guix system, therefore no nix-service-type
endif
	@echo ""

apply-guix-system: ## Copy this host's config to /etc/config.scm and (prompt to) reconfigure
ifeq ($(HOSTNAME), thinkpad)
	sudo cp config-thinkpad.scm /etc/config.scm
	@printf "Reconfigure system? [y/N] " && read ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		sudo guix system reconfigure /etc/config.scm -L modules; \
	fi
else ifeq ($(HOSTNAME), pc)
	sudo cp config-pc.scm /etc/config.scm
	@printf "Reconfigure system? [y/N] " && read ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		sudo guix system reconfigure /etc/config.scm -L modules; \
	fi
else
	@echo "Unsupported host: $(HOSTNAME)"
endif

check-guix-system: ## Dry-build this host's system config to catch breakage (does NOT activate)
ifeq ($(HOST_CONFIG),)
	@echo "Unsupported host: $(HOSTNAME) (no config-$(HOSTNAME).scm)" && exit 1
else
	# Dry build of this host's system config (evaluates + builds the
	# derivation but does NOT activate it) to catch breakage early.
	guix system build $(HOST_CONFIG) -L modules
endif

apply-guix-profile: ## Install the captured Guix profile from current-profile-manifest
	guix package -m current-profile-manifest -L modules

apply-nix-profile: ## Install the captured Nix profile from nix-config/attribute-manifest.nix
	nix-env --install --remove-all --file ./nix-config/attribute-manifest.nix

distrobox: distrobox-build distrobox-recreate ## Build the Arch image and (re)create the distrobox container

distrobox-build: ## Build the local Arch container image from .config/distrobox
	podman build --pull=newer -t localhost/arch ./.config/distrobox

distrobox-recreate: ## Recreate and enter the 'arch' distrobox container
	# delete 'arch' image
	distrobox rm arch
	# rebuild 'arch' image
	distrobox create \
          --volume /gnu:/gnu/ \
          --volume /var/guix:/var/guix \
          --volume /run/current-system:/run/current-system \
          --volume /nix:/nix \
          --image localhost/arch \
          --name arch
	# run the container
	distrobox enter arch -- ls
