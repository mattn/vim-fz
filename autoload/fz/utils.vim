function! fz#utils#uniq(list) abort
  let l:result = []
  for l:item in a:list
    if index(l:result, l:item) == -1
      call add(l:result, l:item)
    endif
  endfor
  return l:result
endfunction
