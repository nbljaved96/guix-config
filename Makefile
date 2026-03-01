HOSTNAME := $(shell hostname)
GUIX_SYSTEM := $(shell grep '^ID=guix' /etc/os-release)
NIX := $(shell command -v nix >/dev/null 2>&1 && echo nix)

all: sync

sync: guix nix

guix:
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

nix:
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

echo:
	echo $(HOSTNAME) > /dev/null
	echo $(GUIX_SYSTEM) > /dev/null
	echo $(NIX) > /dev/null

distrobox: build-arch-image run-arch-image-w-distrobox

build-arch-image:
	podman build --pull=newer -t localhost/arch ./.config/distrobox

run-arch-image-w-distrobox:
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
