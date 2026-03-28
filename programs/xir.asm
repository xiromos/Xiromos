;===================================================================
;Xiromos Assembly-Texteditor
;Copyright (C) 2026 Technodon. All Rights Reserved
;
;features: custom cursor and assembly-syntax highlighting
;uses graphic mode 0x13
;===================================================================

bits 16
[org 0x0000]

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    ;320x200
    mov ax, 0x13
    int 0x10

    mov si, header
    mov bl, 0x04
    call print_start
    call print_newline
    mov si, instructions
    mov bl, 0x0c
    call print_start
    call print_newline
    call print_newline

    mov [pos_y], word 32
    jmp write_loop

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



;------------------Cursor------------------------
print_cursor:
    mov ax, [pos_y]
    mov cx, 320
    mul cx

    add ax, [pos_x]
    mov di, ax

    xor ax, ax
    mov al, 0x0e
    mov cx, 8

    mov dx, 0xa000
    mov es, dx
draw_loop:
    mov [es:di], al
    inc di
    loop draw_loop
    mov ax, 0x5000
    mov es, ax
    ret
delete_cursor:
    mov dx, 0xa000
    mov es, dx

    mov ax, [pos_y]
    mov cx, 320
    mul cx

    add ax, [pos_x]
    mov di, ax

    xor ax, ax
    mov cx, 8
delete_cursor_loop:
    mov al, 0x00
    mov [es:di], al
    inc di
    loop delete_cursor_loop
    mov dx, 0x5000
    mov es, dx
    ret
get_cursor_pos:
    mov ah, 0x03
    mov bh, 0
    int 0x10
    ;DL = X (0-79)
    ;DH = Y (0-24)
    mov [bios_x], dl
    mov [bios_y], dh
    ret
set_bios_cursor:
    mov ah, 0x02
    mov bh, [page_number]
    mov dh, [bios_y]
    mov dl, [bios_x]
    int 0x10
    ret
;---------------------------text input-------------------------
write_loop:
    call get_cursor_pos
    call print_cursor
    xor ah, ah
    int 0x16
    call compare_chars
print_chars:
    mov ah, 0x0e
    mov bl, 0x0f
    int 0x10
    call delete_cursor
    add [pos_x], 8
    jmp write_loop
handle_backspace:
    cmp [bios_x], 0
    je move_line_up
    mov ah, 0x0e
    mov al, 0x08    ;go one space back
    int 0x10
    mov al, ' '     ;replace the char with space
    int 0x10        
    mov al, 0x08    ;go another space back
    int 0x10
    call delete_cursor
    sub [pos_x], 8
    call print_cursor
    sub [bios_x], 1
    jmp write_loop
move_line_up:
    call delete_cursor
    cmp [bios_y], 2
    je write_loop
    sub [pos_y], 8
    mov [pos_x], 0
    call print_cursor
    sub [bios_y], 1
    mov [bios_x], 0
    cmp [current_line_number], 0
    je last_page
    call set_bios_cursor
    jmp write_loop
last_page:
    mov [current_line_number], 24
    sub [page_number], 1
    call set_bios_cursor
    jmp write_loop
print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret
print_z:
    mov al, 'z'
    jmp print_chars
print_y:
    mov al, 'y'
    jmp print_chars
print_Z:
    mov al, 'Z'
    jmp print_chars
print_Y:
    mov al, 'Y'
    jmp print_chars
print__:
    mov al, '_'
    jmp print_chars
tab:
    call delete_cursor
    mov cx, 4
tab_loop:
    dec cx
    cmp cx, 0
    je print_chars
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    add [pos_x], 8
    jmp tab_loop
line_down:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    call delete_cursor
    add [pos_y], 8
    mov [pos_x], 0
    call print_cursor
    
    add [current_line_number], 1
    cmp [current_line_number], 25
    jne write_loop

    add [page_number], 1
    mov [current_line_number], 0
    jmp write_loop
sub_8:
    sub [pos_y], 8
    jmp write_loop
compare_chars:
    cmp al, 0x0d        ;compare if ENTER was pressed
    je line_down
    cmp al, 0x08        ;compare if BACKSPACE was pressed
    je handle_backspace
    cmp al, 0x1b        ;al=0x1b ESCAPE, ah=0x53 =DEL 
    je exit_program
    cmp al, 'y'         ;german
    je print_z          ;keyboard
    cmp al, 'z'         ;is much better
    je print_y          ;than the english one
    cmp al, 'Y'         
    je print_Z          
    cmp al, 'Z'         
    je print_Y
    cmp al, '?'
    je print__
    cmp al, 0x09        ;TAB
    je tab
    cmp ax, 0x4b00      ;LEFT
    je move_left
    cmp ax, 0x4d00      ;RIGHT
    je move_right
    cmp ax, 0x4800      ;UP
    ;je move_up
    cmp ax, 0x5000      ;DOWN
    ;je move_down
    cmp ah, 0x3b
    je open_file
    ret
move_left:
    call delete_cursor
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    sub [pos_x], 8
    call print_cursor
    jmp write_loop
move_right:
    call delete_cursor
    mov ah, 0x0e
    int 0x10
    add [pos_x], 8
    add [bios_x], 1
    cmp [bios_x], 79
    je line_down
    jmp write_loop

;--------------------file system----------------------
open_file:
    mov ax, 0x12
    int 0x10

    mov ah, 0x03
    int 0x22
    mov ax, 0x5000
    mov ds, ax
    mov es, ax
    
    call print_newline
    mov si, f1_instruction_msg
    mov bl, 0x0b
    call print_start
    call print_newline
    mov si, prompt
    mov bl, 0x0f
    call print_start
    call read_string
    mov si, di
    mov ah, 0x01
    int 0x22
    mov ax, 0x5000
    mov ds, ax
    mov es, ax
    xor ah, ah
    int 0x16
;--------------------other functions------------------
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
    jmp start
read_string_done:
    ret


exit_program:
    pop ax
    mov ax, 0x12
    int 0x10
    retf


;--------------------data-----------------------------
header: db '    XIR TEXTEDITOR -- ESC TO QUIT', 0
instructions: db '  F1 - Open File    F2 - Save File', 0
pos_x: dw 0
pos_y: dw 0
bios_x: dw 0
bios_y: dw 0
page_number: dw 0
current_line_number: dw 0
f1_instruction_msg: db 'Chose a file to edit or press "q" to go back', 0
prompt: db '> ', 0
read_buffer: db 0 dup(11)