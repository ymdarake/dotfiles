colorscheme codedark

set number

call plug#begin()
" enables file tree
Plug 'lambdalisue/fern.vim'
" shows git diff on file tree
Plug 'lambdalisue/fern-git-status.vim'
" shows icons
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
" color file tree icons
Plug 'lambdalisue/glyph-palette.vim'

" shows status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" shows git diff
Plug 'airblade/vim-gitgutter'

" enables Find files
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()

" Ctrl + n to toggle file tree
nnoremap <C-n> :Fern . -reveal=% -drawer -toggle -width=40<CR>

" vim-airline
"" shows tab line
let g:airline#extensions#tabline#enabled = 1
"" changes items on the status bar
let g:airline#extensions#default#layout = [
  \ [ 'a', 'b', 'c' ],
  \ ['z']
  \ ]
let g:airline_section_c = '%t %M'
let g:airline_section_z = get(g:, 'airline_linecolumn_prefix', '').'%3l:%-2v'

" never shows diff line count when no changes made
let g:airline#extensions#hunks#non_zero_only = 1 

" customizes tab line
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_tab_type = 1
let g:airline#extensions#tabline#show_close_button = 0

" shows icons
let g:fern#renderer = 'nerdfont'
" color icons
augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END

"" git操作
" g]で前の変更箇所へ移動する
nnoremap g[ :GitGutterPrevHunk<CR>
" g[で次の変更箇所へ移動する
nnoremap g] :GitGutterNextHunk<CR>
" ghでdiffをハイライトする
nnoremap gh :GitGutterLineHighlightsToggle<CR>
" gpでカーソル行のdiffを表示する
nnoremap gp :GitGutterPreviewHunk<CR>
" 記号の色を変更する
highlight GitGutterAdd ctermfg=green
highlight GitGutterChange ctermfg=blue
highlight GitGutterDelete ctermfg=red

"" 反映時間を短くする(デフォルトは4000ms)
set updatetime=250

