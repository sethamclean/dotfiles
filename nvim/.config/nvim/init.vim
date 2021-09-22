"------------------------------------------------------------------------------
" Setup plug-ins
"------------------------------------------------------------------------------
"if &compatible
"    set nocompatible
"endif

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')

let packages = [
            \ 'w0rp/ale',
            \ 'vim-scripts/dbext.vim',
            \ 'burnettk/vim-angular',
            \ 'Konfekt/FastFold',
            \ 'Konfekt/FoldText',
            \ 'rust-lang/rust.vim',
            \ 'cespare/vim-toml',
            \ 'tpope/vim-surround',
            \ 'tpope/vim-fugitive',
            \ 'tpope/vim-git',
            \ 'mileszs/ack.vim',
            \ 'sjl/gundo.vim',
            \ 'fs111/pydoc.vim',
            \ 'vim-scripts/TaskList.vim',
            \ 'vim-scripts/The-NERD-tree',
            \ 'klen/python-mode',
            \ 'janko-m/vim-test',
            \ 'morhetz/gruvbox',
            \ 'fxn/vim-monochrome',
            \ 'whatyouhide/vim-gotham',
            \ 'tomasr/molokai',
            \ 'othree/xml.vim',
            \ 'szw/vim-maximizer',
            \ 'airblade/vim-gitgutter',
            \ 'majutsushi/tagbar',
            \ 'fatih/vim-go',
            \ 'benmills/vim-golang-alternate',
            \ 'rhysd/vim-crystal',
            \  'python-rope/ropevim',
            \ 'fholgado/minibufexpl.vim',
            \ 'itchyny/lightline.vim',
            \ 'scrooloose/nerdcommenter',
            \ 'vim-scripts/delimitMate.vim',
            \ 'vim-scripts/javacomplete',
            \ 'Chiel92/vim-autoformat',
            \ 'honza/vim-snippets',
            \ 'SirVer/ultisnips',
            \ 'Shougo/denite.nvim',
            \ 'nathanaelkane/vim-indent-guides',
            \ 'Rip-Rip/clang_complete',
            \ 'godlygeek/tabular',
            \ 'plasticboy/vim-markdown',
            \ 'saltstack/salt-vim',
            \ 'lepture/vim-jinja',
            \ 'haskell/haskell-mode',
            \ 'elixir-lang/vim-elixir',
            \ 'jiangmiao/auto-pairs',
            \ 'sheerun/vim-polyglot',
            \ 'Shougo/deoplete.nvim',
            \ 'wellle/tmux-complete.vim',
            \ 'zchee/deoplete-jedi',
            \ 'davidhalter/jedi-vim',
            \ 'zchee/deoplete-go',
            \ ]

for package in packages
    Plug package
endfor

call plug#end()

filetype plugin indent on
syntax enable


"------------------------------------------------------------------------------
" nvim interpreter settings
"------------------------------------------------------------------------------
let g:python_host_prog = '/bin/python3'

"------------------------------------------------------------------------------
" Bindings
"------------------------------------------------------------------------------
" Use ctrl-[hjkl] to select the active split!
nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>
nmap <silent> <c-x> :bd <CR>
nmap <space><space> <leader>
" Plugins
" tagbar
map <leader>tb :Tagbar<CR>
" Minibufexmplorer
map <leader>m :MBEToggle<CR>
" Maximizer
map <leader>f :MaximizerToggle<CR>
" task list
map <leader>td <Plug>TaskList
"Gundo
map <leader>g :GundoToggle<CR>
" Mash exit
inoremap jj <Esc>
"Reselect visual block after indent/outdent
vnoremap < <gv
vnoremap > >gv

