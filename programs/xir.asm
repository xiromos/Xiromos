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

    mov si, header
    mov bl, 0x0f
    call print_start

    xor ah, ah
    int 0x16
    jmp exit

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
exit:
    jmp 0x1000:0x0000

header: db 'Xiromos Texteditor', 0