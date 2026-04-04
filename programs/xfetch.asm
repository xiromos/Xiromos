[org 0x0000]
bits 16

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax


    mov si, line1
    mov bl, 0x0f
    call print_start
    mov si, line2
    mov bl, 0x0f
    call print_start
    mov si, line3
    call print_start
    call print_newline
    mov si, line4
    call print_start
    call check_edd
    mov si, line5
    mov bl, 0x0f
    call print_start
    call check_cpu
    mov si, line6
    mov bl, 0x0f
    call print_start
    call detect_drives
    mov si, line7
    mov bl, 0x0f
    call print_start
    call print_newline
    mov si, line8
    call print_start
    call print_newline
    mov si, line9
    call print_start
    call detect_memory
    mov si, lineA
    mov bl, 0x0f
    call print_start
    call print_blocks
    call print_newline
    jmp exit

print_start:
    mov ah, 0x0e
print_loop:
    lodsb
    cmp al, 0
    je done
    int 0x10
    jmp print_loop
done:
    ret
print_newline:
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10
    ret

check_edd:
    mov ah, 0x41
    mov bx, 0x55aa
    mov dl, 0x80
    int 0x13
    cmp bx, 0xaa55
    je edd_true

    mov si, no_str
    mov bl, 0x0c
    call print_start
    call print_newline
    ret
edd_true:
    mov si, active_str
    mov bl, 0x0a
    call print_start
    call print_newline
    ret
check_cpu:
    mov eax, 0x80000002
    cpuid
    mov [cpu_type_str+0], eax
    mov [cpu_type_str+4], ebx
    mov [cpu_type_str+8], ecx
    mov [cpu_type_str+12], edx
    mov eax, 0x80000003
    cpuid
    mov [cpu_type_str+16], eax
    mov [cpu_type_str+20], ebx
    mov [cpu_type_str+24], ecx
    mov [cpu_type_str+28], edx
    mov eax, 0x80000004
    cpuid
    mov [cpu_type_str+32], eax
    mov [cpu_type_str+36], ebx
    mov [cpu_type_str+40], ecx
    mov [cpu_type_str+44], edx
    mov si, cpu_type_str
    mov bl, 0x0b
    call print_start
    call print_newline
    ret
detect_drives:
    push es
    mov ax, 0x0040
    mov es, ax
    mov al, [es:0x0075]
    mov ah, 0
    pop es
    call print_decimal
    call print_newline
    ret
print_decimal:
    pusha
    mov cx, 0
    mov bx, 10
.div_loop:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .div_loop
.print_loop:
    pop ax
    add al, '0'
    mov ah, 0x0e
    int 0x10
    loop .print_loop
    popa
    ret
detect_memory:
    int 0x12
    call print_decimal
    mov si, kb_str
    mov bl, 0x0f
    call print_start
    call print_newline
    ret
print_blocks:
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x01
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x02
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x03
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x04
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x05
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x06
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x07
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x08
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x09
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0a
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0b
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0c
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0d
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0e
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0f
    int 0x10
    ret
exit:
    retf



;--data--
no_str: db 'Not present', 0
active_str: db 'Active', 0
cpu_type_str: times 49 db 0
kb_str: db ' KB', 0
line1: db ' _____ ', 0x0a, 0x0d, 0
line2: db '|     |      Host-PC: x86', 0x0a, 0x0d, 0
line3: db '|_____|      Video: Mode 0x12, 640x480', 0
line4: db ' _____       Enhanced Disk Drive Services: ', 0
line5: db '|     |      CPU: ', 0
line6: db '|     |      Drives: ', 0
line7: db '|     |      Supported Filesystems: FAT12, FAT16', 0
line8: db '|     |      Supported Disk Types: Floppy Disk, Hard Disk', 0
line9: db '|     |      Memory: ', 0
lineA: db '|     |', 0x0a, 0x0d,
       db '|     |', 0x0a, 0x0d,
       db '|_____|      ', 0