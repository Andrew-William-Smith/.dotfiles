" Copyright (c) 2022, Andrew Smith <aws@awsmith.us> :::::::::::: SOLI DEO GLORIA
" SPDX-License-Identifier: GPL-3.0-or-later

" {{{ General settings.
set nocompatible           " Disable vi compatibility.
set noshowmode             " Disable mode indicator in command line.
set showcmd                " Show commands as they are being typed.
set modeline               " Respect file-local modeline settings.

set number relativenumber  " Enable relative line numbers.
set cursorline             " Highlight the current line.
set colorcolumn=80,100     " Highlight common maximum line lengths.

set hlsearch               " Highlight search results.
                           " Note: sensible enables clearing with <C-l>.
set incsearch              " Scroll to the first search result while typing.
set ignorecase             " Ignore case in searches.
set smartcase              " Override ^ when the pattern contains uppercase.

set wildmenu               " Use an interactive menu for command-line completion.
set wildmode=longest:full,full

set autoindent             " Enable automatic indentation.
set smartindent            " Indent based on file type.
set tabstop=4              " Render tabs as 4 spaces.
set shiftwidth=4
set expandtab              " Never use tabs.
set encoding=utf-8         " Assume UTF-8 encoding by default.

" Enable filetype plugins.
filetype plugin on
filetype indent on

" Enable true colour in the terminal.
if has('termguicolors')
    set termguicolors
end
" }}}

" {{{ Keybinding customisations.
nnoremap <SPACE> <Nop>
let mapleader=" "          " Use <Space> as leader rather than \.

" Switch between panes without C-w.
nnoremap <leader><leader> <C-w><C-w>
nnoremap <leader>h <C-w>h
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l
" Create new panes without invoking the command line.
nnoremap <leader>s :vsplit<CR>
nnoremap <leader>a :split<CR>
" Delete panes without C-w.
nnoremap <leader>d :q<CR>
" }}}

" {{{ GVim-specific settings.
if has('gui_running')
    " Set the font.
    if has('gui_gtk2') || has('gui_gtk3')
        set guifont=Iosevka\ Collegiate\ 12
    elseif has('gui_macvim') || has('gui_win32')
        set guifont=Iosevka\ Collegiate:h12
    endif

    " Disable the toolbar.
    set guioptions-=T
endif
" }}}

" {{{ Package manifest.
packadd! quick-scope
packadd! gruvbox-material
packadd! lightline.vim
packadd! rainbow_parentheses.vim
packadd! seoul256.vim
packadd! vim-better-whitespace
packadd! vim-commentary
packadd! vim-sensible
packadd! vim-surround
" }}}

" {{{ Plugin configurations.
" {{{ quick-scope
" Only highlight when motion keys are pressed.
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
" Make quick-scope targets more prominent.
augroup qs_colors
    autocmd!
    autocmd ColorScheme * highlight QuickScopePrimary ctermfg=0 ctermbg=11 guifg=Black guibg=#FFFF00     " Yellow
    autocmd ColorScheme * highlight QuickScopeSecondary ctermfg=0 ctermbg=172 guifg=Black guibg=#FF8300  " Orange
augroup END
" }}}
" {{{ vim-better-whitespace
" Highlight in a red that matches the colourscheme.
augroup bw_colors
    autocmd!
    autocmd ColorScheme * highlight ExtraWhitespace ctermbg=Red guibg=#ea6962
augroup END
" }}}
" {{{ gruvbox-material
" Increase contrast between text and the background.
set background=dark
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_ui_contrast = 'high'

" Activate the colourscheme. Must appear after quick-scope configuration in
" order for colour customisation to take effect.
colorscheme gruvbox-material
" }}}
" {{{ seoul256.vim
" Increase contrast between text and the background.
let g:seoul256_srgb = 1
let g:seoul256_background = 234
" }}}
" {{{ rainbow_parentheses
" Add additional delimiters.
let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]
" Enable in all buffers by default.
augroup rainbow_parentheses
    autocmd!
    autocmd VimEnter * RainbowParentheses
augroup END
" }}}
" {{{ lightline
" Always display the statusline.
set laststatus=2
" Use the Gruvbox Material colourscheme.
let g:lightline = { 'colorscheme': 'gruvbox_material' }
" }}}
" }}}

" vim: set sw=4 ts=4 sts=4 et tw=80 foldmethod=marker:
