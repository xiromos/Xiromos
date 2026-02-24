[org 1000h]
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

    mov si, input1_msg      ;say the user to input a number
    call print_start
    call print_newline
    call read_input1        ;store the input number in a buffer
    call print_newline

    mov si, input2_msg      ;say the user to input a second number
    call print_start        
    call print_newline
    call read_input2

    call calculate          ;calculate the numbers

    ;wait for keyboard input
    mov ah, 0x00
    int 0x16

    jmp 500h                ;exit

set_video_mode:
    mov ax, 0x12
    int 0x10
    ret

print_start:
    mov ah, 0x0e
    mov bh, 0
    mov bl, 0x0f
print_loop:
    lodsb
    cmp al, 0
    je print_done
    int 0x10
    jmp print_loop
print_done:
    ret

print_green:
    mov ah, 0x0e
    mov bh, 0
    mov bl, 0x0a
print_green_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp print_green_loop
.done:
    ret
read_input1:
    mov ax, ds
    mov es, ax
    mov di, buffer1
    xor cx, cx
    jmp read_input_loop
read_input2:
    mov ax, ds
    mov es, ax
    mov di, buffer2
    xor cx, cx
    jmp read_input_loop 
read_input_loop:
    mov ah, 0
    int 0x16        ;BIOS read function
    cmp al, 0x08
    je handle_backspace
    cmp al, 0x0d
    je end
    cmp cx, 255
    jge read_input_loop
    stosb
    mov ah, 0x0e
    int 0x10
    inc cx
    jmp read_input_loop
handle_backspace:
    cmp cx, 0
    je read_input_loop
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_input_loop
end:
    mov byte [di], 0
    call comp_q
    ret
print_newline:
    mov ah, 0x0e    ;print function
    mov al, 0x0d    ;cursor goes to the left of the line
    int 0x10        ;BIOS print interrupt
    mov al, 0x0a    ;cursor goes 1 line down
    int 0x10        
    ret
comp_q:
    mov si, buffer1
    lodsb
    cmp al, 'q'
    je return

    mov si, buffer2
    lodsb
    cmp al, 'q'
    je return

    ret
ascii_to_num:
    xor ax, ax
convertai_loop:
    lodsb
    cmp al, 0
    je done_aiconvert

    sub al, '0'
    mov bl, al

    mov dx, ax
    mov cx, 10
    mul cx

    add ax, bx
    jmp convertai_loop
done_aiconvert:
    ret
num_to_ascii:
    mov di, num + 9        ; Zeige auf das Ende des num-Buffers
    mov byte [di], 0       ; Null-Terminator
    dec di
convertia_loop:
    xor dx, dx
    mov bx, 10
    div bx

    add dl, '0'
    mov [di], dl
    dec di

    cmp ax, 0
    jne convertia_loop

    inc di
    ret
    

calculate:
    mov si, buffer1
    call ascii_to_num
    mov bx, ax

    mov si, buffer2
    call ascii_to_num
    add ax, bx

    call num_to_ascii
    
    call print_newline
    mov si, result_msg
    call print_start
    call print_newline

    mov si, [num]
    call print_start
    call print_newline
    call print_newline

    mov si, exit_msg
    call print_start

print_result:

    xor ah, ah
    int 0x16
    clc

    call start

return:
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