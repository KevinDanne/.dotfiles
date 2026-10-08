#!/usr/bin/env bash
# Bootstrap: installs all tools and stows the dotfiles (Ubuntu / Kubuntu).
# Idempotent – safe to run multiple times.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
FONT_DIR="$HOME/.local/share/fonts/HackNerdFont"

PROTONVPN_DEB="protonvpn-stable-release_1.0.8_all.deb"
PROTONVPN_SHA256="0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180"

APT_PACKAGES=(
  # package managers
  flatpak snapd
  # dotfiles & shell
  git stow zsh
  # used by this script (downloads, fonts, signatures)
  curl unzip fontconfig minisign
  # terminal
  ghostty
  # cli tools
  yazi lazygit ffmpeg jq ripgrep fzf zoxide glow
  # dev
  codium podman
  # desktop
  copyq proton-vpn-gnome-desktop kde-config-flatpak
)

# name:flags
SNAP_PACKAGES=(
  helix:--classic
  proton-mail:
)

FLATPAK_APPS=(
  app.zen_browser.zen
  org.mozilla.thunderbird
  org.libreoffice.LibreOffice
  com.discordapp.Discord
  com.spotify.Client
  com.usebruno.Bruno
  io.podman_desktop.PodmanDesktop
  org.waywallen.waywallen
  org.videolan.VLC
)

WAYWALLEN_DATA="$HOME/.var/app/org.waywallen.waywallen/data/waywallen"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip() { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }

add_apt_repos() {
  if [ ! -f /etc/apt/sources.list.d/yazi.list ]; then
    info "Adding Yazi apt repository"
    curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null
    echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
  else
    skip "Yazi apt repository already configured"
  fi

  if [ ! -f /etc/apt/sources.list.d/protonvpn-stable.sources ]; then
    info "Adding Proton VPN apt repository"
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/$PROTONVPN_DEB" "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/$PROTONVPN_DEB"
    echo "$PROTONVPN_SHA256  $tmp/$PROTONVPN_DEB" | sha256sum --check -
    sudo dpkg -i "$tmp/$PROTONVPN_DEB"
    rm -rf "$tmp"
  else
    skip "Proton VPN apt repository already configured"
  fi

  if [ ! -f /etc/apt/sources.list.d/vscodium.sources ]; then
    info "Adding VSCodium apt repository"
    curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
      | gpg --dearmor \
      | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg status=none
    printf 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg\n' \
      | sudo tee /etc/apt/sources.list.d/vscodium.sources >/dev/null
  else
    skip "VSCodium apt repository already configured"
  fi

  if [ ! -f /etc/apt/sources.list.d/charm.list ]; then
    info "Adding Charm apt repository"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
  else
    skip "Charm apt repository already configured"
  fi
}

install_apt_packages() {
  info "Installing apt packages"
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
}

# Downloads the latest release asset of a GitHub repo matching a regex
download_github_asset() {
  local repo="$1" pattern="$2" out="$3" url
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | jq -r --arg p "$pattern" '.assets[] | select(.name | test($p)) | .browser_download_url' | head -n1)"
  [ -n "$url" ] || { echo "No asset matching '$pattern' in $repo" >&2; return 1; }
  curl -fsSL -o "$out" "$url"
}

# Installs a .deb from the latest GitHub release unless the package is already installed
install_github_deb() {
  local package="$1" repo="$2" pattern="$3" tmp
  if dpkg -s "$package" >/dev/null 2>&1; then
    skip "$package already installed"
    return
  fi
  info "Installing $package"
  tmp="$(mktemp -d)"
  download_github_asset "$repo" "$pattern" "$tmp/$package.deb"
  sudo apt-get install -y "$tmp/$package.deb"
  rm -rf "$tmp"
}

