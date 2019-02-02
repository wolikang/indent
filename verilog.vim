" Language:    Verilog HDL
" Maintainer:  Kody He <kody.he@hotmail.com>
" Last Change: 
" URL:         http://www.cs.nthu.edu.tw/~cthuang/vim/indent/verilog.vim
"
" Credits:
"   Suggestions for improvement, bug reports by
"
" Buffer Variables:
"     b:verilog_indent_modules : indenting after the declaration
"                 of module blocks
"     b:verilog_indent_width   : indenting width
"     b:verilog_indent_verbose : verbose to each indenting
"

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetVerilogIndent()
setlocal indentkeys=0=always,0=initial,0=module,0=endmodule,0=function,0=endfunction,0=task,0=endtask
setlocal indentkeys+=0=begin,0=end,0=case,0=endcase
setlocal indentkeys+=0=assign,0=input,0=output,0=inout,0=wire,0=reg
setlocal indentkeys+==if,=else
setlocal indentkeys+=!^B,o,O,0)

" Only define the function once.
if exists("*GetVerilogIndent")
  finish
endif



let s:cpo_save = &cpo
set cpo&vim

function GetVerilogIndent()

    if exists('b:verilog_indent_width')
        let offset = b:verilog_indent_width
    else
        let offset = shiftwidth()
    endif
    if exists('b:verilog_indent_modules')
        let indent_modules = offset
    else
        let indent_module = 0
    endif

    " Find a non-black line above the current line.
    "let lnum = prevnonblank(v:lnum - 1)

    " At the start of the file use zero indent.
    "if lnum == 0
    "    return 0
    "endif

    let curr_line = getline(v:lnum)
    let last_line = getline(v:lnum - 1)
    let ind = indent(v:lnum - 1)

    " NOTE: By default, 'begin' and 'end' is never on the same line
    "       By default, 'case' and 'endcase' never supports nested usage
    let pat_com_pre_key     = '\m^\s*\<\(always\|initial\|module\|function\|task\)\>'
    let pat_com_module_pair = '\m^\s*\<\(module\|endmodule\)\>'
    let pat_com_func_pair   = '\m^\s*\<\(function\|endfunction\)\>'
    let pat_com_task_pair   = '\m^\s*\<\(task\|endtask\)\>'
    let pat_com_if_and_else = '\m\<if\>\s*(.*)[^;]*;\s*\<else\>\s\+[^;]*;'
    let pat_com_if_or_else  = '\m\<\(if\|else\)\>'
    let pat_com_pre_else    = '\m^\s*\<else\>'
    let pat_com_blank_line  = '\m^\s*\n'
    let pat_com_end         = '\m\<end\>'
    let pat_com_pre_end     = '\m^\s*\<end\>'
    let pat_com_begin       = '\m\<begin\>'
    let pat_com_pre_begin   = '\m^\s*\<begin\>'
    let pat_com_if          = '\m\<if\>'
    let pat_com_if_begin    = '\m\<if\>\s*\<begin\>'
    let pat_com_pre_case    = '\m^\s*\<case\>'
    let pat_com_pre_endcase = '\m^\s*\<endcase\>'
    let pat_com_pre_assign  = '\m^\s*\<assign\>'
    let pat_com_pre_input   = '\m^\s*\<input\>'
    let pat_com_pre_output  = '\m^\s*\<output\>'
    let pat_com_pre_inout   = '\m^\s*\<inout\>'
    let pat_com_pre_wire    = '\m^s\*\<wire\>'
    let pat_com_pre_reg     = '\m^s\*\<reg\>'

    " current line is preceded by 'module', 'function', 'task', and so on
    if curr_line =~ pat_com_module_pair ||
     \ curr_line =~ pat_com_func_pair   ||
     \ curr_line =~ pat_com_task_pair
        return 0
    endif
    " current line is preceded by 'begin'
    if curr_line =~ pat_com_pre_begin
        if v:lnum > 1
            return indent(v:lnum - 1)
        endif
    endif
    " current line is preceded by 'end', find the corresponding 'begin'
    if curr_line =~ pat_com_pre_end
        let begin_idx = -1
        let i = 1
        while i < v:lnum
            let line = getline(v:lnum - i)
            if begin_idx == -1
                if line =~ pat_com_begin
                    return indent(v:lnum - i)
                elseif line =~ pat_com_end
                    let begin_idx = begin_idx - 1
                endif
            else
                if line =~ pat_com_begin
                    let begin_idx = begin_idx + 1
                elseif line =~ pat_com_end
                    let begin_idx = begin_idx - 1
                endif
            endif
            let i = i + 1
        endwhile
    endif
    " current line is preceded by 'else', find the corresponding 'if'
    " Case 1:
    " if (xxx) begin
    "     if (xxx)
    "         xxx;
    " end
    " else 
    "     xxx;
    "
    " Case 2:
    " if (xxx)
    "     xxx;
    " else 
    "     xxx;
    if curr_line =~ pat_com_pre_else
        let begin_end_flag = 0      " no end, no begin
        let i = 1
        while i < v:lnum 
            let line = getline(v:lnum - i)
            if begin_end_flag == 0 
                if line =~ pat_com_end 
                    let begin_end_flag = 1
                elseif line =~ pat_com_if
                    return indent(v:lnum - i)
                endif
            else
                if line =~ pat_com_begin
                    if line =~ pat_com_if_begin
                        return indent(v:lnum - i)
                    else
                        let begin_end_flag = 0
                    endif
                endif
            endif
            let i = i + 1
        endwhile
    endif
    " current line is preceded by 'endcase'
    if curr_line =~ pat_com_pre_endcase
        for i in range(1, v:lnum - 1)
            let line = getline(v:lnum - i)
            if line =~ pat_com_pre_case
                return indent(v:lnum - i)
            endif
        endfor
    endif
    " current line is preceded by 'input', 'output', 'inout', 'wire', 'reg'
    " and so on
    if curr_line =~ pat_com_pre_input ||
     \ curr_inne =~ pat_com_pre_output ||
     \ curr_line =~ pat_com_pre_inout ||
     \ curr_line =~ pat_com_pre_wire ||
     \ curr_line =~ pat_com_pre_reg 
        return 0
    endif
    " current line is preceded by 'assign'
    if curr_line =~ pat_com_pre_assign
        reutrn 0
    endif
    " last line is composed of <Space>, <Tab>
    if last_line =~ pat_com_blank_line
        return 0
    endif
    " last line is preceded by 'begin'
    if last_line =~ pat_com_pre_begin
        return ind + offset
    endif
    " last line is preceded by 'module', 'always', 'function', 'task', and so on
    "if last_line =~ '\m^\s*\<\(always\|module\|function\|task\)\>'
    if last_line =~ pat_com_pre_key
        return ind + offset
    endif
    " last line just like: if (xx) xxx; else xxx;
    if last_line =~ pat_com_if_else
        return ind
    endif
    " last line like: if or else
    if last_line =~ pat_com_if_or_else
        return ind + offset
    endif
    " last line is preceded by 'case'
    if last_line =~ pat_com_pre_case
        return ind + offset
    endif

    return ind

endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:sw=2
