[org 0x0000]
bits 16

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    mov si, welcome_msg
    mov bh, 0x02
    mov bl, 0x01
    int 0x27

get_key:
    xor ax, ax
    int 0x16

    mov si, prefix
    mov bh, 0x02
    mov bl, 0x0b
    int 0x27

    push ax
    ;add al, ah
    mov dx, ax
    mov bh, 0x03
    int 0x27
    pop ax

    mov cx, 3
    push ax
    call print_spaces
    pop ax

    mov ah, 0x0e
    mov bl, 0x0b
    int 0x10

    cmp al, 'q'
    je exit

    call print_newline
    jmp get_key

print_spaces:
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    loop print_spaces
    ret

print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret

exit:
    retf

prefix: db '0x', 0
welcome_msg: db 'Press "q" to quit', 0x0a, 0x0d, 0