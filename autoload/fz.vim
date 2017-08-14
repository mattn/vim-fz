let s:is_nvim = has('nvim')

function! s:exit_cb(job, st, ...) " neovim passes third argument as 'exit' while vim passes only 2 arguments
  if a:st != 0
    exe s:buf 'bwipe!'
    call delete(s:tmp)
    return
  endif
  if !s:is_nvim
      silent! call ch_close(job_getchannel(term_getjob(s:buf)))
  endif
  let files = readfile(s:tmp)
  call delete(s:tmp)
  exe s:buf 'bwipe!'
  if len(files) == 0
    return
  endif
  if has_key(s:ctx, 'accept')
    call call(s:ctx['accept'], files)
  else
    if len(files) == 1
      exe 'edit' files[0]
    else
      for file in files
        exe 'sp' file
      endfor
    endif
  endif
endfunction

function! s:quote(arg)
  if has('win32')
    return '"' . substitute(a:arg, '"', '\"', 'g') . '"'
  endif
  return "'" . substitute(a:arg, "'", "\\'", 'g') . "'"
endfunction

let s:fz_command = get(g:, 'fz_command', 'files -I FZ_IGNORE -A | gof')

function! fz#run(...)
  if !s:is_nvim && !has('patch-8.0.928')
    echohl ErrorMsg | echo "vim-fz doesn't work on legacy vim" | echohl None
    return
  endif
  let s:ctx = get(a:000, 0, {})
  if type(s:ctx) != type({})
    echohl ErrorMsg | echo "invalid argument" | echohl None
    return
  endif
  let typ = get(s:ctx, 'type', 'cmd')
  if typ == 'cmd'
    let $FZ_IGNORE = get(s:ctx, 'ignore', '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$')
    let fzcmd = get(s:ctx, 'cmd', s:fz_command)
  else
    echohl ErrorMsg | echo "unsupported type" | echohl None
    return
  endif
  let s:tmp = tempname()
  let cmd = printf('%s %s %s > %s', &shell, &shellcmdflag, s:quote(fzcmd), s:tmp)
  if s:is_nvim
    botright new | resize 40
    let s:buf = bufnr('%')
    call termopen(cmd, {'on_exit': function('s:exit_cb')}) | startinsert
  else
    let s:buf = term_start(cmd, {'term_name': 'Fz', 'exit_cb': function('s:exit_cb')})
  endif
endfunction
