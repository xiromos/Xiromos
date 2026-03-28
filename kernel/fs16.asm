bits 16
[org 0x0000]

start_program:          ;interrupt for searching and loading a PROGRAM from the disk
    int 0x20            ;expects the filename to search in SI
    ret
read_file:
    mov si, read_prompt
    call print_string_white
    call read_string
    call int_read_file
    ret
int_read_file:
    call print_newline
    mov si, read_buffer
    mov ah, 0x01
    int 0x22
    ret
read_string:
    xor cx, cx
    mov di, read_buffer
read_string_loop:
    xor ah, ah
    int 0x16
    cmp al, 0x0d
    je read_string_done
    cmp al, 0x08
    je rs_handle_backspace
    cmp al, 'q'
    je quit_read_string
    cmp cx, 11
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
    jmp shell
read_string_done:
    ret
write_file:
    mov si, read_prompt
    call print_string_white
    call read_string
    call int_write_file
    ret
int_write_file:
    call print_newline
    mov ah, 0x02
    int 0x22
    ret
ls_dir:
    mov ah, 0x03
    int 0x22
    ret
rename_file:
    mov si, read_prompt
    call print_string_white
    call read_string
    mov si, read_buffer
    mov di, file_kernel_bin
    call compare_str
    jc invalid_filename
    mov ah, 0x04
    int 0x22
    ret
invalid_filename:
    call print_newline
    mov si, invalid_rename
    call print_string_red
    call print_newline
    ret
delete_file:
    mov si, read_prompt
    call print_string_white
    call read_string
    mov si, read_buffer
    mov di, file_kernel_bin
    call compare_str
    jc invalid_filename
    mov ah, 0x05
    int 0x22
    ret