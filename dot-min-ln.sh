#! /bin/bash
set -ex

cd ~

cp dotfiles_min/.vimrc-min ~/.vimrc
cp dotfiles_min/.zshrc-min ~/.zshrc
cp dotfiles_min/.tmux.conf-min ~/.tmux.conf

echo "ln dotfiles complete"
