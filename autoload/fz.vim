let s:is_nvim = has('nvim')
let s:is_win = has('win32') || has('win64')

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
      if filereadable(items[0])
        exe 'edit' items[0]
      endif
    else
      for item in items
        if filereadable(item)
          exe 'sp' item
        endif
      endfor
    endif
  endif
endfunction

function! s:quote(arg)
  if s:is_win
    return '"' . substitute(substitute(a:arg, '/', '\\', 'g'), '"', '\"', 'g') . '"'
  endif
  return "'" . substitute(a:arg, "'", "\\'", 'g') . "'"
endfunction

function! fz#run(...)
  if !s:is_nvim && !has('patch-8.0.928')
    echohl ErrorMsg | echo "vim-fz doesn't work on legacy vim" | echohl None
    return
  endif

  " create context
  let ctx = {
    \ 'options': get(a:000, 0, {})
    \ }

  " check argument
  if type(ctx['options']) != type({})
    echohl ErrorMsg | echo "invalid argument" | echohl None
    return
  endif

  " check type
  let typ = get(ctx['options'], 'type', 'cmd')
  if typ == 'cmd'
    let $FZ_IGNORE = get(ctx['options'], 'ignore', '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$')
    let fzcmd = get(ctx['options'], 'cmd', empty(g:fz_command_files) ? g:fz_command : printf('%s | %s', g:fz_command_files, g:fz_command))
  elseif typ == 'file'
    let fz_command = get(ctx['options'], 'fz_command', g:fz_command)
    if !has_key(ctx['options'], 'file')
      echohl ErrorMsg | echo "invalid argument. 'file' required" | echohl None
      return
    endif
    let fzcmd = printf('%s < %s', fz_command, s:quote(ctx['options']['file']))
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
