bits 16
[org 0x0000]

start_program:          ;interrupt for searching and loading a PROGRAM from the disk

    cmp byte [drive_number], 0x80
    jb start_program_flp

    int 0x20            ;expects the filename to search in SI
    ret
start_program_flp:
    mov ah, 0x08
    int 0x24
    ret
read_file:
    mov si, [argument]
    call clear_buffer
    call parse_arg

    cmp byte [drive_number], 0x80
    jb read_file_flp

    mov si, read_buffer
    mov ah, 0x01        ;expects string in SI
    int 0x22
    ret
read_file_flp:
    cmp byte [fat8], 1
    je read_file_flp8

    mov si, read_buffer
    mov ah, 0x02
    int 0x24
    ret
read_file_flp8:
    mov si, read_buffer
    mov ah, 0x01
    int 0x30
    ret
read_string:
    xor cx, cx
    mov di, arg_buffer
read_string_loop:
    xor ah, ah
    int 0x16
    cmp al, 0x0d
    je read_string_done
    cmp al, 0x08
    je rs_handle_backspace
    cmp al, 'q'
    je quit_read_string
    cmp cx, 12
    jge read_string_loop
    stosb               ;store string in di
    mov ah, 0x0e
    mov bl, 0x02
    int 0x10
    inc cx
    jmp read_string_loop
rs_handle_backspace:
    cmp cx, 0
    je read_string_loop
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08    ;Backspace
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_string_loop
quit_read_string:
    mov ax, kernel_seg
    mov es, ax
    call print_newline
    pop ax
    jmp shell
read_string_done:
    ret
write_file:
    ;mov si, read_prompt
    ;call print_string_white
    ;call read_string
    call clear_buffer
    call parse_arg
    mov si, read_buffer

    cmp byte [drive_number], 0x80
    jb write_file_flp

    mov ah, 0x02
    int 0x22
    ret
write_file_flp:
    cmp byte [fat8], 1
    je write_file_flp8

    mov ah, 0x03
    int 0x24
    ret
write_file_flp8:
    mov ah, 0x02
    int 0x30
    ret
ls_dir:
    mov ah, 0x03
    int 0x22
    ret
rename_file:
    ;mov si, read_prompt
    ;call print_string_white
    ;call read_string
    call clear_buffer
    call parse_arg
    mov si, read_buffer
    mov di, file_kernel_bin
    call compare_str
    jc invalid_filename

    cmp byte [drive_number], 0x80
    jb rename_file_flp

    mov ah, 0x04
    int 0x22
    ret
rename_file_flp:
    mov ah, 0x05
    int 0x24
    ret
invalid_filename:
    call print_newline
    mov si, invalid_rename
    call print_string_red
    call print_newline
    ret
delete_file:
    ;mov si, read_prompt
    ;call print_string_white
    ;call read_string
    call clear_buffer
    call parse_arg
    mov si, read_buffer
    mov di, file_kernel_bin
    call compare_str
    jc invalid_filename
    
    cmp byte [drive_number], 0x80
    jb delete_file_flp

    mov ah, 0x05
    int 0x22
    ret
delete_file_flp:
    cmp byte [fat8], 1
    je delete_file_flp8

    mov ah, 0x04
    int 0x24
    ret
delete_file_flp8:
    mov ah, 0x03
    int 0x30
    ret
get_bpb_data:
    mov al, [0x7e00]
    mov [drive_number], 0x80
    mov al, [0x7e00+1]
    mov [sec_per_cluster], byte 4
    mov ax, [0x7e00+2]
    mov [root_entries], word 512
    mov ax, [0x7e00+4]
    mov [data_start_sec], word 100
    mov [fat_size], word 32
    mov [reserved_sectors], word 4
    mov [root_start_sec], word 68
    mov [root_size], word 32
    ret
cd_drives:
    ;mov si, change_drive_str
    ;call print_string_white
    ;call read_string
    call clear_buffer
    call parse_arg
    mov si, read_buffer
    mov ah, 0x06
    int 0x22
    ret

print_working_dir:
    mov dl, 0x80
    mov bh, 0x43
    mov cx, 5
.loop:
    cmp [drive_number], dl
    je pwd
    inc dl
    inc bh
    loop .loop
pwd:
    mov ah, 0x0e
    mov al, bh
    mov bl, 0x0b
    int 0x10
    mov al, ':'
    int 0x10
    mov al, '/'
    int 0x10
    call print_newline
    ret
clear_buffer:
    mov al, ' '
    mov di, read_buffer
    mov cx, 11
    rep stosb
    ret
parse_arg:
    xor cx, cx
    mov si, [argument]      ;pointer to argument (filename)
    mov di, read_buffer
    mov ah, 0x08            ;filename in SI, buffer in DI, CX = 0
    int 0x22
    ret
; parse_arg_loop:
;     mov al, [si]
;     cmp al, 0       ;check for 0-terminator
;     je add_spaces     ;invalid string
;     cmp al, '.'     ;chech for extension
;     je add_spaces
;     stosb           ;stores al in ES:DI
;     inc si
;     inc cx
;     cmp cx, 8
;     jnz parse_arg_loop
; add_spaces:
;     cmp cx, 8
;     je parse_ext
;     mov al, ' '     ;fill the rest of the name with spaces to achieve 8.3 format
;     stosb
;     inc cx
;     jmp add_spaces
; parse_ext:
;     cmp byte [si], '.'
;     jne parse_ext_loop
;     inc si
; parse_ext_loop:
;     xor cx, cx
; .loop:
;     mov al, [si]
;     cmp al, 0
;     je add_spaces_ext
;     stosb
;     inc si
;     inc cx
;     cmp cx, 3
;     jb .loop
; add_spaces_ext:
;     cmp cx, 3
;     je done_parse
;     mov al, ' '
;     stosb
;     inc cx
;     jmp add_spaces_ext
; done_parse:
;     ret

search_for_program:
    mov di, command_buffer
    mov cx, 11
.loop:
    cmp byte [di], 0
    jne .next_char
    mov byte [di], 0x20      ;space
.next_char:
    inc di
    loop .loop

    mov di, command_buffer+8
    mov al, 'B'
    stosb
    mov al, 'I'
    stosb
    mov al, 'N'
    stosb
    
    mov si, command_buffer
    mov di, read_buffer
    mov cx, 11
    rep movsb
    mov si, read_buffer
    ; call print_buffer
    ; mov di, file_kernel_bin
    ; call compare_str
    ; jc exec_kernel

    cmp byte [drive_number], 0x80
    jb start_program_flp

    int 0x20
    ret
exec_kernel:
    mov si, kernel_exec_err
    call print_string_red
    call print_newline
    ret
print_buffer:
    mov cx, 11
    mov ah, 0x0e
.loop:
    lodsb
    int 0x10
    loop .loop
    ret

change_dir:
    call clear_buffer
    call parse_arg

    cmp byte [drive_number], 0x80
    jb change_dir_flp

    mov si, read_buffer
    mov ah, 0x0a
    int 0x22
    ret
change_dir_flp:
    mov si, read_buffer
    mov ah, 0x09
    int 0x24
    ret

make_dir:
    call clear_buffer
    call parse_arg

    mov si, read_buffer
    mov ah, 0x0a
    int 0x24
    ret

delete_dir:
    call clear_buffer
    call parse_arg

    mov si, read_buffer
    mov ah, 0x0b
    int 0x24
    ret