[org 0x0000]

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    mov ax, 0x4f02
    mov bx, 0x105
    int 0x10

    ; mov ax, 0x11
    ; mov bh, 16
    ; mov cx, 256

    ; mov dx, font

    ; int 0x10

    ; mov ah, 0x0e
    ; mov al, 'A'
    ; int 0x10

    ; mov ah, 0x0e
    ; mov al, 'B'
    ; int 0x10

    ; xor ah, ah
    ; int 0x16

    ; mov ah, 0x15
    ; mov al, 0b11111111
    ; int 0x16

    mov si, hello_str
    mov bl, 0x0a
    mov bh, 0x02
    int 0x27

    xor ah, ah
    int 0x16

    mov ax, 0x12
    int 0x10

    retf
print:
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret
hello_str: db 0x0a, '   Hello, this is VESA mode with the resolution of 1024x768 pixels and 256 colors', 0

font:
    times 65*16 db 0

    db 0b00111100
    db 0b01100110
    db 0b01100110
    db 0b01111110
    db 0b01100110
    db 0b01100110
    db 0b01100110
    db 0b01100110
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000

    db 0b01111110
    db 0b11000011
    db 0b11000011
    db 0b11111110
    db 0b11000011
    db 0b11000011
    db 0b01111110
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000
    db 0b00000000

    times (256-65)*16 db 0