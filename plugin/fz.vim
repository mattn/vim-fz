command! Fz call fz#run()
nnoremap <Plug>(fz) :<c-u>Fz<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