install_github_debs() {
  local gcm_arch
  gcm_arch="$(dpkg --print-architecture)"
  [ "$gcm_arch" = amd64 ] && gcm_arch=x64

  # Credential helper config lives in .gitconfig
  install_github_deb gcm git-ecosystem/git-credential-manager "^gcm-linux-${gcm_arch}-.*\\.deb$"
}

install_openlogi() {
  if dpkg -s openlogi >/dev/null 2>&1; then
    skip "openlogi already installed"
    return
  fi
  info "Installing OpenLogi"
  # Official installer: verifies the minisign signature and SHA256SUMS itself
  local tmp
  tmp="$(mktemp -d)"
  curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fsSL --retry 3 \
    -o "$tmp/openlogi-install.sh" \
    https://raw.githubusercontent.com/AprilNEA/OpenLogi/master/packaging/linux/install.sh
  sh "$tmp/openlogi-install.sh"
  rm -rf "$tmp"
}

install_steam() {
  if dpkg -s steam-launcher >/dev/null 2>&1; then
    skip "Steam already installed"
    return
  fi
  info "Installing Steam"
  # Steam needs 32-bit libraries; the package adds Valve's apt repository itself
  sudo dpkg --add-architecture i386
  sudo apt-get update
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/steam.deb" https://cdn.fastly.steamstatic.com/client/installer/steam.deb
  sudo apt-get install -y "$tmp/steam.deb"
  rm -rf "$tmp"
}

install_snaps() {
  local entry name flags
  for entry in "${SNAP_PACKAGES[@]}"; do
    name="${entry%%:*}"
    flags="${entry#*:}"
    if snap list "$name" >/dev/null 2>&1; then
      skip "snap $name already installed"
    else
      info "Installing snap $name"
      # shellcheck disable=SC2086 # flags is intentionally word-split
      sudo snap install "$name" $flags
    fi
  done
}

install_flatpaks() {
  info "Installing flatpak apps"
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak install -y --noninteractive flathub "${FLATPAK_APPS[@]}"
}

setup_waywallen() {
  local arch tmp
  arch="$(uname -m)"

  # Let waywallen pause on media playback (MPRIS)
  flatpak override --user --talk-name='org.mpris.MediaPlayer2.*' org.waywallen.waywallen

  if [ -d "$HOME/.local/share/plasma/wallpapers/org.waywallen.kde" ]; then
    skip "Waywallen KDE plugin already installed"
  else
    info "Installing Waywallen KDE plugin"
    tmp="$(mktemp -d)"
    download_github_asset waywallen/waywallen-display "^waywallen-kde-.*-${arch}-embed\\.zip$" "$tmp/kde.zip"
    kpackagetool6 --type Plasma/Wallpaper -i "$tmp/kde.zip"
    rm -rf "$tmp"
    info "Restart plasmashell to load it: systemctl --user restart plasma-plasmashell.service"
  fi

  local owe_dir="$WAYWALLEN_DATA/plugins/org.waywallen.open-wallpaper-engine"
  if [ -d "$owe_dir" ]; then
    skip "Waywallen Wallpaper Engine plugin already installed"
  else
    info "Installing Waywallen Wallpaper Engine plugin"
    tmp="$(mktemp -d)"
    download_github_asset waywallen/open-wallpaper-engine "^org\\.waywallen\\.open-wallpaper-engine-.*-linux-${arch}\\.zip$" "$tmp/owe.zip"
    mkdir -p "$owe_dir"
    unzip -q "$tmp/owe.zip" -d "$owe_dir"
    rm -rf "$tmp"
  fi
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    skip "Oh My Zsh already installed"
    return
  fi
  info "Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
}

install_fnm() {
  if [ -x "$HOME/.local/share/fnm/fnm" ] || command -v fnm >/dev/null; then
    skip "fnm already installed"
    return
  fi
  info "Installing fnm"
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
}

