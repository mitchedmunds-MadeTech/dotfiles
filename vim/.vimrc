syntax on
set wrap
set linebreak
set nolist
set textwidth=80
command! -nargs=* Wrap set wrap linebreak nolist

" Automatically wrap git commit message body to 72 chars
au FileType gitcommit setlocal tw=72
