;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules
 (gnu)
 (gnu packages package-management)
 (gnu packages bash)
 (gnu packages admin)
 (gnu packages lisp-xyz)
 (gnu packages rust-apps)
 (gnu packages wm)
 (gnu packages virtualization)
 (gnu packages rsync)
 (gnu services shepherd)
 ;; https://lists.nongnu.org/archive/html/guix-patches/2022-02/msg00365.html
 (gnu system file-systems)
 (gnu system accounts)                  ; for 'subuid-range'
 (nongnu packages linux)
 (nongnu packages firmware)
 (nongnu system linux-initrd)
 (srfi srfi-1)
 (guix inferior)
 (guix channels)
 (nbl packages tailscale)
 (nbl services tailscale))

(use-package-modules
 curl
 docker
 containers
 emacs
 fonts
 lisp
 version-control
 wm)

(use-service-modules
 cups
 databases
 desktop
 docker
 dbus
 containers
 networking
 nix
 ssh
 xorg)

(operating-system
 (kernel
  ;; https://github.com/nonguix/nonguix#pinning-package-versions
  ;;
  ;; When using substitutes is not an option, you may find that guix
  ;; system reconfigure recompiles the kernel frequently due to
  ;; version bumps in the kernel package. An inferior can be used to
  ;; pin the kernel version and avoid lengthy rebuilds.
  ;; (let*
  ;;     ((channels
  ;;       (list (channel
  ;;              (name 'nonguix)
  ;;              (url "https://gitlab.com/nonguix/nonguix")
  ;;              (commit "57c186c44fdec1461af63286cb9442424ca8a0b2")
  ;;              (introduction
  ;;               (make-channel-introduction
  ;;                "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
  ;;                (openpgp-fingerprint
  ;;                 "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
  ;;             (channel
  ;;              (name 'guix)
  ;;              (url "https://git.guix.gnu.org/guix.git")
  ;;              (commit "a88d6a45e422cede96d57d7a953439dc27c6a50c")
  ;;              (introduction
  ;;               (make-channel-introduction
  ;;                "9edb3f66fd807b096b48283debdcddccfea34bad"
  ;;                (openpgp-fingerprint
  ;;                 "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))
  ;;      (inferior
  ;;       (inferior-for-channels channels)))
  ;;   (first (lookup-inferior-packages inferior "linux" "6.14.11")))
  linux
  )
 (initrd microcode-initrd)
 (firmware (list linux-firmware))
 (locale "en_IN.utf8")
 (timezone "Asia/Kolkata")
 (keyboard-layout (keyboard-layout "us" "altgr-intl"))
 (host-name "pc")

 ;; The list of user accounts ('root' is implicit).
 (users (cons* (user-account
                (name "nabeel")
                (comment "Nabeel Javed")
                (group "users")
                (home-directory "/home/nabeel")
                (shell (file-append bash "/bin/bash"))
                (supplementary-groups '("wheel" ;allow use of sudo, etc.
                                        "tty"
                                        "netdev"
                                        "lp" ;Users need to be in the lp group to access the D-Bus service, like bluetooth.
                                        "audio" ;sound card
                                        "video" ;video devices such as webcams
                                        "input"
                                        "cgroup" ;Adding the account to the "cgroup" group makes it possible to run podman commands.
                                        ;; "docker"
                                        )))
               %base-user-accounts))

 ;; Packages installed system-wide.  Users can also install packages
 ;; under their own account: use 'guix search KEYWORD' to search
 ;; for packages and 'guix install PACKAGE' to install a package.
 (packages (append (list curl
                         tailscale

                         ;; docker
                         ;; docker-cli
                         ;; docker-compose
                         ;;
                         ;; podman
                         podman
                         podman-compose
                         ;;
                         incus
                         rsync
                         ;;
                         emacs
                         font-dejavu
                         font-fira-code
                         git
                         ;; nix (for devenv.sh and uv, etc.)
                         nix
                         ;;
                         ;; sway
                         ;; swaylock-effects
                         ;; swaybg
                         ;; swayidle
                         ;; waybar
                         ;; stumpwm
                         sbcl
                         (specification->package "stumpwm-with-slynk")
                         i3lock
                         ;; sbcl-slynk
                         ;; `(,stumpwm "lib")
                         ;; sbcl-stumpwm-ttf-fonts
                         xremap-x11)
                   %base-packages))

 ;; Below is the list of system services.  To search for available
 ;; services, run 'guix system search KEYWORD' in a terminal.
 (services
  (append (list (service tailscaled-service-type)
                (service xfce-desktop-service-type)

                ;; To configure OpenSSH, pass an 'openssh-configuration'
                ;; record as a second argument to 'service' below.
                (service openssh-service-type
                         (openssh-configuration
                          ;; Currently the default is #t but it's considered
                          ;; unsafe.  Explicitly pass #f.
                          (password-authentication? #f)))
                (service bluetooth-service-type
                         (bluetooth-configuration
                          (auto-enable? #t)))
                (service cups-service-type)
                ;; The iptables-service-type is required for Podman to be able
                ;; to setup its own networks.
                ;; (service dbus-root-service-type) ; part of %desktop-services
                ;; (service dhcpcd-service-type)
                (service iptables-service-type)
                (service rootless-podman-service-type
                         (rootless-podman-configuration
                          (subgids
                           (list (subid-range (name "nabeel"))))
                          (subuids
                           (list (subid-range (name "nabeel"))))))
                ;; (service docker-service-type)
                ;; Have to manually add containerd service to use in docker.
                ;; https://lists.nongnu.org/archive/html/guix-patches/2024-06/msg00177.html
                ;; (service containerd-service-type)
                (set-xorg-configuration
                 (xorg-configuration (keyboard-layout keyboard-layout)))
                (service screen-locker-service-type
                         (screen-locker-configuration
                          (name "i3lock")
                          (program (file-append i3lock "bin/i3lock"))
                          (using-pam? #t)
                          (using-setuid? #f)))
                (service nix-service-type))
          ;; This is the default list of services we
          ;; are appending to.
          (modify-services %desktop-services
                           ;; can wayland for gdm, gnome
                           (gdm-service-type config =>
                                             (gdm-configuration
                                              (inherit config)
                                              (wayland? #f)))
                           (elogind-service-type
                            config =>
                            (elogind-configuration
                             (inherit config)
                             (handle-power-key 'suspend)))
                           ;; See https://gitlab.com/nonguix/nonguix Substitutes for nonguix
                           ;; enable substitute for nonguix - should help with large package eg: linux, firefox
                           (guix-service-type config => (guix-configuration
                                                         (inherit config)
                                                         ;; run guix-daemon without root privileges
                                                         (privileged? #f)
                                                         (substitute-urls
                                                          (append
                                                           (list
                                                            "https://substitutes.nonguix.org")
                                                           %default-substitute-urls))
                                                         (authorized-keys
                                                          (append
                                                           (list
                                                            (local-file
                                                             "./signing-key.pub"))
                                                           %default-authorized-guix-keys)))))))
 (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (targets (list "/boot/efi"))
              (keyboard-layout keyboard-layout)))


 ;; The list of file systems that get "mounted".  The unique
 ;; file system identifiers there ("UUIDs") can be obtained
 ;; by running 'blkid' in a terminal.
 (file-systems (cons* (file-system
                       (mount-point "/boot/efi")
                       (device (uuid "9591-0188"
                                     'fat32))
                       (type "vfat"))
                      (file-system
                       (mount-point "/")
                       (device (uuid
                                "41a31ef0-566b-4496-99aa-e4ce821def30"
                                'ext4))
                       (type "ext4")) %base-file-systems))

 ;; https://guix.gnu.org/manual/devel/en/html_node/Swap-Space.html
 (swap-devices (list (swap-space
                      (target (uuid
                               "27b860cf-aa15-4be6-b08f-6592fc8f0dc8")))
                     (swap-space (target "/swapfile")
                                 (dependencies (filter (file-system-mount-point-predicate "/")
                                                       file-systems)))))

 ;; Enables the swap file /swapfile for hibernation by telling the kernel about
 ;; the partition containing it (resume argument) and its offset on that
 ;; partition (resume_offset argument)
 ;;
 ;; See https://guix.gnu.org/manual/devel/en/html_node/Swap-Space.html to
 ;; understand how to get these values
 (kernel-arguments
  (cons* "resume=/dev/nvme0n1p3"        ;device that holds /swapfile
         "resume_offset=122318848"      ;offset of /swapfile on device
         %default-kernel-arguments)))
