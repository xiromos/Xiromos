write_entry:
    pusha
    mov si, ok_msg
    call print_string_green
    call print_newline
    popa
    ;write filename attribute
    ;mov si, read_buffer
    mov si, file_test_txt
    mov cx, 11
    push di
    rep movsb       ;copies [ds:si] to [es:di]
    pop di
    mov byte [es:di+0x0b], 0x20     ;archive
    
    mov [es:di+0x1a], bx            ;first cluster

    mov [es:di+0x1c], word 4096          ;!!!

    mov word [es:di+0x1e], 0        ;high word
    mov si, ok_msg
    call print_string_green
    call print_newline 
    
    ; Write root directory entry to disk
    call write_root_directory
    
get_data:
    ;mov si, file_content
    ;call print_string_white
    ;mov si, read_buffer2
    mov si, test_txt
write_disk:
    pop bx
    mov ax, bx
    call cluster_to_sec

    mov [file_dap+0x08], ax
    xor bx, bx
    mov bl, [sec_per_cluster] 
    mov [file_dap+0x02], bx       ;!!! need to calculate it dynamic

    mov [file_dap+4], si         ;offset
    mov [file_dap+6], ds         ;segment

    mov si, file_dap
    call write_sectors
    mov si, write_success_msg
    call print_string_green
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    iret
write_sectors:
    mov ah, 0x43
    mov dl, [drive_number]
    int 0x13
    jc write_sectors_error
    ret
write_sectors_error:
    mov ax, kernel_seg
    mov es, ax
    mov si, write_sec_err
    call print_string_red
    call print_newline
    iret

;---------- Load root directory from disk -----------
load_root_directory:
    pusha
    mov ax, 0x0000
    mov es, ax
    
    ; Calculate root directory LBA sector
    ; LBA = reserved_sectors + (fat_size * 2)
    mov ax, [fat_size]
    mov cx, 2                   ; 2 FATs
    mul cx
    add ax, [reserved_sectors]
    
    ; Setup DAP to read root directory
    mov [file_dap+0x08], ax     ; LBA sector
    
    ; Calculate number of sectors for root directory
    mov ax, [root_entries]
    mov cx, 32
    mul cx
    mov cx, 512
    xor dx, dx
    div cx
    cmp dx, 0
    je load_root_sectors_ok
    inc ax
load_root_sectors_ok:
    mov [file_dap+0x02], ax     ; number of sectors
    
    mov [file_dap+0x04], word 0x0500  ; offset (buffer at 0x500)
    mov [file_dap+0x06], word 0x0000  ; segment
    
    mov si, file_dap
    call read_sectors
    
    mov ax, kernel_seg
    mov ds, ax
    popa
    ret

;---------- write root directory to disk -----------
write_root_directory:
    pusha
    mov ax, 0x0000
    mov es, ax
    
    ; Calculate root directory LBA sector
    ; LBA = reserved_sectors + (fat_size * 2)
    mov ax, [fat_size]
    mov cx, 2
    mul cx
    add ax, [reserved_sectors]
    
    ; Setup DAP to write root directory
    mov [file_dap+0x08], ax     ; LBA sector
    
    ; Calculate number of sectors for root directory
    mov ax, [root_entries]
    mov cx, 32
    mul cx
    mov cx, 512
    xor dx, dx
    div cx
    cmp dx, 0
    je write_root_sectors_ok
    inc ax
write_root_sectors_ok:
    mov [file_dap+0x02], ax     ; number of sectors
    
    mov [file_dap+0x04], word 0x0500  ; offset (buffer at 0x500)
    mov [file_dap+0x06], word 0x0000  ; segment
    
    mov si, file_dap
    call write_sectors
    
    mov ax, kernel_seg
    mov ds, ax
    popa
    ret

read_string2:
    mov di, read_buffer2
    xor cx, cx
read_string_loop2:
    xor ah, ah
    int 0x16
    cmp al, 0x0d
    je read_string_done
    cmp al, 0x08
    je rs_handle_backspace2
    cmp al, 'q'
    je quit_read_string
    stosb               ;store string in di
    mov ah, 0x0e
    mov bl, 0x02
    int 0x10
    inc cx
    jmp read_string_loop2
rs_handle_backspace2:
    cmp cx, 0
    je read_string_loop2
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08    ;Backspace
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_string_loop2

current_cluster: dw 0