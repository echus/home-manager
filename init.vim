" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

" vim-plug plugins
call plug#begin('~/.config/nvim/plugged')
Plug 'jeffkreeftmeijer/neovim-sensible'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
call plug#end()

" Use system clipboard for yank/paste
set clipboard=unnamedplus

" Colorscheme
colorscheme catppuccin-macchiato " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
