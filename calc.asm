;==============================================
;Simple Calculator
;Copyright (C) 2026 Technodon
;==============================================
[org 0x5000]
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

    mov si, input1_msg
    call print_start
    call print_newline
    call read_input1
    call print_newline

    mov si, input2_msg
    call print_start
    call print_newline
    call read_input2
    call print_newline

    call convert_to_num1
    call convert_to_num2

    call calculate

    call convert_to_ascii1

    jmp start

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

print_string_green:
    mov ah, 0x0E
    mov bl, 0x0a
print_char:
    lodsb
    cmp al, 0
    je print_char_done
    int 0x10
    jmp print_char
print_char_done:
    ret
    
;=====================read and store number=====================
;---------------------read input1 ------------------------------
read_input1:
    mov di, buffer1
    xor cx, cx
read_loop1:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0d
    je read_done
    cmp al, 0x08
    je handle_backspace1
    cmp cx, 255
    je read_loop1
    stosb
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x10
    cmp al, 'q'
    je exit_program
    inc cx
    jmp read_loop1
handle_backspace1:
    cmp di, buffer1
    je read_loop1
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_loop1

;---------------------read input1 ------------------------------

read_input2:
    mov di, buffer2
    xor cx, cx
read_loop2:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0d
    je read_done
    cmp al, 0x08
    je handle_backspace2
    cmp cx, 255
    je read_loop2
    stosb
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x10
    cmp al, 'q'
    je exit_program
    inc cx
    jmp read_loop2
handle_backspace2:
    cmp di, buffer2
    je read_loop2
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_loop2
read_done:
    mov byte [di], 0
    ret

convert_to_num1:
    mov si, buffer1
    xor ax, ax
    xor cx, cx
convert_to_num_loop1:
    lodsb
    cmp al, 0
    je done_convert_to_num1
    sub al, '0'         
    imul cx, 10
    add cx, ax
    jmp convert_to_num_loop1
done_convert_to_num1:
    mov [buffer1], cx
    ret
convert_to_num2:
    mov si, buffer2
    xor ax, ax
    xor cx, cx
convert_to_num_loop2:
    lodsb
    cmp al, 0
    je done_convert_to_num2
    sub al, '0'         
    imul cx, 10
    add cx, ax
    jmp convert_to_num_loop2
done_convert_to_num2:
    mov [buffer2], cx
    ret
calculate:
    ;add
    xor ax, ax
    xor cx, cx
    mov ax, [buffer1]
    mov cx, [buffer2]
    add ax, cx
    mov [num1], ax
    ;sub
    xor ax, ax
    xor cx, cx
    mov ax, [buffer1]
    mov cx, [buffer2]
    sub ax, cx
    mov [num2], ax
    ret
convert_to_ascii1:
    mov ax, [num1]
    mov di, result_buf1
    mov bx, 10
    xor cx, cx
    
    ; Count digits
    mov dx, ax
    mov cx, 0
count_digits1:
    xor dx, dx
    div bx
    inc cx
    cmp ax, 0
    jne count_digits1
    
    mov ax, [num1]
    add di, cx        ;move to end of buffer
    mov byte [di], 0  ;null terminator
    dec di
    
    ; Extract digits
convert_digit_loop1:
    xor dx, dx
    div bx
    add dl, '0'
    mov [di], dl
    dec di
    cmp ax, 0
    jne convert_digit_loop1
    
convert_to_ascii2:
    mov ax, [num2]
    mov di, result_buf2
    mov bx, 10
    xor cx, cx
    
    ; Count digits
    mov dx, ax
    mov cx, 0
count_digits2:
    xor dx, dx
    div bx
    inc cx
    cmp ax, 0
    jne count_digits2
    
    mov ax, [num2]
    add di, cx        ;move to end of buffer
    mov byte [di], 0  ;null terminator
    dec di
    
    ; Extract digits
convert_digit_loop2:
    xor dx, dx
    div bx
    add dl, '0'
    mov [di], dl
    dec di
    cmp ax, 0
    jne convert_digit_loop2
    
    jmp print_result


print_result:
    mov si, result_msg
    call print_start
    call print_newline

    mov si, addi
    call print_start

    mov si, result_buf1
    call print_string_green
    call print_newline

    mov si, subt
    call print_start

    mov si, result_buf2
    call print_string_green
    call print_newline
    call print_newline

    mov si, restart_msg
    call print_start
    call print_newline

    xor ah, ah
    int 0x16
    ret


exit_program:
    jmp 0x1000





;================================================
; Variables And Buffers
;================================================

welcome_msg: db 'Xiromos Calculator v0.1', 0
leave_msg: db 'To Leave Type "q"', 0
input1_msg: db 'Input a number ', 0
result_msg: db 'Result: ', 0
input2_msg: db 'Input a second number ', 0
exit_msg: db 'Press Key To Calculate Again...', 0
buffer1: db 25 dup(0)
buffer2: db 25 dup(0)
num1: dw 0
num2: dw 0
result_buf1: db 50 dup(0)
result_buf2: db 50 dup(0)
addi: db 'ADD: ', 0
subt: db 'SUB: ', 0
mult: db 'MUL: ', 0
divi: db 'DIV: ', 0
restart_msg: db 'Press Any Key To Restart...', 0