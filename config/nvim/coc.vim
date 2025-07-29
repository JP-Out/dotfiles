let g:coc_global_extensions = ['coc-snippets', 'coc-explorer']
set encoding=utf-8
set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes

" Defina os mapeamentos do COC aqui
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

