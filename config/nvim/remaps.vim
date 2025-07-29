" Mapeamentos de remaps e atalhos
if (has("nvim"))
  nnoremap <leader>ff <cmd>Telescope find_files<cr>
  nnoremap <leader>fg <cmd>Telescope live_grep<cr>
  nnoremap <leader>fb <cmd>Telescope buffers<cr>
  nnoremap <leader>fh <cmd>Telescope help_tags<cr>
endif

" Ctrl+C para copiar a seleção visual
vmap <C-c> "+y

" Ctrl+V para colar do clipboard
map <C-v> "+p
imap <C-v> <C-r>+

" Tab para inserir uma tabulação
inoremap <Tab> <Tab>

" Ctrl+Z para desfazer
nnoremap <C-z> u
inoremap <C-z> <C-o>u

nnoremap <silent> U :redo<CR>
