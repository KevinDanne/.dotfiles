# Dotfiles

Personal dotfiles for Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

| Tool | Config |
| --- | --- |
| [zsh](https://www.zsh.org/) + [Oh My Zsh](https://ohmyz.sh/) | `.zshrc` |
| [Ghostty](https://ghostty.org/) | `.config/ghostty/config.ghostty` |
| [Helix](https://helix-editor.com/) | `.config/helix/config.toml` |
| [IdeaVim](https://github.com/JetBrains/ideavim) | `.ideavimrc` |

## Dependencies

### Required

- `git`
- `stow`

### Shell

- `zsh`
- [Oh My Zsh](https://ohmyz.sh/)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) (bundled with Oh My Zsh)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) (bundled with Oh My Zsh)
- [fnm](https://github.com/Schniz/fnm) – Node version manager
- [zoxide](https://github.com/ajeetdsouza/zoxide) – smarter `cd`
- [fzf](https://github.com/junegunn/fzf) – fuzzy finder (>= 0.48 for `fzf --zsh`)

### Editor & Terminal

- [Helix](https://helix-editor.com/) (`hx`)
- [Ghostty](https://ghostty.org/) (>= 1.1.1 for server-side decorations on KDE)
- Font: [Hack](https://sourcefoundry.org/hack/)
- A JetBrains IDE with the IdeaVim plugin

## Installation

1. Install packages (Ubuntu / Kubuntu)
```sh
sudo apt install git stow zsh zoxide fzf fonts-hack
```
Helix and Ghostty: see their install docs ([Helix](https://docs.helix-editor.com/install.html), [Ghostty](https://ghostty.org/docs/install)).

2. Install Oh My Zsh **without overwriting `.zshrc`**
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc
```

3. Install fnm **without modifying `.zshrc`**
```sh
curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
```

4. Clone repository
```sh
git clone https://github.com/KevinDanne/.dotfiles ~/.dotfiles
```

5. Stow files
```sh
cd ~/.dotfiles && stow . && cd -
```

## Uninstall

1. Unlink files
```sh
cd ~/.dotfiles && stow -D . && cd -
```

2. Remove repository
```sh
rm -rf ~/.dotfiles
```
