function! mail#get_headers(filename)
    let lines = readfile(expand(a:filename))
    let headers_lines = []
    for line in lines
        if line =~ '^$'
            break
        elseif line =~ '\M^\s\+'
            let headers_lines[len(headers_lines) - 1] .= line
        else
            call add(headers_lines, line)
        endif
    endfor

    let headers = {}
    for header_line in headers_lines
        let key_value = split(header_line, ':')
        let key = substitute(tolower(key_value[0]), '\M\s', '', 'g')
        call remove(key_value, 0)
        let headers[key] = mail#strip_header(substitute(join(key_value, ''), '\M^\s\+', '', ''))
    endfor
    return headers
endfunction

function! mail#strip_header(header)
    let parts = split(a:header, ';')
    if len(parts) == 1
        return a:header
    endif
    let dict = {'misc': []}
    for part in parts
        if part =~ '='
            let key_value = split(part, '=\zs', 1)
            let key = mail#trim(key_value[0])
            call remove(key_value, 0)
            let value = mail#trim(join(key_value, ''))
            let dict[key] = value
        else
            call add(dict['misc'], part)
        endif
    endfor
    return dict
endfunction

function! mail#trim(string)
    let string = a:string
    let string = substitute(string, '\M^\s\+', '', '')
    let string = substitute(string, '\M\s\+$', '', '')
    let string = substitute(string, '\M^=', '', '')
    let string = substitute(string, '\M=$', '', '')
    let string = substitute(string, '\M^"', '', '')
    let string = substitute(string, '\M"$', '', '')
    return string
endfunction
