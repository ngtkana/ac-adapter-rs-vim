let s:rust_tab = "    "
let s:ac_adapter_rs_crate_path = expand($HOME) . "/github/ngtkana/procon/ac-adapter-rs"

function! s:contains_doc_comment(line) abort
  return match(a:line, "///") != -1 || match(a:line, "//!") != -1
endfunction

function! s:contains_attribute_warn_missing_docs(line) abort
  return match(a:line, "warn(missing_docs)") != -1
endfunction

function! s:contains_attribute_warn_missing_doc_code_examples(line) abort
  return match(a:line, "warn(missing_doc_code_examples)") != -1
endfunction

" rust-doc 向けの行を見つけます。
function! s:is_documentive(line) abort
  return s:contains_doc_comment(a:line)
  \ || s:contains_attribute_warn_missing_docs(a:line)
  \ || s:contains_attribute_warn_missing_doc_code_examples(a:line)
endfunction

" 空行判定です。
function! s:is_empty_line(line) abort
  return a:line == ""
endfunction

" test をみつけます。
function! s:contains_cfg_test(line) abort
  return match(a:line, "cfg(test)") != -1
endfunction

function! s:construct_filepath_from_libname(libname) abort
  let l:lib_rs_relative_path = "src/lib.rs"

  return s:ac_adapter_rs_crate_path
  \ . "/"
  \ . a:libname
  \ . "/"
  \ . l:lib_rs_relative_path
endfunction

" # parameters
" ident: string snake_case または chain-case の文字列です。
"
" # returns
" snake_case に変換します。
function! s:to_snake_case(ident) abort
    return split(a:ident, "-")->join("_")
endfunction

" # parameters
" lines: [string]
" ファイルのすべての行です。
"
" # returns
"
" 必要な行だけを抽出します。
"
function! s:collect_essential_lines(lines) abort
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
" lines: [string] 必要な行の内容のリスト
" snake_case_libname: snake_case に変換されたライブラリ名
"
" # returns
" - mod で包みます。
" - mod のお名前は引数で与えられます。
" - さらに #[allow(dead_code)] をつけます。
"
function! s:throw_into_mod_libname(lines, snake_case_libname) abort
  " まずインデントです。
  let l:mapped_lines = map(a:lines, {_, line -> empty(line) ? "" : s:rust_tab . line})

  return
  \ ["#[allow(dead_code)]"]
  \ + ["mod " . a:snake_case_libname . " {"]
  \ + l:mapped_lines
  \ + ["}"]
endfunction

" # parameters
" lines: [string] ソースコードです。すでに mod に包まれているとします。
" libname: string ユーザーに指定されたライブラリ名
"
" # returns
" fold marker とライブラリ名をつけます。
"
function! s:add_fold_markers(lines, libname) abort
  let l:head = "// " . a:libname . " {{{"
  let l:tail = "// }}}"

  return [l:head] + a:lines + [l:tail]
endfunction

" メインです。
"
" # parameters
" libname: ライブラリのお名前
"
function! g:ac_adapter_rs_vim#Fire(libname) abort
  " chain-case はコンパイルできないので snake_case に変換です。
  let l:snake_case_libname = s:to_snake_case(a:libname)

  " ファイルが存在しなければ即リターンです。
  let l:filename = s:construct_filepath_from_libname(a:libname)
  if !filereadable(l:filename)
    echo "ERROR: ac-adapter-rs-vim aborted failing a file"
    return
  endif

  let lines = [] " ペーストすべき行を集めていきます。
  " ファイルのすべての行を走査してリストに集めます。
  for l:line in readfile(l:filename)
    let lines += [l:line]
  endfor

  " 必要な行だけを抽出です。
  let l:lines = s:collect_essential_lines(l:lines)

  " mod snake_case_libname {} に包みます。
  let l:lines = s:throw_into_mod_libname(l:lines, l:snake_case_libname)

  " fold marker に包みます。
  let l:lines = s:add_fold_markers(l:lines, a:libname)

  " 集めた行をバッファに書き込みます。
  :call append(line('.') - 1, l:lines)
endfunction
