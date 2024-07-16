#! /bin/bash
set -ex

cd ~

ln -s  $PWD/.vimrc-min ~/.vimrc
ln -s  $PWD/.zshrc-min ~/.zshrc
ln -s  $PWD/.tmux.conf-min ~/.tmux.conf

echo "ln dotfiles complete"
