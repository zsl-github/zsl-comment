" zsl_log.vim
" Version: 1.0

if exists("g:zsl_loaded_log") || &cp || v:version < 700
    finish
endif
let g:zsl_loaded_log = 1

"基础函数
function AddLog()
    let zslinde = max([indent(line(".")), indent(line(".")+1)])
    let log = 'android.util.Log.e("zhangshuli|exchange", "");'
    let curfile = expand("%:t:r")
    let logline = line(".") + 1
    let log = substitute(log, "exchange", curfile."|".logline, '')
    call append(line("."), log)
    execute (line(".")+1)." normal =="
    call cursor(".", stridx(getline("."), ";")-1)
endfunction

"更改java默认注释符号
autocmd FileType java set commentstring=/*%s*/

"获取当前文件的注释标签
function! s:surroundings() abort
  return split(substitute(substitute(
        \ get(b:, 'commentary_format', &commentstring)
        \ ,'\S\zs%s',' %s','') ,'%s\ze\S', '%s ', ''), '%s', 1)
endfunction

"添加注释行首跟行尾
function! s:AddAnnotion(type, linenum)
  let [l, r] = s:surroundings()
  let time = "2016-01-01"
  let anno = "modify by zhangshui time begin"
  let anno = l.anno.r
  if exists("*strftime")
    let time = strftime("%Y-%m-%d")
  endif
  let anno = substitute(anno, "time", time, '')

  if a:type ==0
    call append(a:linenum, anno)
  elseif a:type == 1
    call append(a:linenum, substitute(anno, "begin", "end", ''))
  endif
  "光标会自动跳转到操作行
  execute (a:linenum+1)." normal =="
endfunction

"普通模式下基础函数
function AnnotationN()
  call s:AddAnnotion(0, line("."))
  call s:AddAnnotion(1, line("."))
endfunction

"可视模式下基础函数
function! s:AnnotationV()
  call s:go(line("'<"), line("'>"))
  call s:AddAnnotion(0, line("'<")-1)
  call s:AddAnnotion(1, line("'>"))
endfunction

"注释掉选中文本
function! s:go(type,...) abort
  if a:0
    let [lnum1, lnum2] = [a:type, a:1]
  else
    let [lnum1, lnum2] = [line("'["), line("']")]
  endif

  let [l, r] = s:surroundings()
  let uncomment = 2
  for lnum in range(lnum1,lnum2)
    let line = matchstr(getline(lnum),'\S.*\s\@<!')
    if line != '' && (stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
      let uncomment = 0
    endif
  endfor

  for lnum in range(lnum1,lnum2)
    let line = getline(lnum)
    if strlen(r) > 2 && l.r !~# '\\'
      let line = substitute(line,
            \'\M'.r[0:-2].'\zs\d\*\ze'.r[-1:-1].'\|'.l[0].'\zs\d\*\ze'.l[1:-1],
            \'\=substitute(submatch(0)+1-uncomment,"^0$\\|^-\\d*$","","")','g')
    endif
    if uncomment
      let line = substitute(line,'\S.*\s\@<!','\=submatch(0)[strlen(l):-strlen(r)-1]','')
    else
      let line = substitute(line,'^\%('.matchstr(getline(lnum1),'^\s*').'\|\s*\)\zs.*\S\@<=','\=l.submatch(0).r','')
    endif
    call setline(lnum,line)
  endfor
  silent doautocmd User CommentaryPost
endfunction
xnoremap <silent> <Plug>AnnotationV     :<C-U>call <SID>AnnotationV()<CR>
