#! /bin/bash
set -ex

rm -rf ~/.vimrc
rm -rf ~/.zshrc
rm -rf ~/.tmux.conf

cp .vimrc-min ~/.vimrc
cp .zshrc-min ~/.zshrc
cp .tmux.conf-min ~/.tmux.conf

mkdir -p ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim

echo "dot-min.sh complete"
