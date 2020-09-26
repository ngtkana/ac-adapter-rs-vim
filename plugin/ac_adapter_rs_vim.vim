function! g:ac_adapter_rs_vim#Fire(libname) abort
  " procon-bundler さんを召喚します。
  let command = "procon-bundler --repo " . g:ac_adapter_rs_vim#repo . " --name " . a:libname
  let result = system(command)

  " エラー処理をします。
  if v:shell_error
    echo "procon-bundler さんのえらーです。"
    echo l:result
    abort
  endif

  " 集めた行をバッファに書き込みます。
  for line in split(l:result, '\n')
    call append(line('.'), l:line)
  endfor
endfunction
