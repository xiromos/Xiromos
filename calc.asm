[org 8000h]
bits 16

start:
    mov ax, 0x03            ;clear screen
    int 0x10

    call set_video_mode

    mov si, welcome_msg     ;display welcome_message
    call print_start
    call print_newline
    
    mov si, leave_msg       ;show the user how to leave
    call print_start
    call print_newline

    call read_input
    call exit_program

set_video_mode:
    mov ax, 0x12
    int 0x10
    ret

print_start:
    mov ah, 0x0e
    mov bl, 0x0f
print_loop:
    lodsb
    cmp al, 0
    je print_done
    int 0x10
    jmp print_loop
print_done:
    ret

print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret
    

read_input:
    mov di, buffer1
    xor cx, cx
read_loop:
    mov ah, 0
    int 0x16
    cmp al, 0x0d
    je read_done
    cmp al, 0x08
    je handle_backspace
    cmp cx, 255
    je read_loop
    stosb
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x10
    inc cx
    jmp read_loop
handle_backspace:
    cmp di, buffer1
    je read_loop
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_loop
read_done:
    mov byte [di], 0
    ret


exit_program:
    jmp 500h





;================================================
; Variables And Buffers
;================================================

welcome_msg: db 'Xiromos Calculator v0.1', 0
leave_msg: db 'To Leave Type "q"', 0
input1_msg: db 'Input a number ', 0
result_msg: db 'Result: ', 0
input2_msg: db 'Input a second number ', 0
exit_msg: db 'Press Key To Calculate Again...', 0
buffer1 dw 25 dup(0)
buffer2 dw 25 dup(0)
num db 10 dup(0)
addi: db 'ADD: ', 0
subt: db 'SUB: ', 0
mult: db 'MUL: ', 0
divi: db 'DIV: ', 0