function! mail#get_headers(filename)
    let l:lines = readfile(expand(a:filename))
    let l:headers_lines = mail#get_headers_lines(lines)

    let l:headers = {}
    for l:header_line in l:headers_lines
        let l:key_value = split(l:header_line, '\m:\s*')
        let l:key = substitute(tolower(l:key_value[0]), '\M\s', '', 'g')
        call remove(l:key_value, 0)
        let l:value = substitute(join(l:key_value, ': '), '\M^\s\+', '', '')
        if !has_key(l:headers, l:key)
            let l:headers[l:key] = l:value
        else
            let l:headers[l:key] .= ';'.l:value
        endif
    endfor
    if has_key(l:headers, 'content-type')
        let l:headers['content-type'] = mail#strip_header(l:headers['content-type'])
    endif
    if has_key(l:headers, 'from')
        let l:headers['from'] = mail#split_recipients(l:headers['from'])
    endif
    if has_key(l:headers, 'to')
        let l:headers['to'] = mail#split_recipients(l:headers['to'])
    endif
    if has_key(l:headers, 'cc')
        let l:headers['cc'] = mail#split_recipients(l:headers['cc'])
    endif
    if has_key(l:headers, 'bcc')
        let l:headers['bcc'] = mail#split_recipients(l:headers['bcc'])
    endif
    return l:headers
endfunction

function! mail#get_headers_lines(lines)
    let l:headers_lines = []
    for l:line in a:lines
        if l:line =~ '^$'
            break
        elseif l:line =~ '\M^\s\+'
            let headers_lines[len(l:headers_lines) - 1] .= substitute(l:line, '\M^\s\+', ' ', '')
        else
            call add(l:headers_lines, l:line)
        endif
    endfor
    return l:headers_lines
endfunction

function! mail#strip_header(header)
    let l:parts = split(a:header, '\m;\s*')
    if len(l:parts) == 1
        return a:header
    endif
    let l:dict = {'misc': []}
    for l:part in l:parts
        if l:part =~ '='
            let l:key_value = split(l:part, '=')
            let l:key = l:key_value[0]
            call remove(l:key_value, 0)
            let l:value = substitute(matchstr(join(l:key_value, '='), '\m^\s*"\?\zs\S\+\ze"\?'), '"$', '', '')
            let l:dict[l:key] = l:value
        else
            call add(l:dict['misc'], l:part)
        endif
    endfor
    return l:dict
endfunction

function! mail#split_recipients(text)
    " Ensure there is no "To: "
    let l:text = a:text
    let l:to_list = split(a:text, '\m:\s*')
    if len(l:to_list) > 1
        call remove(l:to_list, 0)
        let l:text = join(l:to_list, ': ')
    endif
    let l:recipients = []
    let l:items = split(l:text, ',')
    for l:item in l:items
        let l:address = matchstr(l:item, '\m<\zs\S*\ze>')
        if l:address =~ '\m^$'
            let l:address = l:item
            let l:name = split(l:address, '@')[0]
        else
            let l:name = substitute(matchstr(l:item, '\m^\s*"\?\zs.*\ze<.*>'), '"\?\s*$', '', '')
        endif
        call add(l:recipients, {'name': l:name, 'address': l:address})
    endfor
    return l:recipients
endfunction

function! mail#get_parts(filename)
    let l:headers = mail#get_headers(a:filename)
    let l:boundary = l:headers['content-type']['boundary']
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

function! mail#get_part_headers(part)
    let l:headers_lines = mail#get_headers_lines(a:part)
    let l:headers = {}
    for l:line in l:headers_lines
        let l:arr = split(l:line, '\m:\s*')
        let l:key = tolower(l:arr[0])
        call remove(l:arr, 0)
        let l:headers[l:key] = join(l:arr, ': ')
    endfor
    return l:headers
endfunction
