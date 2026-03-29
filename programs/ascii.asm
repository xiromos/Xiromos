;============================================================
;Program that shows the ASCII table
;Copyright (C) 2026 Technodon
;============================================================
bits 16
[org 0x0000]

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    mov ax, 0x12
    int 0x10

    mov si, ascii_table1
    call print_start
    xor ah, ah
    int 0x16
    jmp exit

print_start:
    mov ah, 0x0e
    mov bl, 0x0e
print_loop:
    lodsb
    cmp al, 0
    je done
    int 0x10
    jmp print_loop
done:
    ret

exit:
    mov ax, 0x12
    int 0x10
    retf

ascii_table1 db 'HEX        CHAR        |       HEX        CHAR', 13, 10,
             db '                       |       0x61       a', 13, 10, 
             db '0x08       BACKSPACE   |       0x62       b', 13, 10,
             db '0x09       TAB         |       0x63       c', 13, 10,
             db '0x1b       ESCAPE      |       0x64       d', 13, 10,
             db '0x20       SPACE       |       0x65       e', 13, 10,
             db '0x21       !           |       0x66       f', 13, 10,
             db '0x22       "           |       0x67       g', 13, 10,
             db '0x24       $           |       0x68       h', 13, 10,
             db '0x25       %           |       0x69       i', 13, 10,
             db '0x26       &           |       0x6A       j', 13, 10,
             db '0x28       (           |       0x6B       k', 13, 10,
             db '0x29       )           |       0x6C       l', 13, 10,
             db '0x2A       *           |       0x6D       m', 13, 10,
             db '0x2B       +           |       0x6E       n', 13, 10,
             db '0x2C       ,           |       0x6F       o', 13, 10,
             db '0x2D       -           |       0x70       p', 13, 10,
             db '0x2E       .           |       0x71       q', 13, 10,
             db '0x2F       /           |       0x72       r', 13, 10,
             db '0x3A       :           |       0x73       s', 13, 10,
             db '0x3C       <           |       0x74       t', 13, 10,
             db '0x3D       =           |       0x75       u', 13, 10,
             db '0x3E       >           |       0x76       v', 13, 10,
             db '0x3F       ?           |       0x77       w', 13, 10,
             db '0x40       @           |       0x78       x', 13, 10,
             db '0x7F       DEL         |       0x79       y', 13, 10,
             db '                       |       0x7A       z', 13, 10, 13, 10
             db 'Press Any Key To Return To Terminal...', 0
             