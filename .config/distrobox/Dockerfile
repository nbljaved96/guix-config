from quay.io/toolbx/arch-toolbox

# run useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# user builder
# workdir /home/builder

# Configure Paru
# https://github.com/Morganamilo/paru#examples
# run sudo pacman -S --needed base-devel
# run git clone https://aur.archlinux.org/paru-bin.git && \
#     cd paru-bin && \
#     makepkg -si --noconfirm --needed

# #
run sudo pacman -Syu --noconfirm
# run sudo pacman -S --needed --noconfirm \
#     starship \
#     zoxide \
#     direnv \
#     eza \
#     bat \
#     ripgrep \
#     fzf \
#     lazydocker \
#     lazygit \
#     trash-cli \
#     uv \
#     npm

# npm/bun setup
# install bun - https://bun.com/docs/installation
# run npm config set ignore-scripts true --global
# run npm install -g bun

# # https://github.com/akinomyoga/ble.sh#quick-instructions
# run paru -S --needed --noconfirm \
#     blesh-git
#     # https://github.com/getnf/getnf \
#     # getnf

cmd ["/bin/bash"]
