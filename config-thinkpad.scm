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
 (gnu services shepherd)
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
  ;;
  ;; (let*
  ;;     ((channels
  ;;       (list (channel
  ;;              (name 'nonguix)
  ;;              (url "https://gitlab.com/nonguix/nonguix")
  ;;              (branch "master")
  ;;              (commit
  ;;               "94c750ad596f513d5659ce9909022ed09f864537")
  ;;              (introduction
  ;;               (make-channel-introduction
  ;;                "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
  ;;                (openpgp-fingerprint
  ;;                 "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
  ;;             (channel
  ;;              (name 'guix)
  ;;              (url "https://git.guix.gnu.org/guix.git")
  ;;              (branch "master")
  ;;              (commit
  ;;               "5239ec21fda51687671c6667a3bffbcd32bbc9d5")
  ;;              (introduction
  ;;               (make-channel-introduction
  ;;                "9edb3f66fd807b096b48283debdcddccfea34bad"
  ;;                (openpgp-fingerprint
  ;;                 "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))
  ;;      (inferior
  ;;       (inferior-for-channels channels)))
  ;;   (first (lookup-inferior-packages inferior "linux" "6.10.13")))
  ;;
  linux)
 (initrd microcode-initrd)
 ;; includes iwlwifi, intel microcode
 (firmware (list linux-firmware))
 (locale "en_IN.utf8")
 (timezone "Asia/Kolkata")
 (keyboard-layout (keyboard-layout "us" "altgr-intl"))
 (host-name "nabeel")

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
                                        "docker"
                                        )))
               %base-user-accounts))

 ;; Packages installed system-wide.  Users can also install packages
 ;; under their own account: use 'guix search KEYWORD' to search
 ;; for packages and 'guix install PACKAGE' to install a package.
 (packages (append (list curl
                         tailscale

                         ;; docker
                         docker-cli
                         docker-compose
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
                         xremap-x11
                         )
                   %base-packages))

 ;; Below is the list of system services.  To search for available
 ;; services, run 'guix system search KEYWORD' in a terminal.
 (services
  (append (list (service tailscaled-service-type)
                (service gnome-desktop-service-type)

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
                (service docker-service-type)
                ;; Have to manually add containerd service to use in docker.
                ;; https://lists.nongnu.org/archive/html/guix-patches/2024-06/msg00177.html
                (service containerd-service-type)
                (set-xorg-configuration
                 (xorg-configuration (keyboard-layout keyboard-layout)))
                (service screen-locker-service-type
                         (screen-locker-configuration
                          (name "swaylock")
                          (program (file-append swaylock "bin/swaylock"))
                          (using-pam? #t)
                          (using-setuid? #f)))
                (service screen-locker-service-type
                         (screen-locker-configuration
                          (name "i3lock")
                          (program (file-append swaylock "bin/i3lock"))
                          (using-pam? #t)
                          (using-setuid? #f)))
                (service nix-service-type)
                ;; Add a uinput udev rule so that Xremap can run without root
                ;; permissions.
                ;; https://github.com/xremap/xremap?tab=readme-ov-file#running-xremap-without-sudo
                (udev-rules-service 'uinput
                                    (udev-rule
                                     "input.rules"
                                     "KERNEL==\"uinput\", GROUP=\"input\", TAG+=\"uaccess\""))
                (simple-service 'xremap-service
                                shepherd-root-service-type
                                (list (shepherd-service
                                       (provision '(xremap))
                                       (requirement '())
                                       (start #~(make-forkexec-constructor
                                                 (list #$(file-append xremap-x11
                                                                      "/bin/xremap"
                                                                      "--watch=config"
                                                                      "--watch=device"
                                                                      "/etc/xremap.yaml"))))
                                       (stop #~(make-kill-destructor)))))
                )

          ;; This is the default list of services we
          ;; are appending to.
          (modify-services %desktop-services
                           ;; enable wayland for gdm, gnome
                           (gdm-service-type config =>
                                             (gdm-configuration
                                              (inherit config)
                                              (wayland? #f)))
                           (elogind-service-type
                            config =>
                            (elogind-configuration
                             (inherit config)
                             (handle-power-key 'suspend)))
                           ;; enable substitute for nonguix - should help with large package eg: linux, firefox
                           (guix-service-type config => (guix-configuration
                                                         (inherit config)
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
 (swap-devices (list (swap-space
                      (target (uuid
                               "b1411533-b4e5-4f41-8bc4-cce90b425870")))))

 ;; The list of file systems that get "mounted".  The unique
 ;; file system identifiers there ("UUIDs") can be obtained
 ;; by running 'blkid' in a terminal.
 (file-systems (cons* (file-system
                       (mount-point "/boot/efi")
                       (device (uuid "19EA-A6BA"
                                     'fat32))
                       (type "vfat"))
                      (file-system
                       (mount-point "/")
                       (device (uuid
                                "b54d30b2-e4fe-4385-8518-cca7a28746ab"
                                'ext4))
                       (type "ext4")) %base-file-systems)))
