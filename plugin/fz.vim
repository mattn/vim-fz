if exists('g:fz_loaded')
  finish
endif
let g:fz_loaded = 1

let g:fz_command = get(g:, 'fz_command', 'gof')
let g:fz_command_files = get(g:, 'fz_command_files', 'files %s -I FZ_IGNORE -A')
let g:fz_command_options_action = get(g:, 'fz_command_options_action', '-a=%s')
let g:fz_command_actions = {
  \ 'ctrl-o': 'edit',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit'
  \ }

command! -nargs=* -complete=dir Fz call fz#run({'basepath': <q-args>})
nnoremap <Plug>(fz) :<c-u>Fz<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
