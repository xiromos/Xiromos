;======================================================
;interrupt for reading and writing from a FAT12 formatted floppy disk
;AH = 0x01: load root directory and FAT from the floppy into memory
;AH = 0x02: read a file from the floppy disk            (filename in SI)
;Copyright (C) 2026 Technodon
;======================================================
check_floppy:
    mov [external_drive_number], di

    mov si, drive_num_str
    call print_string_white
    mov dx, [external_drive_number]
    call print_hex
    call print_newline
    
    call load_flpy_mbr
    call get_floppy_bpb
    call calculate_flp_values
    call load_flp_root
    call load_flp_fat
    mov ax, kernel_seg
    mov es, ax
    mov si, floppy_read_success
    call print_string_green
    call print_newline
    iret
load_flpy_mbr:
    mov ah, 0x02
    mov al, 1       ;1 sector to read
    mov ch, 0       ;cylinder
    mov cl, 1       ;first sector
    mov dh, 0       ;head
    mov dl, [external_drive_number]
    mov bx, 0x9000  ;load to 0x9000:0x7c00
    mov es, bx
    mov bx, 0x7c00
    int 0x13
    jc floppy_read_error
    ret
floppy_read_error:
    pop bx
    mov si, flp_error_msg
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    call reload_root
    call reload_fat
    iret
get_floppy_bpb:
    mov di, 0x7c00
    mov al, [external_drive_number]
    mov [drive_number], al
    mov al, [es:di+0x0d]
    mov [sec_per_cluster], al
    mov ax, [es:di+0x0e]
    mov [reserved_sectors], ax
    mov ax, word [es:di+0x11]
    mov [root_entries], ax
    mov ax, [es:di+0x16]
    mov [fat_size], ax
    mov ax, [es:di+0x0b]
    mov [bytes_per_sec], ax
    mov al, [es:di+0x10]
    mov [fat_num], al
    mov ax, [es:di+24]
    mov [sec_per_track], ax
    mov ax, [es:di+26]
    mov [num_heads], ax
    cmp word [es:di+510], 0xaa55
    jne floppy_read_error
    mov ax, kernel_seg
    mov es, ax
    ret

calculate_flp_values:
    ;calculate root sectors
    mov ax, [root_entries]
    mov bx, 32
    mul bx

    mov bx, [bytes_per_sec]
    add ax, bx
    dec ax
    xor dx, dx
    div bx

    mov [root_size], ax
    mov [file_dap+0x02], ax
    ;calculate root start
    xor ax, ax
    mov al, [fat_num]
    mov bx, [fat_size]
    mul bx
    add ax, [reserved_sectors]
    mov [root_start_sec], ax
    mov [file_dap+0x08], ax
    
    ;calculate data start sec
    mov ax, [root_start_sec]
    add ax, [root_size]
    mov [data_start_sec], ax
    ret

load_flp_root:
    mov ax, [root_start_sec]
    call lba_to_chs

    xor ax, ax
    mov ah, 0x02
    ;al contains the lower 8bit of [root_size]
    mov al, [root_size]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    xor bx, bx
    mov es, bx
    mov bx, 0x500
    int 0x13
    jc floppy_read_error
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

load_flp_fat:
    mov ax, [reserved_sectors]
    call lba_to_chs

    mov ah, 0x02
    mov al, [fat_size]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    xor bx, bx
    mov es, bx
    mov bx, 0x3999
    int 0x13
    jc floppy_read_error
    ret

read_flp_file:
    call flp_search_root
    call flp_load_file
    call flp_print_file
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    call print_newline
    iret

flp_search_root:
    xor di, di
    mov es, di
    mov di, 0x500
    mov dx, [root_entries]

.search_loop:
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je flp_found_file
    add di, 32
    dec dx
    jnz .search_loop

    pop bx
    mov si, filenotfound
    call print_string_red
    mov ax, kernel_seg
    mov es, ax
    iret

flp_found_file:
    mov si, file_found_str
    call print_string_green
    call print_newline

    mov ax, [es:di+0x1a]
    mov [program_cluster], ax
    ret
flp_file_err:
    pop bx
    mov si, flp_file_error
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret
flp_load_file:
    mov ax, [program_cluster]
    call cluster_to_sec     ;output = ax (LBA)
    call lba_to_chs

    mov ah, 0x02
    mov al, [sec_per_cluster]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov bx, 0x8000
    mov es, bx
    xor bx, bx
    int 0x13
    jc flp_file_err
    ret
flp_print_file:
    xor ax, ax
    mov es, ax
    mov si, file_content_str
    call print_string_cyan
    call print_newline

    mov ax, 0x8000
    mov ds, ax
    xor si, si
    mov cx, [es:di+0x1c]
    xor dx, dx
    mov bl, 0x0f

    call print_loop_flp
    ret
print_loop_flp:
    lodsb
    cmp al, 0x0a
    je flp_handle_newline
    mov ah, 0x0e
    int 0x10
    loop print_loop_flp
    ret
flp_handle_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    inc dx
    cmp dx, 28
    je flp_longfile
    jmp print_loop_flp
flp_longfile:
    xor ah, ah
    int 0x16
    cmp al, 'q'
    je print_file_done      ;ret
    xor dx, dx
    jmp print_loop_flp