"------------------------------------------------------------------------------
"Look and feel
"------------------------------------------------------------------------------
"Fold level
set foldlevelstart=20
"show whitespace
set invlist
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
"Theme
set t_Co=256
colorscheme gruvbox
let g:gruvbox_contrast_dark = "hard"
set background=dark
"set color line
let &colorcolumn=join(range(81,999),",")
"set colorcolumn=81
highlight ColorColumn ctermbg=0
"Status Line improvements
set laststatus=2
" automatic line numbering
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END
"Highlight the current line number
set cursorline
"hi CursorLine term=bold cterm=bold guibg=Grey40
"Search highlight colors
hi Search cterm=bold ctermfg=black ctermbg=yellow
"Live update of substitute
set inccommand=nosplit

"------------------------------------------------------------------------------
"Behavior
"------------------------------------------------------------------------------
"set clipboard=unnamed,unnamedplus
" I HATE YOU SWAP FILES
set noswapfile
" smart backspacing set backspace=indent,eol,start
" keep curser closer to center of view
set scrolloff=20
"Set tabs to spaces set
set tabstop=4
set shiftwidth=4
set expandtab
set copyindent
set preserveindent
set autoindent
set spell spelllang=en_us
"Spellcheck git commit messages
autocmd BufRead COMMIT_EDITMSG setlocal spell!
"Resize splits when the window is resized
au VimResized * exe "normal! \<c-w>="
"Don't unload buffer when switching set hidden
"Autosave
autocmd BufLeave,CursorHold,CursorHoldI,FocusLost * silent! wa

"------------------------------------------------------------------------------
" TagBar Plugin Settings
"------------------------------------------------------------------------------
let g:tagbar_autoclose = 1
let g:tagbar_autofocus = 1

"------------------------------------------------------------------------------
" Java Complete settings
"------------------------------------------------------------------------------
if has("autocmd")
    autocmd Filetype java setlocal omnifunc=javacomplete#Complete
    autocmd Filetype java setlocal completefunc=javacomplete#CompleteParamsInfo
endif

"------------------------------------------------------------------------------
" Groovy Complete settings
"------------------------------------------------------------------------------
autocmd FileType groovy setlocal shiftwidth=2 tabstop=2

"------------------------------------------------------------------------------
" vim-go settings
"------------------------------------------------------------------------------
let g:go_fmt_command = "goimports"
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1

au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>c <Plug>(go-coverage)
au FileType go nmap <Leader>gb <Plug>(go-doc-browser)
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <Leader>i <Plug>(go-info)

"------------------------------------------------------------------------------
" Auto format settings
"------------------------------------------------------------------------------
function! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfunction

"au BufWrite * :Autoformat
if has("autocmd")
    "Trim whitespace created by autoformat
    autocmd BufWritePre *.java Autoformat%s#\($\n\s*\)\+\%$##
    autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()
endif

"------------------------------------------------------------------------------
" File types
"------------------------------------------------------------------------------
au BufNewFile,BufRead *.sls set filetype=yaml
au BufNewFile,BufRead *.gradle set filetype=groovy

"------------------------------------------------------------------------------
" Denite.nvim Settings
"------------------------------------------------------------------------------
map ff :Denite file_rec<CR>
map fb :Denite buffer file_rec<CR>
map <leader>g :Denite grep:.<CR>
let g:denite_source_grep_max_candidates = 200

