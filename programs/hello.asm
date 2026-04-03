bits 16
[org 0x0000]

start:
    cli
    mov ax, 0x5000
    mov es, ax
    mov ds, ax
    sti
    
    mov si, hello_msg
    mov bl, 0x0b
    call print_start
    retf
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

hello_msg: db 'Hello Technodon!', 0