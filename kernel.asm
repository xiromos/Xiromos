[org 0x0000]
bits 16

start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ax, 0x03
    int 0x10

    mov si, welcome_msg
    call print_loop
    call user_input

hang:
    jmp hang

print_loop:
    lodsb           ;loads next byte
    or al, al
    jz done_print
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    jmp print_loop

done_print:
    ret

user_input:


welcome_msg: db 'Kernel Bootet Successfully. Type "help" For Help.', 0x0d, 0x0a, 0