[org 0x0000]
bits 16

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax
    
    ;call init_drives
    call print_drives
    call print_total
    jmp exit

init_drives:
    xor cx, cx
    mov ah, 0x42
    mov si, dap
    mov dl, 0x81
init_drives_loop:
    int 0x13
    jc init_floppies
    inc cx
    inc dl
    cmp dl, 0x84
    jb init_drives_loop
init_floppies:
    mov [drive], cx
    xor cx, cx
    mov es, cx
    mov ah, 0x02
    mov dl, 0x00
    mov al, 1       ;1 sector
    mov ch, 0       ;cylinder 0
    mov cl, 1       ;sector 1
    mov dh, 0       ;head 0
    mov bx, 0x7000
    xor si, si
init_floppies_loop:
    int 0x13
    jc init_drives_done
    inc dl
    inc si
    cmp dl, 0x02
    jb init_floppies_loop
init_drives_done:
    mov [floppy], si
    mov ax, 0x5000
    mov es, ax
    ret

print_drives:
    mov si, header
    mov bl, 0x0f
    call print_start

    mov si, a_str
    mov bl, 0x0f
    call print_start
    cmp [floppy], 0
    je not_detected
    mov si, active_str
    mov bl, 0x0b
    call print_start
    call print_newline
floppy_b:
    mov si, b_str
    mov bl, 0x0f
    call print_start
    cmp [floppy], 1
    jle not_detected2
    mov si, active_str
    mov bl, 0x0b
    call print_start
    call print_newline
drive_c:
    mov si, c_str
    mov bl, 0x0f
    call print_start
    mov si, root_disk_str
    mov bl, 0x0b
    call print_start
    call print_newline

    mov si, d_str
    mov bl, 0x0f
    call print_start
    cmp word [drive], 0
    je not_detected3
    mov si, active_str
    mov bl, 0x0b
    call print_start
    call print_newline
drive_e:
    mov si, e_str
    mov bl, 0x0f
    call print_start
    cmp [drive], word 1
    jle not_detected4
    mov si, active_str
    mov bl, 0x0b
    call print_start
    call print_newline
    ret
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
print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret
print_total:
    mov si, floppies_str
    mov bl, 0x0f
    call print_start
    mov ax, [floppy]
    call print_dec
    call print_newline
    mov si, drives_str
    mov bl, 0x0f
    call print_start
    mov ax, [drive]
    call print_dec
    ret
not_detected:
    mov si, not_detected_str
    mov bl, 0x0c
    call print_start
    call print_newline
    jmp floppy_b
not_detected2:
    mov si, not_detected_str
    mov bl, 0x0c
    call print_start
    call print_newline
    jmp drive_c
not_detected3:
    mov si, not_detected_str
    mov bl, 0x0c
    call print_start
    call print_newline
    jmp drive_e
not_detected4:
    mov si, not_detected_str
    mov bl, 0x0c
    call print_start
    call print_newline
    ret
print_dec:
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
exit:
    retf
drive: dw 0
floppy: dw 0
a_str: db 'A:/      ', 0
b_str: db 'B:/      ', 0
c_str: db 'C:/      ', 0
d_str: db 'D:/      ', 0
e_str: db 'E:/      ', 0
not_detected_str: db 'Not detected', 0
header: db 'Disk:       Status:         Size:           Used:', 0x0a, 0x0d, 0
root_disk_str: db 'Root Disk', 0
dap:
    db 0x10
    db 1
    dw 0
    dw 0x0000
    dw 0x0000
    dq 0
active_str: db 'Active', 0
floppies_str: db 'Floppies: ', 0
drives_str: db 'Drives: ', 0