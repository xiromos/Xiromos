;======================================================
;interrupt for reading and writing from a FAT12 formatted floppy disk
;AH = 0x01: load root directory and FAT from the floppy into memory
;AH = 0x02: read a file from the floppy disk            (filename in SI)
;AH = 0x03: write a max. 512 byte file to the disk      (filename in SI)
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
    mov bx, fat_offset
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

    add bx, 512

    mov ax, [program_cluster]
    mov cx, 3
    mul cx
    shr ax, 1      ; / 2
    mov cx, [program_cluster]

    xor dx, dx
    mov ds, dx
    mov si, fat_offset
    add si, ax
    mov ax, [si]

    test cx, 1
    jz .even
.odd:
    shr ax, 4
    jmp .done
.even:
    and ax, 0x0fff
.done:
    mov dx, kernel_seg
    mov ds, dx
    mov word [program_cluster], ax
    cmp ax, 0x0ff0
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
    ;writes only one cluster! (512 bytes)
    mov bx, 2       ;cluster 0 and 1 are reserved
.loop:
    mov ax, bx
    mov cx, bx
    shr cx, 1       ; bx / 2
    add ax, cx      ;ax * 1.5
    xor dx, dx
    mov ds, dx
    mov si, fat_offset
    add si, ax

    test bx, 1
    jz .even_cluster
.odd:
    mov ax, [si]
    shr ax, 4
    jmp .done_search
.even_cluster:
    mov ax, [si]
    and ax, 0x0fff
.done_search:
    cmp ax, 0x000
    je flp_free_cluster
    inc bx
    jmp .loop
flp_free_cluster:
    test bx, 1
    jnz .mark_odd_cluster

.mark_even_cluster:
    mov al, [si]
    mov ah, [si+1]
    and ah, 0xf0
    or al, 0xff

    mov [si], al
    mov [si+1], ah
    jmp .done_marker
.mark_odd_cluster:
    and al, 0x0f
    or al, 0xf0
    mov ah, 0xff

    mov [si], al
    mov [si+1], ah
.done_marker:
    mov ax, kernel_seg
    mov ds, ax
    mov [fat_cluster], bx
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
    mov bx, fat_offset
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
    pop si
    mov cx, 11
    push di
    rep movsb       ;copies [ds:si] to [es:di]
    pop di
    mov byte [es:di+0x0b], 0x20     ;archive
    
    mov bx, [fat_cluster]
    mov [es:di+0x1a], bx            ;first cluster
    mov cx, [text_length]
    mov [es:di+0x1c], cx            ;!!!

    mov word [es:di+0x1e], 0        ;high word
    call flp_write_root

    mov ax, [fat_cluster]
    call cluster_to_sec
    call lba_to_chs

    xor cx, cx
    mov ah, 0x03
    mov al, [sec_per_cluster]           ;!!! need to calculate it dynamic
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov bx, kernel_seg
    mov es, bx
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
flp_delete_loop:

    mov ax, bx          ;copy cluster into AX
    shr ax, 1           ; ax / 2
    add ax, bx
    
    mov si, fat_offset
    add si, ax
    mov ax, [si]
    test bx, 1
    jz .even
.odd:
    shr ax, 4
    jmp .next_entry
.even:
    and ax, 0x0fff
.next_entry:
    mov dx, ax          ;save cluster
    test bx, 1
    jz .clear_even
.clear_odd:
    mov ax, [si]
    and ax, 0x000f
    mov [si], ax
    jmp .continue
.clear_even:
    mov ax, [si]
    and ax, 0xf000
    mov [si], ax
.continue:
    mov bx, dx
    cmp bx, 0x0ff0
    jb flp_delete_loop
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
;-----------------------------------------rename a file of the floppy disk----------------------------------
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
;------------------------------------------start a program on the floppy disk-----------------------------------
flp_search_program:
    xor di, di
    mov es, di
    mov di, 0x500
    mov dx, [root_entries]
flp_search_program_loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je flp_program_found

    add di, 32
    dec dx
    jnz flp_search_program_loop

    ;....search program in other directories....
    mov ax, kernel_seg
    mov es, ax
    mov si, programnotfound_str
    call print_string_red
    call print_newline
    iret

flp_program_found:
    mov ax, [es:di+0x1a]
    mov [program_cluster], ax

    mov ax, 0x5000
    mov es, ax
    xor bx, bx

.loop:
    mov ax, [program_cluster]
    call cluster_to_sec
    call lba_to_chs

    mov ah, 0x02
    mov al, [sec_per_cluster]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    int 0x13
    jc disk_error

    add bx, 512

    mov ax, [program_cluster]
    mov cx, 3
    mul cx
    shr ax, 1      ; / 2

    xor dx, dx
    mov ds, dx
    mov si, fat_offset
    add si, ax
    mov ax, [si]

    push bx
    mov bx, [program_cluster]
    test bl, 1
    pop bx
    jz .even
.odd:
    shr ax, 4
    jmp .done
.even:
    and ax, 0x0fff
.done:
    mov dx, kernel_seg
    mov ds, dx
    mov word [program_cluster], ax
    cmp ax, 0x0ff0
    jb .loop

    call far 0x5000:0x0000
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    call print_newline
    iret
;-------------------------------create a directory on the floppy disk---------------------------------
;-------------------------------delete a directory on the floppy disk---------------------------------