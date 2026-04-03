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

;---------------------------------read a file on a floppy disk-----------------------------------------
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
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je flp_found_file
    add di, 32
    dec dx
    jnz .search_loop

    pop bx
    mov si, filenotfound
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret

flp_found_file:
    ; mov si, file_found_str
    ; call print_string_green
    ; call print_newline

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
    mov bx, 0x8000
    mov es, bx
    xor bx, bx
.loop:
    mov ax, [program_cluster]
    call cluster_to_sec     ;output = ax (LBA)
    call lba_to_chs

    mov ah, 0x02
    mov al, [sec_per_cluster]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    int 0x13
    jc flp_file_err

    mov cl, [sec_per_cluster]
    mov ax, 512
    mul cl
    add bx, ax

    mov ax, [program_cluster]
    mov cx, 3
    mul cx
    shr ax, 1      ; / 2

    mov si, fat_offset
    add si, ax

    test [program_cluster], 1
    jz .even
.odd:
    mov ax, [si]
    shr ax, 4
    jmp .done
.even:
    mov ax, [si]
    and ax, 0x0fff
.done:
    mov [program_cluster], ax
    cmp ax, 0xff8
    jb .loop
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
;----------------------------------------------write a file to a floppy disk----------------------------------------------
search_file_flp:
    push si
    xor di, di
    mov es, di
    mov di, 0x500
    mov dx, [root_entries]
search_file_flp_loop:
    mov al, [es:di]
    cmp al, 0x00
    je flp_free_entry
    cmp al, 0xe5
    je flp_free_entry

    add di, 32
    dec dx
    jnz search_file_flp_loop

    pop si
    mov si, no_entries
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret
flp_free_entry:
    mov bx, 2       ;cluster 0 and 1 are reserved
    xor ax, ax
    mov ds, ax
flp_search_fat:
    mov si, fat_offset
    mov ax, bx            ;cluster number in ax
    shl ax, 1             ;ax * 2
    add si, ax
    mov dx, [si]
    cmp dx, 0x000        ;the entries are 1.5 byte arrays
    je flp_free_cluster       ;0x000 = free entry
    inc bx
    jmp flp_search_fat
flp_free_cluster:
    mov ax, 0xff8        ;end of cluster marker
    mov dx, bx            ;copy bx into dx
    shl dx, 1             ;same as dx * 2 (cluster entry is 2 bytes long)
    mov si, fat_offset        ;adress of the FAT
    add si, dx            ;add the FAT adress our cluster number
    mov [si], ax          ;mark this FAT adress as reserved
    mov ax, kernel_seg
    mov ds, ax
    push bx
    call flp_write_fat
    call flp_get_data
    jmp flp_write_entry



flp_write_fat:
    mov ax, [reserved_sectors]
    call lba_to_chs

    mov ah, 0x03
    mov al, [fat_size]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov bx, 0x3999
    int 0x13
    jc flp_fat_error
    ret
flp_fat_error:
    pop bx
    pop si
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    mov si, fat_error_msg
    call print_string_red
    call print_newline
    iret

flp_write_root:
    mov ax, [root_start_sec]
    call lba_to_chs

    mov ah, 0x03
    mov al, [root_size]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    xor bx, bx
    mov es, bx
    mov bx, 0x500
    int 0x13
    jc flp_root_error
    ret
flp_root_error:
    pop bx
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    mov si, write_root_msg
    call print_string_red
    call print_newline
    iret


flp_get_data:
    pusha
    mov si, file_content
    call print_string_white
    mov ax, kernel_seg
    mov es, ax
    call read_string2
    mov [text_length], cx
    popa
    ret

flp_write_entry:
    xor ax, ax
    mov es, ax
    pop bx
    pop si
    push bx
    mov cx, 11
    push di
    rep movsb       ;copies [ds:si] to [es:di]
    pop di
    mov byte [es:di+0x0b], 0x20     ;archive
    
    mov [es:di+0x1a], bx            ;first cluster
    mov cx, [text_length]
    mov [es:di+0x1c], cx            ;!!!

    mov word [es:di+0x1e], 0        ;high word
    call flp_write_root
    mov si, input_buffer

    pop bx
    mov ax, bx
    call cluster_to_sec
    call lba_to_chs

    xor cx, cx
    mov ah, 0x03
    mov al, 1           ;!!! need to calculate it dynamic
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov ax, kernel_seg
    mov es, ax
    mov bx, input_buffer
    int 0x13
    jc write_sectors_error

    call print_newline
    mov si, write_success_msg
    call print_string_green
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    iret

;-----------------------delete a file from the floppy disk-----------------------------------
del_file_flp:
    call flp_search_root
    mov [es:di], 0xe5
    call flp_write_root

    mov bx, [es:di+0x1a]
    xor ax, ax
    mov ds, ax
    mov es, ax
flp_delete_loop:

    mov ax, bx          ;copy cluster into AX
    shl ax, 1
    mov si, fat_offset      ;offset
    add si, ax
    mov dx, [si]        ;next cluster

    mov word [si], 0x000
    cmp dx, 0xff8
    jae flp_delete_loop_done
    mov bx, dx
    jmp flp_delete_loop
flp_delete_loop_done:
    mov ax, kernel_seg
    mov ds, ax
    call flp_write_fat
    mov ax, kernel_seg
    mov es, ax
    mov si, delete_success
    call print_string_green
    call print_newline
    iret

ren_file_flp:
    call flp_search_root

    push di
    mov si, rename_msg
    call print_string_white

    mov ax, kernel_seg
    mov es, ax
    call read_string
    mov si, arg_buffer
    mov di, read_buffer
    xor cx, cx
    mov ah, 0x08
    int 0x22
    xor ax, ax
    mov es, ax

    call print_newline
    
    mov si, read_buffer
    pop di
    mov cx, 11
    rep movsb
    call flp_write_root
    mov ax, kernel_seg
    mov es, ax
    iret

;-------------------------------create a directory on the floppy disk---------------------------------
;-------------------------------delete a directory on the floppy disk---------------------------------