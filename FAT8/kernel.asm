[org 0x0000]
bits 16

start:
    cli
    mov ax, 0x1000
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, ax
    sti

    mov ax, 0x12
    int 0x10

    mov si, welcome_msg
    mov bl, 0x0f
    call print_start

    hlt
    hlt
    hlt
halt:
    jmp halt

print_start:
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

welcome_msg: db 'Hello from Kernel!', 0