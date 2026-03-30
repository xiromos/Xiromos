[org 0x0000]
bits 16

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    jmp exit

exit:
    xor ah, ah
    int 0x16
    retf