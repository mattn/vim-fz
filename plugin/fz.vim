if exists('g:fz_loaded')
  finish
endif
let g:fz_loaded = 1

let g:fz_command = get(g:, 'fz_command', 'gof')
let g:fz_command_files = get(g:, 'fz_command_files', 'files -I FZ_IGNORE -A')
let g:fz_command_options_action = get(g:, 'fz_command_options_action', '-a=%s')
let g:fz_command_actions = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit'
  \ }

command! Fz call fz#run()
nnoremap <Plug>(fz) :<c-u>Fz<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
