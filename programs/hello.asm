bits 16
[org 0x0000]

start:
    mov ax, 0x2000
    mov es, ax
    mov ds, ax

    mov si, hello_msg
    mov bl, 0x0b
    call print_start
    xor ah, ah
    int 0x16
    jmp 0x1000:0x0000
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