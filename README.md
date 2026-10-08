# Dotfiles

Personal dotfiles for Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Tool | Config |
| --- | --- |
| [zsh](https://www.zsh.org/) + [Oh My Zsh](https://ohmyz.sh/) | `.zshrc` |
| [Ghostty](https://ghostty.org/) | `.config/ghostty/config.ghostty` |
| [Helix](https://helix-editor.com/) | `.config/helix/config.toml` |
| [Yazi](https://yazi-rs.github.io/) | `.config/yazi/yazi.toml` |
| [Git](https://git-scm.com/) + [GCM](https://github.com/git-ecosystem/git-credential-manager) | `.gitconfig` (identity in untracked `~/.gitconfig.local`) |
| [Waywallen](https://github.com/waywallen/waywallen) autostart | `.config/autostart/org.waywallen.waywallen.desktop` |
| Login shell environment (PATH, pnpm) | `.profile`, `.zprofile` |
| KDE desktop launchers | `kde/Desktop` (not stowed, copied by `bootstrap.sh`) |
| [IdeaVim](https://github.com/JetBrains/ideavim) | `.ideavimrc` |

## Installation

### Automatic (Ubuntu / Kubuntu)

```sh
sudo apt install git
git clone https://github.com/KevinDanne/.dotfiles ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

The script is idempotent and will:

1. Add the [Yazi](https://yazi-rs.github.io/docs/installation), [Proton VPN](https://protonvpn.com/support/official-linux-vpn-ubuntu/), [VSCodium](https://vscodium.com/) and [Charm](https://github.com/charmbracelet/glow#package-manager) (glow) apt repositories
2. Install packages – the lists are at the top of `bootstrap.sh`:
   - apt: CLI tools, dev tools and apps that need full system access ([Ghostty](https://ghostty.org/), [Yazi](https://yazi-rs.github.io/), [VSCodium](https://vscodium.com/), [Podman](https://podman.io/), [CopyQ](https://hluk.github.io/CopyQ/), [Proton VPN](https://protonvpn.com/))
   - [Steam](https://store.steampowered.com/about/) (official `.deb`, enables i386)
   - `.deb` from latest GitHub release: [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
   - [OpenLogi](https://github.com/AprilNEA/OpenLogi) via its official installer (verifies minisign signature + SHA256SUMS)
   - snap: [Helix](https://helix-editor.com/) (classic), [Proton Mail](https://proton.me/mail)
   - flatpak (Flathub): [Zen Browser](https://zen-browser.app/), [Thunderbird](https://www.thunderbird.net/), [LibreOffice](https://www.libreoffice.org/), [Discord](https://discord.com/), [Spotify](https://www.spotify.com/), [Bruno](https://www.usebruno.com/), [Podman Desktop](https://podman-desktop.io/), [VLC](https://www.videolan.org/vlc/), [Waywallen](https://github.com/waywallen/waywallen)
3. Set up Waywallen: MPRIS override, [KDE plugin](https://github.com/waywallen/waywallen-display) and [Wallpaper Engine plugin](https://github.com/waywallen/open-wallpaper-engine) (latest GitHub releases)
4. Install [Oh My Zsh](https://ohmyz.sh/) **without overwriting `.zshrc`**
5. Install [fnm](https://github.com/Schniz/fnm) **without modifying `.zshrc`**
6. Install [Hack Nerd Font](https://www.nerdfonts.com/) to `~/.local/share/fonts/HackNerdFont`
7. Back up conflicting files to `~/.dotfiles-backup/<timestamp>/` and stow the dotfiles with [GNU Stow](https://www.gnu.org/software/stow/) (`--no-folding`)
8. Ask for your git name/email and write them to `~/.gitconfig.local` (if missing)
9. Copy the desktop launchers to `~/Desktop`
10. Install [Node.js](https://nodejs.org/) LTS via fnm and [pnpm](https://pnpm.io/) (standalone)
11. Set [zsh](https://www.zsh.org/) as the default shell

Not included on purpose – install manually if needed: JetBrains Toolbox, Unity Hub, Teams for Linux, Godot.
Machine-specific git settings (identity, host-specific credentials) go into `~/.gitconfig.local`.

### Adding packages

| Source | Where |
| --- | --- |
| apt (Ubuntu repos) | `APT_PACKAGES` |
| apt (third-party repo) | add the repo in `add_apt_repos`, the package to `APT_PACKAGES` |
| snap | `SNAP_PACKAGES` as `name:flags` |
| flatpak | `FLATPAK_APPS` (Flathub app ID) |
| `.deb` from GitHub releases | one `install_github_deb <package> <owner/repo> <asset regex>` line in `install_github_debs` |

Rule of thumb: GUI apps via Flatpak (sandboxed, fast updates), snap only if there is no Flatpak, apt for dev tools and anything that needs full system access.

### Manual (configs only)

```sh
git clone https://github.com/KevinDanne/.dotfiles ~/.dotfiles
cd ~/.dotfiles && stow --no-folding . && cd -
```

Existing files in `~` block stow – move them away first.

#### Requirements

> Only relevant if you don't use `bootstrap.sh` – the script installs all of this.

| Config | Needs |
| --- | --- |
| `.zshrc` | [Oh My Zsh](https://ohmyz.sh/) (incl. bundled `zsh-autosuggestions`, `zsh-syntax-highlighting`), [fnm](https://github.com/Schniz/fnm), [fzf](https://github.com/junegunn/fzf) >= 0.48, [zoxide](https://github.com/ajeetdsouza/zoxide), [Helix](https://helix-editor.com/) as `$EDITOR` |
| `.profile` | [pnpm](https://pnpm.io/) standalone in `~/.local/share/pnpm` (optional) |
| `.config/ghostty` | [Hack Nerd Font](https://www.nerdfonts.com/font-downloads) |
| `.gitconfig` | [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager), a Secret Service provider (KWallet on KDE) |
| `.config/autostart` | [Waywallen](https://github.com/waywallen/waywallen) (Flatpak) |
| `.ideavimrc` | A JetBrains IDE with the IdeaVim plugin |

## Uninstall

1. Unlink files
```sh
cd ~/.dotfiles && stow -D . && cd -
```

2. Remove repository
```sh
rm -rf ~/.dotfiles
```
