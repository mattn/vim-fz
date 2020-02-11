function! s:uniq(list) abort
  let l:result = []
  for l:item in a:list
    if index(l:result, l:item) == -1
      call add(l:result, l:item)
    endif
  endfor
  return l:result
endfunction

function! fz#utils#mru() abort
  let l:files = map(range(bufnr('$'), 1, -1), 'bufname(v:val)') + copy(v:oldfiles)
  let l:files = filter(map(l:files, 'expand(v:val)'), 'filereadable(v:val)')
  return s:uniq(map(l:files, 'fnamemodify(v:val, ":~:.:gs!\\!/!")'))
endfunction
