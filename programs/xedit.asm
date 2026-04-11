;========================================================
;Xiromos Texteditor Program by Technodon
;Copyright (C) 2026 Technodon
;========================================================
[org 0x0000]
bits 16

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax
    
print_header:
    mov ax, 0x12
    int 0x10
    mov si, header_msg
    mov bl, 0x0b
    call print_start
    mov si, instructions_msg
    mov bl, 0x0b
    call print_start
    mov di, text_buffer

;----------writing---------
write_loop:
    call get_cursor_pos
    call read_cursor_pos
    call print_cursor
    xor ah, ah
    int 0x16
    call compare_chars
print_chars:
    mov ah, 0x0e
    mov bl, 0x0f
    int 0x10
save_buffer:
    cmp di, [text_max]
    je max_text_written
    stosb
    jmp write_loop
handle_backspace:
    pop bx
    dec di
    cmp [column], 0
    je go_up
    call delete_cursor
    mov ah, 0x0e
    mov al, 0x08    ;go one space back
    int 0x10
    mov al, ' '     ;replace the char with space
    int 0x10        
    mov al, 0x08    ;go another space back
    int 0x10
    stosb
    jmp write_loop

compare_chars:
    cmp ah, 0x53    ;DEL
    je exit
    cmp ah, 0x3b    ;F1
    je open_file
    cmp ah, 0x3c    ;F2
    je save_file
    cmp ah, 0x3d    ;F3
    je change_cursor
    cmp al, 0x08    ;BACKSPACE
    je handle_backspace
    cmp al, 0x0d    ;ENTER
    je new_line
    cmp al, 0x09    ;TAB
    je tab
    cmp ah, 0x48    ;UP
    je move_up
    cmp ah, 0x50    ;DOWN
    je move_down
    cmp ah, 0x4b    ;left
    je move_left
    cmp ah, 0x4d    ;right
    je move_right
    ret

;---------------------------
new_line:
    call delete_cursor
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10
    ret
tab:
    call delete_cursor
    mov cx, 4
tab_loop:
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    loop tab_loop
    ret
;-------------------------
;--------Cursor-----------
print_cursor:
    mov ah, 0x09
    mov al, [cursor]
    mov bh, 0
    mov bl, 0x0e
    mov cx, 1
    int 0x10
    ret
delete_cursor:
    mov ah, 0x09
    mov al, [curs_char]
    mov bh, 0
    mov bl, 0x0f
    mov cx, 1
    int 0x10
    ret
get_cursor_pos:
    mov ah, 0x03
    mov bh, 0
    int 0x10

    mov [line], dh
    mov [column], dl
    ret
set_cursor_pos:
    mov ah, 0x02
    mov bh, 0
    mov dh, [line]
    mov dl, [column]
    int 0x10
    ret
go_up:
    call delete_cursor
    cmp [line], 2
    je write_loop

    sub [line], 1
    mov ah, 0x02
    mov dh, [line]
    mov dl, [column]
    mov bh, 0
    int 0x10
    jmp save_buffer
move_up:
    pop ax
    call delete_cursor
    cmp [line], 2
    je write_loop
    sub byte [line], 1
    call set_cursor_pos
    jmp save_buffer
move_down:
    pop bx
    call delete_cursor
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    jmp save_buffer
move_left:
    pop ax
    call delete_cursor
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    jmp save_buffer
move_right:
    call delete_cursor
    call read_cursor_pos
    call print_cursor
    ret
read_cursor_pos:
    mov ah, 0x08    ;al = character
    mov bh, 0
    int 0x10
    cmp al, 0
    ;mov byte [cursor], '_'
    ;je print_done   ;ret
    mov byte [cursor], al
    mov byte [curs_char], al
    ret
;---------file system-------------
open_file:
    pop ax

    ;clear screen
    mov ax, 0x12
    int 0x10

    ;ask user for input
    mov si, enter_filename
    mov bl, 0x0f
    call print_start
    mov di, inputfile_buffer
    call read_string
    call clear_buffer

    xor cx, cx
    mov ah, 0x08        ;filename in SI, output buffer in DI, CX = 0
    mov si, inputfile_buffer
    mov di, outputfile_buffer
    int 0x22
    
    mov ax, 0x12
    int 0x10
    mov si, header_msg
    mov bl, 0x0b
    call print_start
    mov si, instructions_msg
    mov bl, 0x0b
    call print_start

    mov ah, 0x01
    mov si, outputfile_buffer
    mov di, text_buffer
    int 0x23

    mov si, text_buffer
    mov bl, 0x0f
    call print_start
    cmp cx, 0x67
    je max_text_written
    jmp write_loop

save_file:
    pop bx

    mov si, file_test_txt
    mov di, text_buffer
    mov cx, 512
    mov ah, 0x02
    int 0x23
    jmp write_loop
max_text_written:
    mov si, max_text_msg
    mov bl, 0x0c
    call print_start
    jmp write_loop
clear_buffer:
    mov al, ' '
    mov di, outputfile_buffer
    mov cx, 11
    rep stosb
    ret
;---------other functions---------
print_start:
    mov ah, 0x0e
print_loop:
    lodsb
    cmp al, 0
    je print_done
    int 0x10
    jmp print_loop
print_done:
    ret
change_cursor:
    pop ax          ;call
    call delete_cursor
    mov ax, 0x12
    int 0x10
    mov si, change_cur_str
    call print_start
    xor ah, ah
    int 0x16
    mov [cursor], '_'
    cmp al, '1'
    je print_header
    mov [cursor], 0xdb
    cmp al, '2'
    je print_header
    mov [cursor], 'I'
    cmp al, '3'
    je print_header
    mov [cursor], '#'
    jmp print_header
read_string:
    xor cx, cx
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
    pop ax
    jmp print_header
read_string_done:
    ret
exit:
    pop bx
    mov ax, 0x12
    int 0x10
    retf

;----data----
header_msg: db '                    XIROMOS TEXTEDITOR -- DEL TO QUIT', 0x0a, 0x0d, 0
instructions_msg: db '         F1 - Open File      F2 - Save File    F3 - Change Cursor', 0x0a, 0x0d, 0
cursor db '_'
change_cur_str: db 'Press 1 for underline cursor, 2 for block cursor or 3 for stick cursor', 0
max_text_msg: db 'Maximum length of text. Press F2 to save it', 0x0a, 0x0d, 0
enter_filename: db 'Enter the filename you want to open: ', 0
line db 2
column db 0
curs_char db 0
text_buffer dw 0xb000
text_max dw 0xbf00
inputfile_buffer: db 0 dup(12)
outputfile_buffer: db 0 dup(11)
file_test_txt db "TEST    TXT"