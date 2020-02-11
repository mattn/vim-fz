if exists('g:fz_loaded')
  finish
endif
let g:fz_loaded = 1

let g:fz_command = get(g:, 'fz_command', 'gof')
let g:fz_command_options_action = get(g:, 'fz_command_options_action', '-a=%s')
let g:fz_command_actions = {
  \ 'ctrl-o': 'edit',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit'
  \ }

command! -nargs=* -complete=dir Fz call fz#run({'basepath': <q-args>})
command! -nargs=* -complete=dir FzMRU call fz#run({'basepath': <q-args>, 'type': 'list', 'list': fz#utils#uniq(map(filter(map(map(range(bufnr('$'), 1, -1), 'bufname(v:val)') + copy(v:oldfiles), 'expand(v:val)'), 'filereadable(v:val)'), 'fnamemodify(v:val, ":~:.:gs!\\!/!")'))})
nnoremap <Plug>(fz) :<c-u>Fz<cr>
nnoremap <Plug>(fz-mru) :<c-u>FzMRU<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
if !hasmapto('<Plug>(fz-mru)')
  nmap ,, <Plug>(fz-mru)
endif
