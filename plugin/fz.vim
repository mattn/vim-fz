function! s:exit_cb(job, st)
  if a:st != 0
    exe s:buf 'bwipe!'
    call delete(s:tmp)
    return
  endif
  silent! call ch_close(job_getchannel(term_getjob(s:buf)))
  let files = readfile(s:tmp)
  call delete(s:tmp)
  exe s:buf 'bwipe!'
  if len(files) == 0
    return
  endif
  if len(files) == 1
    exe 'edit' files[0]
  else
    for file in files
      exe 'sp' file
    endfor
  endif
endfunction

function! s:quote(arg)
  if has('win32')
    return '"' . substitute(a:arg, '"', '\"', 'g') . '"'
  endif
  return "'" . substitute(a:arg, "'", "\\'", 'g') . "'"
endfunction

if executable('fzf')
    let s:fz_command = get(g:, 'fz_command', 'fzf')
else
    let s:fz_command = get(g:, 'fz_command', 'files -I FZ_IGNORE -A | gof')
endif

function! s:fz()
  if !has('patch-8.0.928')
    echohl ErrorMsg | echo "vim-fz doesn't work on legacy vim" | echohl None
    return
  endif
  let $FZ_IGNORE = '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$'
  let s:tmp = tempname()
  let s:buf = term_start(printf('%s %s %s > %s', &shell, &shellcmdflag, s:quote(s:fz_command), s:tmp), {'term_name': 'Fz', 'exit_cb': function('s:exit_cb')})
endfunction

command! Fz call s:fz()
nnoremap <Plug>(fz) :<c-u>Fz<cr>
if !hasmapto('<Plug>(fz)')
  nmap ,f <Plug>(fz)
endif