if executable('ag')
    " Use ag in denite grep source.
    let g:denite_source_grep_command = 'ag'
    let g:denite_source_grep_default_opts =
            \ '-i --line-numbers --nocolor --nogroup --hidden --ignore ' .
            \  '''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
    let g:denite_source_grep_recursive_opt = ''
elseif executable('pt')
    " Use pt in denite grep source.
    " https://github.com/monochromegane/the_platinum_searcher
    let g:denite_source_grep_command = 'pt'
    let g:denite_source_grep_default_opts = '--nogroup --nocolor'
    let g:denite_source_grep_recursive_opt = ''
elseif executable('ack-grep')
    " Use ack in denite grep source.
    let g:denite_source_grep_command = 'ack-grep'
    let g:denite_source_grep_default_opts =
                \ '-i --no-heading --no-color -k -H'
    let g:denite_source_grep_recursive_opt = ''
endif

"------------------------------------------------------------------------------
" Deoplete.nvim Settings
"------------------------------------------------------------------------------
"" Use deoplete
let g:deoplete#enable_at_startup = 1
" Dissable AutoComplPop.
let g:acp_enableAtStartup = 1
" Use smartcase. Deprecated
"let g:deoplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:deoplete#sources#syntax#min_keyword_length = 2
let g:deoplete#lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:deoplete#sources#dictionary#dictionaries = {
            \ 'default' : '',
            \ 'vimshell' : $HOME.'/.vimshell_hist',
            \ 'scheme' : $HOME.'/.gosh_completions'
            \ }

" Define keyword.: Deprecated
"if !exists('g:deoplete#keyword_patterns')
"    let g:deoplete#keyword_patterns = {}
"endif
"let g:deoplete#keyword_patterns['default'] = '\h\w*'
if !exists('g:deoplete#sources#omni#input_patterns')
    let g:deoplete#force_omni_input_patterns = {}
endif
let g:deoplete#force_omni_input_patterns.go = '[^.[:digit:] *\t]\.'

"------------------------------------------------------------------------------
"CTags
"------------------------------------------------------------------------------
set tags=./tags,tags;$HOME

"------------------------------------------------------------------------------
" python mode settings
"------------------------------------------------------------------------------
let g:pymode_rope = 0
let g:pymode_lint = 0

"------------------------------------------------------------------------------$
" Syntastic settings$
"------------------------------------------------------------------------------$
let g:syntastic_html_checkers = ['w3']
hi SpellBad ctermfg=Red ctermbg=Black
hi SpellBad ctermfg=Red ctermbg=Black

"------------------------------------------------------------------------------
" Indent guide settings
"------------------------------------------------------------------------------
let g:indent_guides_start_level=2
let g:indent_guides_auto_colors = 0
let g:indent_guides_guide_size = 1
let g:indent_guides_enable_on_vim_startup = 1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=238
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=236


"------------------------------------------------------------------------------
"NERDTree
"------------------------------------------------------------------------------
"map ctrl+n nerd tree
map <leader>n :NERDTreeToggle<CR>
let g:NERDTreeDirArrows=0

"------------------------------------------------------------------------------
"UltiSnips
"------------------------------------------------------------------------------
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
let g:UltiSnipsSnippetsDir=$HOME.'/.vim/snippets'
let g:UltiSnipsSnippetDirectories=[$HOME.'/.vim/snippets']

"------------------------------------------------------------------------------
"lightline
"------------------------------------------------------------------------------
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head',
      \   'filename': 'StatusFilename'
      \ },
      \ }

function StatusFilename()
    return expand('%:p')
endfunction
"------------------------------------------------------------------------------
"Ale
"------------------------------------------------------------------------------
let g:ale_completion_enabled = 1
let g:ale_fix_on_save = 1

let g:ale_fixers = {
\    'python': ['autopep8'],
\    'cpp': ['clang-format'],
\}

"------------------------------------------------------------------------------
"vim-test
"------------------------------------------------------------------------------
nmap <silent> t<C-n> :TestNearest<CR> " t Ctrl+n
nmap <silent> t<C-f> :TestFile<CR>    " t Ctrl+f
nmap <silent> t<C-s> :TestSuite<CR>   " t Ctrl+s
nmap <silent> t<C-l> :TestLast<CR>    " t Ctrl+l
nmap <silent> t<C-g> :TestVisit<CR>   " t Ctrl+g
nmap <silent> t<C-t> :TestSuite<CR>   " t Ctrl+t

let test#python#pytest#options = {
        \ 'nearest': '-s',
        \ 'file': '-s',
        \ 'suite': '-s',
    \}
