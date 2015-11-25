let s:sample_mail = 'sample_mail'

function! TestParseHeaders()
    let l:result = mail#get_headers(s:sample_mail)
    call VUAssertEquals(l:result['subject'], 'Re: This is our response')
    call VUAssertEquals(l:result['mime-version'], '1.0')
endfunction

function! TestSplitRecipients()
    let l:normal = 'To: Pepito de los Palotes <pepito.palotes@gmail.com>'
    let l:normal_expected = [{
                \ 'name': 'Pepito de los Palotes',
                \ 'address': 'pepito.palotes@gmail.com'
                \ }]
    call VUAssertEquals(mail#split_recipients(l:normal), l:normal_expected)

    let l:quoted = 'From: "Juan Manches" <juanmanches@gmail.com>'
    let l:quoted_expected = [{
                \ 'name': 'Juan Manches',
                \ 'address': 'juanmanches@gmail.com'
                \ }]
    call VUAssertEquals(mail#split_recipients(l:quoted), l:quoted_expected)

    let l:mixed = 'From: "Juan Manches" <juanmanches@gmail.com>, Pepito de los Palotes <pepito.palotes@gmail.com>, "John Smith" <smashjohn@gmail.com>'
    let l:mixed_expected = [
                \ { 'name': 'Juan Manches', 'address': 'juanmanches@gmail.com' },
                \ { 'name': 'Pepito de los Palotes', 'address': 'pepito.palotes@gmail.com' },
                \ { 'name': 'John Smith', 'address': 'smashjohn@gmail.com' }
                \ ]
    call VUAssertEquals(mail#split_recipients(l:quoted), l:quoted_expected)
endfunction

function! TestStripHeader()
    let l:content_type = 'multipart/alternative; boundary="001a11c36780a5823d051ae6d1cd" '
    let l:content_type_expected = { 'misc': ['multipart/alternative'], 'boundary': '001a11c36780a5823d051ae6d1cd' }
    call VUAssertEquals(mail#strip_header(l:content_type), l:content_type_expected)

    let l:content_type_2 = 'multipart/alternative; boundary="----=_Part_103_790153692.1448382644499"'
    let l:content_type_2_expected = { 'misc': ['multipart/alternative'], 'boundary': '----=_Part_103_790153692.1448382644499' }
    call VUAssertEquals(mail#strip_header(l:content_type_2), l:content_type_2_expected)

    let l:to = '"John Smith" <smashjohn@gmail.com>, Robert Drop Table <bobby.tables@gmail.com>'
    let l:to_expected = '"John Smith" <smashjohn@gmail.com>, Robert Drop Table <bobby.tables@gmail.com>'
    call VUAssertEquals(mail#strip_header(l:to), l:to_expected)
endfunction

function! TestGetParts()
    let l:parts = mail#get_parts(s:sample_mail)
    call VUAssertEquals(len(l:parts), 2)
endfunction

function! TestGetHeadersLines()
    let l:mail = [
                \ 'Subject: Re: This is our response',
                \ 'From: Boba Fett <boba.fett@gmail.com>',
                \ 'To: Pepito de los Palotes <pepito.palotes@gmail.com>',
                \ 'Content-Type: multipart/alternative;',
                \ '     boundary=047d7b41cdd6fb0c5d0525533202',
                \ '',
                \ 'This is the mail',
                \ 'With multiple lines and all'
                \ ]
    let l:mail_expected = [
                \ 'Subject: Re: This is our response',
                \ 'From: Boba Fett <boba.fett@gmail.com>',
                \ 'To: Pepito de los Palotes <pepito.palotes@gmail.com>',
                \ 'Content-Type: multipart/alternative; boundary=047d7b41cdd6fb0c5d0525533202'
                \ ]
    call VUAssertEquals(mail#get_headers_lines(l:mail), l:mail_expected)
endfunction

function! TestParsePartHeaders()
    " function! mail#get_part_headers(part)
endfunction

