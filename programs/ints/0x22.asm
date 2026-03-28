;================READ OR WRITE A FILE================
;----------------search and read a file--------------
search_file:
    xor ax, ax
    mov es, ax
    xor dx, dx
    mov dx, word [root_entries]
    mov di, 0x0500          ;search kernel at [ES:DI]
search_file_loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je search_file_done
    add di, 32
    dec dx
    jnz search_file_loop
    jmp file_notfound
search_file_done:
    push di
    mov di, [es:di+0x01a]
    mov [program_cluster], di
    pop di
    jmp load_file
file_notfound:
    mov ax, kernel_seg
    mov es, ax
    mov si, filenotfound
    call print_string_red
    call print_newline
    iret
load_file:
    mov [program_dap+4], word 0x0000
    mov [program_dap+6], word 0x8000        ;load file at 0x8000:0x0000
load_file_loop:
    ;mov si, ok_msg
    ;call print_string_green
    ;call print_newline

    mov ax, word [program_cluster]          ;first cluster of the program
    call cluster_to_sec                     ;get the first sector
    mov [program_dap+8], ax                 ;set LBA
    xor bx, bx
    mov bl, [sec_per_cluster]
    mov [program_dap+2], bl                 ;number of sectors to read
    mov word [program_dap+10], 0            ;fill the rest of the LBA field with zeros
    mov word [program_dap+12], 0
    mov word [program_dap+14], 0
    mov si, program_dap
    call read_sectors

    mov cl, [sec_per_cluster]
    mov ax, 512                                 ;standard size of cluster in FAT16
    mul cl
    add [program_dap+4], ax                     ;add one cluster to the memory adress
    adc word [program_dap+6], 0                ;increase buffer for next cluster
    mov bx, [program_cluster]                   ;get the cluster-number
    shl bx, 1                                   ;multiply it by 2, because [cluster] is 16-bit, but a FAT entry is 32bit
    mov ax, [0x3999+bx]                         ;read the value for the next cluster number
    mov [program_cluster], ax                   ;save the value for next cluster
;------NOT WORKING------
    ;cmp ax, 2
    ;jb invalid_cluster
    ;cmp ax, 0xFFF8                              ;check if its the last cluster
    ;jb load_programs_loop
;-----------------------                    ;!!!! you could get the file size at offset 0x1c, calculate how much sectors this is and then load them!!!!
    ;mov si, ok_msg
    ;call print_string_green
    ;call print_newline
    mov si, file_found_str
    call print_string_green
    call print_newline
    mov si, file_content_str
    call print_string_cyan
    call print_newline
print_file_start:
    mov ax, 0x8000
    mov ds, ax
    mov cx, [es:di+0x1c]
    call print_file_loop_start
    jmp read_file_done
print_file_loop_start:
    mov si, 0x0000
    mov bl, 0x0f
    xor dx, dx
print_file_loop:
    lodsb
    cmp al, 0x0a
    je handle_lf            ;handle carriage return and line feed
    mov ah, 0x0e
    int 0x10
    loop print_file_loop    ;CX--
print_file_done:
    ret
handle_lf:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    inc dx
    cmp dx, 28
    je long_file
    jmp print_file_loop
long_file:
    xor ah, ah
    int 0x16
    cmp al, 'q'
    je print_file_done
    xor dx, dx
    jmp print_file_loop
read_file_done:
    mov ax, kernel_seg
    mov ds, ax
    mov es, ax
    call print_newline
    iret
;----------------write a file to the disk------------
search_entry:
    xor ax, ax
    mov es, ax
    mov dx, [root_entries]
    mov di, 0x500
search_entry_loop:              ;searching the root directory
    mov al, [es:di]             ;for a free entry
    cmp al, 0x00                ;0x00 = free entry
    je free_entry
    cmp al, 0xe5                ;0xe5 = deleted file (free entry)
    je free_entry
    add di, 32                  ;one root directory entry is 32bytes, we need to add 32 to get to the next one
    dec dx
    jnz search_entry_loop

    ;no free entries
    mov ax, kernel_seg
    mov es, ax
    mov si, no_entries
    call print_string_red
    call print_newline
    iret
free_entry:
    ;[es:di] = free entry
    mov si, entry_found
    call print_string_green
    call print_newline
    mov bx, 2       ;cluster 0 and 1 are reserved
    push ax
    xor ax, ax
    mov ds, ax
    pop ax
search_fat:
    mov si, 0x3999
    mov ax, bx            ;cluster number in ax
    shl ax, 1             ;ax * 2
    add si, ax
    mov dx, [si]
    cmp dx, 0x0000        ;the entries are 2byte arrays
    je free_cluster       ;0x0000 = free entry
    inc bx
    jmp search_fat
file_dap:
    db 0x10
    db 0
    dw 0
    dw 0
    dw 0
    dq 0
