function! g:ac_adapter_rs_vim#Fire(libname) abort
  " procon-bundler さんを召喚します。
  let command = "procon-bundler find " . g:ac_adapter_rs_vim#workspace . " " . a:libname
  let result = system(command)

  " エラー処理をします。
  if v:shell_error
    echo "ERROR: from procon-bundler"
    echo l:result
  endif

  " 集めた行をバッファに書き込みます。
  call append(line('.'), split(l:result, '\n'))
endfunction
