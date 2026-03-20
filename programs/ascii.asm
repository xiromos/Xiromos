bits 16
[org 0x0000]

start:
    mov ax, 0x2000
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x9000

    mov ax, 0x12
    int 0x10