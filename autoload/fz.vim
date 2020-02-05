let s:is_nvim = has('nvim')
let s:is_win = has('win32') || has('win64')

function! s:wipe(ctx)
  if buflisted(a:ctx['buf'] )
    exe a:ctx['buf'] 'bwipe!'
  endif
endfunction

" first argument is the ctx
" neovim passes third argument as 'exit' while vim passes only 2 arguments
function! s:exit_cb(ctx, job, st, ...) abort
  if has_key(a:ctx, 'tmp_input') && !has_key(a:ctx, 'file')
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
  let l:items = readfile(a:ctx['tmp_result'])
  call delete(a:ctx['tmp_result'])
  call s:wipe(a:ctx)
  if len(l:items) == 0
    return
  endif
  if has_key(a:ctx['options'], 'accept')
    let l:params = {}
    if has_key(a:ctx, 'actions')
      let l:params['actions'] = a:ctx['actions']
      if has_key(l:params['actions'], l:items[0])
        let l:params['action'] = l:params['actions'][l:items[0]]
      else
        let l:params['action'] = l:items[0]
      endif
      let l:params['items'] = l:items[1:]
    else
      let l:params['items'] = l:items
    endif
    call a:ctx['options']['accept'](l:params)
  else
    if has_key(a:ctx, 'actions')
      let l:action = l:items[0]
      let l:items = l:items[1:]
    else
      let l:action = ''
    endif

    if len(l:items) == 1 && l:action == ''
      let l:path = a:ctx.basepath . '/' . l:items[0]
      if filereadable(expand(l:path))
        if &modified
          if winwidth(win_getid()) > winheight(win_getid()) * 3
            exe 'vsplit' l:path
          else
            exe 'split' l:path
          endif
        else
          exe 'edit' l:path
        endif
      endif
    else
      for l:item in l:items
        let l:path = a:ctx.basepath . '/' . l:item
        if filereadable(expand(l:path))
          if l:action == ''
            exe 'sp' l:path
          else
            exe a:ctx['actions'][l:action] . ' ' . l:path
          endif
        endif
      endfor
    endif
  endif
endfunction

function! s:get_fzcmd_options(ctx) abort
  " should include empty space if it contains options
  let l:actions = get(a:ctx['options'], 'actions', g:fz_command_actions)
  if !empty(l:actions)
    let l:options_action = get(a:ctx['options'], 'options_action', g:fz_command_options_action)
    if l:options_action == ''
      return ''
    endif
    let a:ctx['actions'] = l:actions
    return ' ' . printf(l:options_action, join(keys(l:actions), ','))
  endif
  return ''
endfunction

function! fz#run(...)
  if !s:is_nvim && !has('patch-8.0.928')
    echohl ErrorMsg | echo "vim-fz doesn't work on legacy vim" | echohl None
    return
  endif

  " create context
  let l:ctx = {
    \ 'options': get(a:000, 0, {}),
    \ 'basepath': ''
    \ }

  " check argument
  if type(l:ctx['options']) != type({})
    echohl ErrorMsg | echo 'invalid argument' | echohl None
    return
  endif

  " Get basepath
  let l:basepath = get(l:ctx['options'], 'basepath', '')
  if empty(l:basepath)
    let l:basepath = '.'
  endif
  let l:ctx['basepath'] = expand(l:basepath)

  " check type
  let l:typ = get(l:ctx['options'], 'type', 'cmd')
  if l:typ ==# 'cmd'
    let l:fz_command = get(l:ctx['options'], 'fz_command', g:fz_command)
  elseif l:typ ==# 'file'
    if !has_key(l:ctx['options'], 'file')
      echohl ErrorMsg | echo "invalid argument. 'file' required." | echohl None
      return
    endif
    call writefile(l:ctx['options']['list'], l:ctx['tmp_input'])
    let l:ctx['tmp_input'] = l:ctx['options']['file']
  elseif l:typ ==# 'list'
    if !has_key(l:ctx['options'], 'list')
      echohl ErrorMsg | echo "invalid argument. 'list' required." | echohl None
      return
    endif
    if type(l:ctx['options']['list']) != type([])
      echohl ErrorMsg | echo "invalid argument 'list'." | echohl None
      return
    endif
    let l:ctx['tmp_input'] = tempname()
    call writefile(l:ctx['options']['list'], l:ctx['tmp_input'])
  else
    echohl ErrorMsg | echo 'unsupported type' | echohl None
    return
  endif
  let l:ctx['tmp_result'] = tempname()
  let l:fz_command = get(l:ctx['options'], 'fz_command', g:fz_command)
  let l:fz_options = s:get_fzcmd_options(l:ctx)
  if has_key(l:ctx, 'tmp_input')
    if s:is_win
      let l:cmd = printf('%s %s "%s%s <%s >%s"', &shell, &shellcmdflag, l:fz_command, l:fz_options, l:ctx['tmp_input'], l:ctx['tmp_result'])
    else
      let l:cmd = [&shell, &shellcmdflag, printf('%s%s > %s < %s', l:fz_command, l:fz_options, l:ctx['tmp_result'], l:ctx['tmp_input'])]
    endif
  else
    let l:cmd = [&shell, &shellcmdflag, printf('%s%s > %s', l:fz_command, l:fz_options, l:ctx['tmp_result'])]
  endif
  botright new
  let l:ctx['buf'] = bufnr('%')
  if s:is_nvim
    call termopen(l:cmd, {'on_exit': function('s:exit_cb', [l:ctx]), 'cwd': l:ctx['basepath']}) | startinsert
  else
    call term_start(l:cmd, {'term_name': 'Fz', 'curwin': l:ctx['buf'], 'exit_cb': function('s:exit_cb', [l:ctx]), 'tty_type': 'conpty', 'cwd': l:ctx['basepath']})
  endif
endfunction
