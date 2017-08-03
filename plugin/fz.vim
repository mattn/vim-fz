function! s:exit_cb(job, st)
  if a:st != 0
    exe s:buf 'bwipe!'
    return
  endif
  call ch_close(job_getchannel(term_getjob(s:buf)))
  let file = getbufline(s:buf, 1)[0]
  exe s:buf 'bwipe!'
  exe 'edit' file
endfunction

let s:fz_command = get(g:, 'fz_command', 'files -A | gof')
function! s:fz()
  let $FILES_IGNORE_PATTERN = '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$'
  let s:buf = term_start(printf('%s %s %s', &shell, &shellcmdflag, shellescape(s:fz_command)), {'exit_cb': function('s:exit_cb')})
endfunction

command! Fz call s:fz()
nnoremap <Plug>(fz) :<c-u>Fz<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
