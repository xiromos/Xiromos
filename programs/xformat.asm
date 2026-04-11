[org 0x0000]
bits 16

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    call print_newline
    mov si, header_msg
    mov bl, 0x0f
    call print_start
    call print_newline

    call get_drive_number

    cmp di, 0x01
    jb .format_floppy

    ;call format_disk
    jmp exit
.format_floppy:
    call format_floppy
    jmp exit
get_drive_number:
    mov si, prompt
    mov bl, 0x0f
    call print_start
    xor ah, ah
    int 0x16

    mov ah, 0x0e
    mov bl, 0x02
    int 0x10

    xor di, di
    cmp al, 'A'
    je .done
    cmp al, 'a'
    je .done
    inc di
    cmp al, 'B'
    je .done
    cmp al, 'b'
    je .done
    mov di, 0x81
    cmp al, 'D'
    je .done
    cmp al, 'd'
    je .done
    inc di
    cmp al, 'E'
    je .done
    cmp al, 'e'
    je .done

    cmp al, 'q'
    je .exit

    call print_newline
    mov si, invalid_drive
    mov bl, 0x0c
    call print_start
    call print_newline
    jmp get_drive_number
.done:
    mov [drive_number], di
    call print_newline
    mov si, confirm_str
    mov bl, 0x0b
    call print_start
    call print_newline
    mov si, prompt
    mov bl, 0x0f
    call print_start
    xor ah, ah
    int 0x16
    mov ah, 0x0e
    int 0x10
    cmp al, 'y'
    je .confirmed
    cmp al, 'Y'
    je .confirmed
    call print_newline
    mov si, cancelled_str
    mov bl, 0x0c
    call print_start
    call print_newline
    jmp get_drive_number

.confirmed:
    ret
.exit:
    pop bx
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
print_newline:
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10
    ret
format_floppy:
    call print_newline
    mov si, formatting_str
    mov bl, 0x0f
    call print_start

    mov ax, [flp_root_entry]
    mov bx, [flp_entry_size]
    mul bx

    mov cx, ax
    xor al, al
    lea di, 0x7000
    rep stosb

load_flp_mbr:
    mov ah, 0x02
    mov al, 1       ;1 sector to read
    mov ch, 0       ;cylinder
    mov cl, 1       ;first sector
    mov dh, 0       ;head
    mov dl, [drive_number]
    mov bx, 0x9000  ;load to 0x9000:0x7c00
    mov es, bx
    mov bx, 0x7c00
    int 0x13
    jc disk_error

    call get_root_start     ;output = LBA of the root start sector
    call lba_to_chs
    
    mov ah, 0x03
    mov al, 9       ;size of root dir on standard floppy
    mov cl, [absolute_sector]
    mov ch, [absolute_cylinder]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov bx, 0x7000
    mov es, bx
    xor bx, bx
    int 0x13
    jc disk_error

    mov ax, [reserved]
    call lba_to_chs

    mov ah, 0x03
    mov al, [fat_size]
    mov cl, [absolute_sector]
    mov ch, [absolute_cylinder]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov bx, 0x7000
    mov es, bx
    xor bx, bx
    int 0x13
    jc disk_error

    mov ax, 0x5000
    mov es, ax

    mov si, success_msg
    mov bl, 0x0a
    call print_start
    ret
get_root_start:
    mov di, 0x9000
    mov es, di
    mov di, 0x7c00

    mov al, [es:di+16]
    mov [fat_num], al
    mov ax, [es:di+22]
    mov [fat_size], ax
    mov ax, [es:di+14]
    mov [reserved], ax
    mov ax, [es:di+24]
    mov [sec_per_track], ax
    mov ax, [es:di+26]
    mov [num_heads], ax
    
    mov di, 0x5000
    mov es, di

    xor ax, ax
    mov al, [fat_num]
    mov bx, [fat_size]
    mul bx
    add ax, [reserved]
    ret
lba_to_chs:
    ;input: AX = LBA value
    xor dx, dx
    div word [sec_per_track]
    inc dl
    mov byte [absolute_sector], dl
    xor dx, dx
    div word [num_heads]
    mov byte [absolute_head], dl
    mov byte [absolute_cylinder], al
    ret

disk_error:
    pop bx
    mov si, disk_error_msg
    mov bl, 0x0c
    call print_start
    call print_newline
exit:
    retf


;--data--
header_msg: db '  ---- XFORMAT ----', 0x0a, 0x0d,
            db 'Erase or format a disk', 0x0a, 0x0d
            db 'Enter the drive number of', 0x0a, 0x0d
            db 'the disk you want to clear.', 0x0a, 0x0d
            db '  ------------------', 0x0a, 0x0d, 0
            
flp_root_entry: dw 224
flp_entry_size: dw 32
invalid_drive: db 'Invalid drive number', 0

fat_num: db 0
fat_size: dw 0
reserved: dw 0
sec_per_track: dw 0
num_heads: dw 0
absolute_sector: db 0
absolute_head: db 0
absolute_cylinder: db 0
drive_number: db 0
formatting_str: db 'Formatting Floppy...', 0
success_msg: db 'Floppy successfully formatted', 0
disk_error_msg: db 'Error while formatting disk. Do not use it, because it might be corrupted', 0
prompt: db '> ', 0
confirm_str: db 'Are you sure you want to format this disk? All data will be lost (y/n)', 0
cancelled_str: db 'Cancelled...', 0