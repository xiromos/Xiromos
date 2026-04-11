;===============================================
;FAT8 file operations
;AH = 0x01: read file
;-----------------------------------------------
;Copyright (C) 2026 Technodon
;===============================================

fat8_read_file:
    xor ax, ax
    mov es, ax
    xor dx, dx
    mov dx, word [root_entries]
    mov di, 0x0500          ;search kernel at [ES:DI]
.loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je .done
    add di, 32
    dec dx
    jnz .loop
    jmp .no_file
.done:
    mov al, [es:di+0x1a]
    mov [cluster8], al
    jmp fat8_load_file
.no_file:
    mov ax, kernel_seg
    mov es, ax
    mov si, filenotfound
    call print_string_red
    call print_newline
    iret

fat8_load_file:
    mov bx, 0x8000
    mov es, bx
    xor bx, bx
.loop:

    movzx ax, byte [cluster8]
    call cluster_to_sec                     ;get the first sector
    call lba_to_chs

    mov ah, 0x02
    mov al, [sec_per_cluster]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    int 0x13
    jc disk_error

    add bx, 512                   ;save the value for next cluster
    
    movzx ax, byte [cluster8]
    xor dx, dx
    mov ds, dx
    mov si, fat_offset
    add si, ax
    mov al, [si]
    mov [cluster8], al
    mov dx, kernel_seg
    mov ds, dx
    cmp al, 0xf8
    jb .loop

    mov si, file_found_str
    call print_string_green
    call print_newline
    mov si, file_content_str
    call print_string_cyan
    call print_newline
fat8_print_file:
    mov ax, 0x8000
    mov ds, ax
    xor ax, ax
    mov es, ax
    mov cx, [es:di+0x1c]
    call print_file_loop_start

    mov ax, kernel_seg
    mov ds, ax
    mov es, ax
    call print_newline
    iret


;===================================== write file ====================================
fat8_write_file:
    push si
    xor ax, ax
    mov es, ax
    mov dx, [root_entries]
    mov di, 0x500
.loop:
    mov al, [es:di]
    cmp al, 0x00                ;0x00 = free entry
    je .free_entry
    cmp al, 0xe5                ;0xe5 = deleted file (free entry)
    je .free_entry
    add di, 32
    dec dx
    jnz .loop

    ;no free entries
    pop si
    mov ax, kernel_seg
    mov es, ax
    mov si, no_entries
    call print_string_red
    call print_newline
    iret
.free_entry:
    ;[es:di] = free entry
    xor bx, bx
    xor dx, dx
    mov bl, 2       ;cluster 0 and 1 are reserved
    xor ax, ax
    mov ds, ax
flp8_search_fat:
    mov si, fat_offset
    add si, bx
    mov dl, [si]
    cmp dl, 0x00        ;entries are 1 byte
    je fat8_free_cluster       ;0x00 = free entry
    inc bl
    jmp flp8_search_fat
fat8_free_cluster:
    ;bx = first cluster
    mov al, 0xf8        ;end of cluster marker
    mov dl, bl            ;copy bx into dx
    mov si, fat_offset        ;adress of the FAT
    add si, dx            ;add the FAT adress our cluster number
    mov [si], al          ;mark this FAT adress as reserved
    mov ax, kernel_seg
    mov ds, ax
    xor ax, ax
    mov es, ax
    push bx
    call flp_write_fat

    mov si, file_content
    call print_string_white
    mov ax, kernel_seg
    mov es, ax
    push di
    call read_string2
    pop di
    mov [text_length], cx


    ;write filename attribute
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

    mov [es:di+0x1a], bl            ;first cluster

    mov cx, [text_length]
    mov [es:di+0x1c], cx            ;!!!

    mov word [es:di+0x1e], 0        ;high word
    call flp_write_root

    pop bx
    movzx ax, bl
    call cluster_to_sec
    call lba_to_chs

    mov ah, 0x03
    mov al, [sec_per_cluster]
    mov ch, [absolute_cylinder]
    mov cl, [absolute_sector]
    mov dh, [absolute_head]
    mov dl, [drive_number]
    mov bx, kernel_seg
    mov es, bx
    mov bx, input_buffer
    int 0x13
    jc .write_error
    call print_newline
    mov si, write_success_msg
    call print_string_green
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret
.write_error:
    call print_newline
    mov si, write_sec_err
    call print_string_red
    call print_newline
    iret

;=================================== delete a file =========================================

fat8_delete_file:
    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov dx, [root_entries]
.loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je .found

    add di, 32
    dec dx
    jnz .loop

    mov ax, kernel_seg
    mov es, ax
    mov si, filenotfound
    call print_string_red
    call print_newline
    iret

.found:
    mov byte [es:di], 0xe5

    mov bl, byte [es:di+0x1a]
    xor ax, ax
    mov ds, ax

.delete:
    mov al, bl
    mov si, fat_offset
    add si, ax
    mov al, [si]
    
    mov byte [si], 0x00
    cmp al, 0xf8
    jae .done
    mov bl, al
    jmp .delete

.done:
    mov ax, kernel_seg
    mov ds, ax
    call flp_write_root
    call flp_write_fat
    mov ax, kernel_seg
    mov es, ax
    mov si, delete_success
    call print_string_green
    call print_newline
    iret

