function! mail#get_headers(filename)
    let lines = readfile(expand(a:filename))
    let headers_lines = []
    for line in lines
        if line =~ '^$'
            break
        elseif line =~ '\M^\s\+'
            let headers_lines[len(headers_lines) - 1] .= substitute(line, '\M^\s\+', ' ', '')
        else
            call add(headers_lines, line)
        endif
    endfor

    let headers = {}
    for header_line in headers_lines
        let key_value = split(header_line, ':')
        let key = substitute(tolower(key_value[0]), '\M\s', '', 'g')
        call remove(key_value, 0)
        let value = substitute(join(key_value, ''), '\M^\s\+', '', '')
        if !has_key(headers, key)
            let headers[key] = value
        else
            let headers[key] .= ';'.value
        endif
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

function! mail#split_recipients(text)
    " Ensure there is no "To: "
    let l:text = a:text
    let l:to_list = split(a:text, ':')
    if len(l:to_list) > 1
        let l:text = l:to_list[1]
    endif
    let l:recipients = []
    let l:items = split(l:text, ',')
    for l:item in l:items
        let l:address = matchstr(l:item, '\m<\zs.*\ze>')
        if l:address =~ '^$'
            let l:address = l:item
            let l:name = split(l:address, '@')[0]
        else
            let l:name = matchstr(l:item, '\m.*\ze<.*>')
        endif
        call add(l:recipients, {'name': l:name, 'address': l:address})
    endfor
    return l:recipients
endfunction

function! mail#get_parts(filename)
    let l:headers = mail#get_headers(a:filename)
    let l:boundary = mail#get_boundary(l:headers)
    let l:lines = readfile(expand(a:filename))
    " Erase headers and first boundary
    for l:line in l:lines
        call remove(l:lines, 0)
        if l:line =~ '\m^--'.l:boundary.'$'
            break
        endif
    endfor
    let l:list = []
    let l:part = []
    for l:line in l:lines
        if l:line =~ '\m^--'.l:boundary
            call add(l:list, l:part)
            let l:part = []
            if l:line =~ '^--'.l:boundary.'--$'
                break
            endif
        else
            call add(l:part, l:line)
        endif
    endfor
    return l:list
endfunction
