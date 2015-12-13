function! mail#parse_headers(lines)
    let l:headers = {}
    let l:headers_lines = mail#get_headers_lines(a:lines)
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
    call map(l:headers, 'mail#strip_header(v:key,v:val)')
    return l:headers
endfunction

function! mail#get_headers_lines(lines)
    let l:lines = []
    if type(a:lines) == type("")
        let l:lines = split(a:lines, '\n')
    else
        let l:lines = a:lines
    endif
    let l:headers_lines = []
    for l:line in l:lines
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

function! mail#strip_header(key, header)
    if a:key == 'content-type'
        return mail#strip_key_value(a:header)
    elseif a:key == 'from' || a:key == 'to' || a:key == 'cc' || a:key == 'bcc'
        return mail#strip_recipients(a:header)
    endif
    return a:header
endfunction

function! mail#strip_key_value(header)
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
    let l:quoted = 0
    let l:recipients = []
    let l:recipient = ''
    for l:index in range(len(a:text))
        let l:char = a:text[l:index]
        if l:char == '"'
            let l:quoted = 1 - l:quoted
        elseif l:char == ',' && !l:quoted
            call add(l:recipients, l:recipient)
            let l:quoted = 0 " should be 0 already but just in case
            let l:recipient = ''
        else
            let l:recipient .= l:char
        endif
    endfor
    call add(l:recipients, l:recipient)
    return l:recipients
endfunction

function! mail#strip_recipients(text)
    " Ensure there is no "To: "
    let l:text = a:text
    let l:to_list = split(a:text, '\m:\s*')
    if len(l:to_list) > 1
        call remove(l:to_list, 0)
        let l:text = join(l:to_list, ': ')
    endif
    let l:recipients = []
    let l:items = mail#split_recipients(l:text)
    for l:item in l:items
        let l:address = matchstr(l:item, '\m<\zs\S*\ze>')
        if l:address =~ '\m^$'
            let l:address = l:item
            let l:name = split(l:address, '@')[0]
        else
            let l:name = matchstr(l:item, '\m^\s*"\?\zs.*\ze<.*>')
        endif
        let l:name = substitute(l:name, '\m^"\?\s*', '', '')
        let l:name = substitute(l:name, '\m"\?\s*$', '', '')
        let l:address = substitute(l:address, '\m^"\?\s*', '', '')
        let l:address = substitute(l:address, '\m"\?\s*$', '', '')
        call add(l:recipients, {'name': l:name, 'address': l:address})
    endfor
    return l:recipients
endfunction

function! mail#join_recipients(recipients)
    let l:line = ''
    let l:first = 1
    for l:recipient in a:recipients
        if l:first
            let l:first = 0
        else
            let l:line .= ', '
        endif
        let l:line .= l:recipient['name'].' <'.l:recipient['address'].'>'
    endfor
    return l:line
endfunction

function! mail#get_parts(lines)
    let l:lines = a:lines
    let l:headers = mail#parse_headers(l:lines)
    let l:boundary = l:headers['content-type']['boundary']
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

function! mail#get_body(lines)
    let l:body = []
    let l:is_body = 0
    for l:line in a:lines
        if l:is_body
            call add(l:body, l:line)
        elseif l:line =~ '\m^$'
            let l:is_body = 1
        endif
    endfor
    return l:body
endfunction

function! mail#get_plain_text(lines)
    let l:headers = mail#parse_headers(a:lines)
    if !has_key(l:headers, 'content-type')
        return mail#get_body(a:lines)
    endif
    let l:content_type = l:headers['content-type']['misc'][0]
    if l:content_type == 'text/plain'
        return mail#get_plain_text_text_plain(a:lines)
    elseif l:content_type == 'multipart/alternative'
        return mail#get_plain_text_multipart_alternative(mail#get_parts(a:lines))
    elseif l:content_type == 'multipart/mixed'
        return mail#get_plain_text_multipart_mixed(mail#get_parts(a:lines))
    elseif l:content_type == 'multipart/related'
        return mail#get_plain_text_multipart_related(mail#get_parts(a:lines))
    else
        return 'mail#get_plain_text unknown content type'
    endif
    return 'mail#get_plain_text should not return this'
endfunction

function! mail#get_plain_text_text_plain(lines)
    let l:headers = mail#parse_headers(a:lines)
    if !has_key(l:headers, 'content-transfer-encoding')
        return mail#get_body(a:lines)
    endif
    let l:content_transfer_encoding = l:headers['content-transfer-encoding']['misc'][0]
    if l:content_transfer_encoding == 'quoted-printable' || l:content_transfer_encoding == 'q'
        return mail#decode_lines(mail#get_body(a:lines), 'qp')
    elseif l:content_transfer_encoding == 'base64' || l:content_transfer_encoding == 'b64'
        return mail#decode_lines(mail#get_body(a:lines), 'b64')
    endif
endfunction

function! mail#get_plain_text_multipart_mixed(parts)
    return 'TODO: mail#get_plain_text_multipart_mixed'
endfunction

function! mail#get_plain_text_multipart_alternative(parts)
    for l:part in a:parts
        let l:headers = mail#parse_headers(l:part)
        if !has_key(l:headers, 'content-type')
            return 'mail#get_plain_text_multipart_alternative should not return this'
            return mail#get_body(l:part)
        endif
        let l:content_type = l:headers['content-type']['misc'][0]
        if l:content_type == 'text/plain'
            return mail#get_plain_text_text_plain(l:part)
        endif
    endfor
    return 'mail#get_plain_text_multipart_alternative should not return this'
endfunction

function! mail#get_plain_text_multipart_related(parts)
    return 'TODO: mail#get_plain_text_multipart_related'
endfunction

function! mail#decode_lines(lines, format)
    let l:filename = tempname()
    call writefile(a:lines, l:filename)
    call system('recode /'.a:format.' '.l:filename)
    return readfile(l:filename)
endfunction
