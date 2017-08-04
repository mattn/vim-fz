function! s:done(...)
  let files = getbufline(s:buf, 1, '$')
  if len(files) == 0
    call timer_start(10, function('s:done'))
    return
  endif
  exe s:buf 'bwipe!'
  if len(files) > 0
    for file in files
      exe 'sp' file
    endfor
  else
    exe 'edit' file
  endif
endfunction

function! s:exit_cb(job, st)
  if a:st != 0
    exe s:buf 'bwipe!'
    return
  endif
  call ch_close(job_getchannel(term_getjob(s:buf)))
  call timer_start(10, function('s:done'))
endfunction

let s:fz_command = get(g:, 'fz_command', 'files -I FZ_IGNORE -A | gof')
function! s:fz()
  let $FZ_IGNORE = '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$'
  let s:buf = term_start(printf('%s %s %s', &shell, &shellcmdflag, shellescape(s:fz_command)), {'exit_cb': function('s:exit_cb')})
endfunction

command! Fz call s:fz()
nnoremap <Plug>(fz) :<c-u>Fz<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
