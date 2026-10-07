# Dotfiles

Personal dotfiles for linux

## Installation

1. Clone repository
```sh
git clone https://github.com/KevinDanne/.dotfiles ~/
```
2. Stow files
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
