let s:rust_tab = "    "

function! s:contains_doc_comment(line)
  return match(a:line, "///") != -1 || match(a:line, "//!") != -1
endfunction

function! s:contains_attribute_warn_missing_docs(line)
  return match(a:line, "warn(missing_docs)") != -1
endfunction

function! s:contains_attribute_warn_missing_doc_code_examples(line)
  return match(a:line, "warn(missing_doc_code_examples)") != -1
endfunction

" rust-doc 向けの行を見つけます。
function! s:is_documentive(line)
  return s:contains_doc_comment(a:line)
  \ || s:contains_attribute_warn_missing_docs(a:line)
  \ || s:contains_attribute_warn_missing_doc_code_examples(a:line)
endfunction

" 空行判定です。
function! s:is_empty_line(line)
  return a:line == ""
endfunction

" test をみつけます。
function! s:contains_cfg_test(line)
  return match(a:line, "cfg(test)") != -1
endfunction

function! s:construct_filepath_from_libname(libname)
  let l:ac_adapter_rs_path = expand($HOME) . "/github/ac-adapter-rs"
  let l:lib_rs_relative_path = "src/lib.rs"

  return l:ac_adapter_rs_path
  \ . "/"
  \ . a:libname
  \ . "/"
  \ . l:lib_rs_relative_path
endfunction

" # parameters
"
" lines: [string]
" ファイルのすべての行です。
"
" # returns
"
" 必要な行だけを抽出します。
"
function! s:collect_essential_lines(lines)
  let ret = []
  let found_the_first_line = v:false " 読み飛ばさない行を発見したら true です。

  for l:line in a:lines
    " テストに到達したら終了です。
    if s:contains_cfg_test(l:line)
      break
    endif

    " rust-doc 関連の行は読み飛ばします。
    if s:is_documentive(l:line)
      continue
    endif

    " ファイルの前の方に空行があれば読み飛ばします。
    if ! l:found_the_first_line && s:is_empty_line(l:line)
      continue
    endif

    " やっと読むべき行を見つけました。
    let l:found_the_first_line = v:true

    let ret += [l:line]
  endfor

  " 末尾空行を削除です。
  while !empty(ret) && ret[-1] == ""
    unlet ret[len(ret)-1]
  endwhile

  return ret
endfunction

" # parameters
"
" lines: [string]
" 必要な行の内容のリスト
"
" libname: string
" ユーザーに指定されたライブラリ名
"
" # returns
"
" こんな形にします。
" tab はスクリプトローカル変数で決めます。
"
" mod lib {
"     contents
" }
"
function! s:throw_into_mod_libname(lines, libname)
  let ret = ["mod " . a:libname . " {"]

  for l:line in a:lines
    " 空行以外を 1 段階インデントです。
    if l:line != ""
      let l:line = s:rust_tab . l:line
    endif
    let ret += [l:line]
  endfor

  let ret += ["}"]

  return ret
endfunction

" # parameters
"
" libname: ライブラリのお名前
"
" # effects
"
" なんかします。
"
function! g:ac_adapter_rs_vim#Fire(libname)
  " ファイルが存在しなければ即リターンです。
  let s:filename = s:construct_filepath_from_libname(a:libname)
  if !filereadable(s:filename)
    echo "ERROR: ac-adapter-rs-vim aborted failing a file"
    return
  endif

  let lines = [] " ペーストすべき行を集めていきます。
  " ファイルのすべての行を走査してリストに集めます。
  for l:line in readfile(s:filename)
    let lines += [l:line]
  endfor

  " 必要な行だけを抽出です。
  let l:lines = s:collect_essential_lines(l:lines)

  " mod libname {} に包みます。
  let l:lines = s:throw_into_mod_libname(l:lines, a:libname)

  " 集めた行をバッファに書き込みます。
  :call append('.', l:lines)
endfunction
