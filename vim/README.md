# Vim
 - Install [vim-plug](https://github.com/junegunn/vim-plug)
 - Download vim-code-dark
 - `PlugInstall` to install plugins in .vimrc

## As of Now

```sh

ln -s $(pwd)/.vimrc ~/.vimrc

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

git clone https://github.com/tomasiser/vim-code-dark.git ~/.vim/bundle/vim-code-dark.git
mkdir ~/.vim/colors
ln -s ~/.vim/bundle/vim-code-dark.git/colors/codedark.vim ~/.vim/colors/codedark.vim

vim .
:PlugInstall

```
