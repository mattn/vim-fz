let s:is_nvim = has('nvim')

" first argument is the ctx
" neovim passes third argument as 'exit' while vim passes only 2 arguments
function! s:exit_cb(ctx, job, st, ...)
  if a:st != 0
    exe a:ctx['buf'] 'bwipe!'
    call delete(a:ctx['tmp_result'])
    return
  endif
  if !s:is_nvim
      silent! call ch_close(job_getchannel(term_getjob(a:ctx['buf'])))
  endif
  let items = readfile(a:ctx['tmp_result'])
  call delete(a:ctx['tmp_result'])
  exe a:ctx['buf'] 'bwipe!'
  if len(items) == 0
    return
  endif
  if has_key(a:ctx['options'], 'accept')
    call call(a:ctx['options']['accept'], { 'items': items })
  else
    if len(items) == 1
      exe 'edit' items[0]
    else
      for item in items
        exe 'sp' item
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
  let ctx = {
    \ 'options': get(a:000, 0, {})
    \ }
  if type(ctx['options']) != type({})
    echohl ErrorMsg | echo "invalid argument" | echohl None
    return
  endif
  let typ = get(ctx['options'], 'type', 'cmd')
  if typ == 'cmd'
    let $FZ_IGNORE = get(ctx['options'], 'ignore', '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$')
    let fzcmd = get(ctx['options'], 'cmd', s:fz_command)
  else
    echohl ErrorMsg | echo "unsupported type" | echohl None
    return
  endif
  let ctx['tmp_result'] = tempname()
  let cmd = printf('%s %s %s > %s', &shell, &shellcmdflag, s:quote(fzcmd), ctx['tmp_result'])
  botright new
  let ctx['buf'] = bufnr('%')
  if s:is_nvim
    call termopen(cmd, {'on_exit': function('s:exit_cb', [ctx])}) | startinsert
  else
    call term_start(cmd, {'term_name': 'Fz', 'curwin': ctx['buf'], 'exit_cb': function('s:exit_cb', [ctx])})
  endif
endfunction