install_nerd_font() {
  if fc-list | grep "Hack Nerd Font" >/dev/null; then
    skip "Hack Nerd Font already installed"
    return
  fi
  info "Installing Hack Nerd Font"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/Hack.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz
  mkdir -p "$FONT_DIR"
  tar -xJf "$tmp/Hack.tar.xz" -C "$FONT_DIR"
  rm -rf "$tmp"
  fc-cache -f "$FONT_DIR"
}

# Moves files that would block stow out of the way. Stow itself reports the conflicts,
# so .stow-local-ignore is respected automatically.
backup_conflicts() {
  local rel
  while IFS= read -r rel; do
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$HOME/$rel" "$BACKUP_DIR/$rel"
    info "Backed up ~/$rel -> $BACKUP_DIR/$rel"
  done < <(stow --dir="$DOTFILES" --target="$HOME" --no-folding --simulate --stow . 2>&1 \
    | sed -nE \
      -e 's/.* over existing target (.+) since .*/\1/p' \
      -e 's/.* over existing directory target (.+)$/\1/p' \
      -e 's/.*existing target is not owned by stow: (.+)$/\1/p')
}

stow_dotfiles() {
  info "Stowing dotfiles"
  # Unfold directory links from older stow runs, otherwise files would be backed up through them
  stow --dir="$DOTFILES" --target="$HOME" --delete .
  backup_conflicts
  # --no-folding: never link whole directories, so apps can't write into the repo
  stow --dir="$DOTFILES" --target="$HOME" --no-folding --stow .
}

setup_git_identity() {
  if [ -f "$HOME/.gitconfig.local" ]; then
    skip "~/.gitconfig.local already exists"
    return
  fi
  info "Creating ~/.gitconfig.local (git identity, not tracked)"
  local name email
  read -rp "  Git name: " name
  read -rp "  Git email: " email
  git config --file "$HOME/.gitconfig.local" user.name "$name"
  git config --file "$HOME/.gitconfig.local" user.email "$email"
}

install_desktop_launchers() {
  # Launchers are symlinks to absolute system paths, which stow refuses – copy them instead
  local link
  mkdir -p "$HOME/Desktop"
  for link in "$DOTFILES"/kde/Desktop/*.desktop; do
    [ -e "$HOME/Desktop/${link##*/}" ] || cp -P "$link" "$HOME/Desktop/"
  done
}

install_node() {
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env --shell bash)"
  if fnm list | grep default >/dev/null; then
    skip "Node $(fnm current) already installed (default)"
    return
  fi
  info "Installing Node LTS via fnm"
  fnm install --lts
  fnm default lts-latest
}

install_pnpm() {
  if [ -x "$HOME/.local/share/pnpm/bin/pnpm" ] || command -v pnpm >/dev/null; then
    skip "pnpm already installed"
    return
  fi
  info "Installing pnpm"
  # The installer always runs `pnpm setup`, which adds PATH lines to a shell config.
  # .profile already has them, so point setup at a throwaway sh config ($ENV) instead
  # of letting it touch ~/.bashrc or the stowed ~/.zshrc.
  local tmp
  tmp="$(mktemp -d)"
  touch "$tmp/profile"
  curl -fsSL https://get.pnpm.io/install.sh \
    | env PNPM_HOME="$HOME/.local/share/pnpm" SHELL=/bin/sh ENV="$tmp/profile" sh -
  rm -rf "$tmp"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$zsh_path" ]; then
    skip "zsh is already the default shell"
    return
  fi
  info "Setting zsh as default shell"
  chsh -s "$zsh_path"
}

main() {
  add_apt_repos
  install_apt_packages
  install_github_debs
  install_openlogi
  install_steam
  install_snaps
  install_flatpaks
  setup_waywallen
  install_oh_my_zsh
  install_fnm
  install_nerd_font
  stow_dotfiles
  setup_git_identity
  install_desktop_launchers
  install_node
  install_pnpm
  set_default_shell
  info "Done! Reboot to apply the default shell and environment (logging out is not enough on KDE)."
}

main "$@"
