let s:is_nvim = has('nvim')
let s:is_win = has('win32') || has('win64')

function! s:wipe(ctx)
  if buflisted(a:ctx['buf'] )
    exe a:ctx['buf'] 'bwipe!'
  endif
endfunction

" first argument is the ctx
" neovim passes third argument as 'exit' while vim passes only 2 arguments
function! s:exit_cb(ctx, job, st, ...)
  if has_key(a:ctx, 'tmp_input')
    call delete(a:ctx['tmp_input'])
  endif
  if a:st != 0
    call s:wipe(a:ctx)
    call delete(a:ctx['tmp_result'])
    return
  endif
  if !s:is_nvim
    silent! call ch_close(job_getchannel(term_getjob(a:ctx['buf'])))
  endif
  let items = readfile(a:ctx['tmp_result'])
  call delete(a:ctx['tmp_result'])
  call s:wipe(a:ctx)
  if len(items) == 0
    return
  endif
  if has_key(a:ctx['options'], 'accept')
    let params = {}
    if has_key(a:ctx, 'actions')
      let params['actions'] = a:ctx['actions']
      if has_key(params['actions'], items[0])
        let params['action'] = params['actions'][items[0]]
      else
        let params['action'] = items[0]
      endif
      let params['items'] = items[1:]
    else
      let params['items'] = items
    endif
    call a:ctx['options']['accept'](params)
  else
    if has_key(a:ctx, 'actions')
      let action = items[0]
      let items = items[1:]
    else
      let action = ''
    endif

    if len(items) == 1 && action == ''
      if filereadable(items[0])
        exe 'edit' items[0]
      endif
    else
      for item in items
        if filereadable(item)
          if action == ''
            exe 'sp' item
          else
            exe a:ctx['actions'][action] . ' ' . item
          endif
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

function! s:get_redirect_cmd(ctx, file)
  let fz_command = get(a:ctx['options'], 'fz_command', g:fz_command)
  return printf('%s%s < %s', fz_command, s:get_fzcmd_options(a:ctx), s:quote(a:file))
endfunction

function! s:get_fzcmd_options(ctx)
  " should include empty space if it contains options
  let actions = get(a:ctx['options'], 'actions', g:fz_command_actions)
  if !empty(actions)
    let options_action = get(a:ctx['options'], 'options_action', g:fz_command_options_action)
    let a:ctx['actions'] = actions
    return ' ' . printf(options_action, join(keys(actions), ','))
  endif
  return ''
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

  " Get basepath
  let basepath = get(ctx['options'], 'basepath', '')
  if basepath != ''
    let basepath = expand(basepath)
  endif

  " check type
  let typ = get(ctx['options'], 'type', 'cmd')
  if typ == 'cmd'
    let $FZ_IGNORE = get(ctx['options'], 'ignore', '(^|[\/])(\.git|\.hg|\.svn|\.settings|\.gitkeep|target|bin|node_modules|\.idea|^vendor)$|\.(exe|so|dll|png|obj|o|idb|pdb)$')
    let fz_command = get(ctx['options'], 'fz_command', g:fz_command)
    let cmd = get(ctx['options'], 'cmd', g:fz_command_files)
    let cmd = isdirectory(basepath) ? printf(cmd, basepath) : printf(cmd, '')
    let fzcmd = empty(cmd) ? printf('%s%s', g:fz_command, s:get_fzcmd_options(ctx)) : printf('%s | %s%s', cmd, fz_command, s:get_fzcmd_options(ctx))
  elseif typ == 'file'
    if !has_key(ctx['options'], 'file')
      echohl ErrorMsg | echo "invalid argument. 'file' required." | echohl None
      return
    endif
    let fzcmd = s:get_redirect_cmd(ctx, ctx['options']['file'])
  elseif typ == 'list'
    if !has_key(ctx['options'], 'list')
      echohl ErrorMsg | echo "invalid argument. 'list' required." | echohl None
      return
    endif
    if type(ctx['options']['list']) != type([])
      echohl ErrorMsg | echo "invalid argument 'list'." | echohl None
      return
    endif
    let ctx['tmp_input'] = tempname()
    call writefile(ctx['options']['list'], ctx['tmp_input'])
    let fzcmd = s:get_redirect_cmd(ctx, ctx['tmp_input'])
  else
    echohl ErrorMsg | echo "unsupported type" | echohl None
    return
  endif
  let ctx['tmp_result'] = tempname()
  let cmd = [&shell, &shellcmdflag, printf('%s > %s', fzcmd, ctx['tmp_result'])]
  botright new
  let ctx['buf'] = bufnr('%')
  if s:is_nvim
    call termopen(cmd, {'on_exit': function('s:exit_cb', [ctx])}) | startinsert
  else
    call term_start(cmd, {'term_name': 'Fz', 'curwin': ctx['buf'], 'exit_cb': function('s:exit_cb', [ctx])})
  endif
endfunction
