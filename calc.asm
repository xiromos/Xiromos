[org 800h]
bits 16

start:
    mov ax, 0x03
    int 0x10

    mov si, input1_msg
    call print_start

    ;wait for keyboard input
    mov ah, 0x00
    int 0x16

    jmp 500h

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

input1_msg: db 'Press A Key', 0