free_cluster:
    ;bx = first cluster
    mov ax, 0xfff8        ;end of cluster marker
    mov dx, bx            ;copy bx into dx
    shl dx, 1             ;same as dx * 2 (cluster entry is 2 bytes long)
    mov si, 0x3999        ;adress of the FAT
    add si, dx            ;add the FAT adress our cluster number
    mov [si], ax          ;mark this FAT adress as reserved
    mov ax, kernel_seg
    mov ds, ax
    push bx
    call write_fat
    jmp write_entry
write_fat:
    pusha
    mov ax, [reserved_sectors]
    mov [file_dap+0x08], ax               ;LBA
    mov cx, [fat_size]
    mov [file_dap+2], cx                 ;size of FAT
    mov [file_dap+4], word 0x3999             ;offset
    mov [file_dap+6], word 0x0000             ;segment

    mov dl, [drive_number]               

    mov si, file_dap
    mov ah, 0x43
    int 0x13
    jc write_fat_error
    popa
    ret
write_fat_error:
    popa
    pop bx
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    mov si, fat_error_msg
    call print_string_red
    call print_newline
    iret
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

    mov [es:di+0x1c], word 4096     ;!!!

    mov word [es:di+0x1e], 0        ;high word
    call write_root
    mov si, ok_msg
    call print_string_green
    call print_newline 
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
write_root:
    mov ax, [root_size]
    mov [file_dap+0x02], ax
    mov [file_dap+0x04], word 0x0500
    mov [file_dap+0x06], word 0x0000
    mov ax, [root_start_sec]
    mov [file_dap+0x08], ax
    mov [file_dap+0x0a], 0

    mov dl, [drive_number]
    mov si, file_dap
    mov ah, 0x43
    int 0x13
    jc write_root_error
    ret
write_root_error:
    mov si, write_root_msg
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    iret
current_cluster: dw 0
;----------------list contents of a directory------------
get_file_list:
    mov si, ls_header
    call print_string_white
    call print_newline
    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov bx, [root_entries]
file_list_loop:
    mov al, [es:di]
    cmp al, 0x00
    je empty_entry
    cmp al, 0xe5
    je empty_entry

    mov ax, [es:di+0x1c]
    mov [ls_size], ax
    mov ax, [es:di+0x1a]
    mov [first_cluster], ax
    push di
    mov si, di
    mov di, dir_files_buffer
    mov ax, kernel_seg
    mov es, ax
    mov cx, 8
    xor ax, ax
    mov ds, ax
    rep movsb
    mov byte [di], 0
    mov ax, kernel_seg
    mov ds, ax
    mov di, extension_files_buffer
    mov cx, 3
    xor ax, ax
    mov ds, ax
    rep movsb
    mov byte [di], 0
    pop di

    mov ax, kernel_seg
    mov ds, ax
    
    xor ax, ax
    mov es, ax
    mov si, dir_files_buffer
    call print_string_white
    mov ah, 0x0e
    mov al, '.'
    int 0x10
    mov si, extension_files_buffer
    call print_string_white
    mov cx, 3
    call print_spaces

    mov ax, [ls_size]
    call print_decimal
    mov cx, 12
    call print_spaces
    mov si, first_cluster_str
    call print_string_white
    mov ax, [first_cluster]
    call print_decimal
    call print_newline
empty_entry:
    add di, 32
    dec bx
    jnz file_list_loop

    mov ax, kernel_seg
    mov es, ax
    iret
print_spaces:
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    loop print_spaces
    ret
;--------------renames a file name----------------
rename_file_name:
    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov dx, [root_entries]
search_root:
    mov cx, 11
    push di
    push si
    repe cmpsb
    pop si
    pop di
    je file_found
    add di, 32
    dec dx
    jnz search_root
    call print_newline
    jmp file_notfound
file_found:
    push di
    call print_newline
    mov si, rename_msg
    call print_string_white

    mov ax, kernel_seg
    mov es, ax
    call read_string
    xor ax, ax
    mov es, ax

    call print_newline
    
    mov si, read_buffer
    pop di
    mov cx, 11
    rep movsb
    call write_root
    mov ax, kernel_seg
    mov es, ax
    iret
;---------------deletes a file------------------
search_filename:
    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov dx, [root_entries]
search_filename_loop:
    mov cx, 11
    push di
    push si
    repe cmpsb
    pop si
    pop di
    je delete_object
    add di, 32
    dec dx
    jnz search_filename_loop
    jmp file_notfound
delete_object:
    mov byte [es:di], 0xe5      ;deleted file marker
    call write_root
    mov bx, [es:di+0x1a]

delete_loop:
    cmp bx, 0x0000
    je delete_loop_done
    mov ax, bx          ;copy cluster into AX
    shl ax, 1
    mov si, 0x3999      ;offset
    add si, ax
    mov dx, [si]        ;next cluster

    mov word [si], 0x0000
    cmp dx, 0xfff8
    jae delete_loop_done
    mov bx, dx
    jmp delete_loop
delete_loop_done:
    call write_fat
    mov ax, kernel_seg
    mov es, ax
    call print_newline
    mov si, delete_success
    call print_string_green
    call print_newline
    iret
file_test_txt: db "TEST    TXT"
test_txt db 'Success!'