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
    mov [program_dap+6], word 0x5000        ;load file at 0x5000:0x0000 (same as the programs)
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
    mov ax, 0x5000
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
    inc bx                ;0xFFF8 < ... filled entries
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
    push ax
    mov ax, kernel_seg
    mov ds, ax
    pop ax
    call write_fat
    jmp write_entry
write_fat:
    pusha
    mov [file_dap+0x08], 1               ;LBA
    mov cx, [fat_size]
    mov [file_dap+2], cx                 ;size of FAT !!!
    mov [file_dap+4], 0x3999             ;offset
    mov [file_dap+6], 0x0000             ;segment

    mov dl, 0x80            ;!!! cant replace it with drive_number because ds isnt set to the kernel segment

    mov si, file_dap
    mov ah, 0x43
    int 0x13
    jc write_fat_error
    popa
    ret
write_fat_error:
    popa
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

    mov [es:di+0x1c], 512

    mov word [es:di+0x1e], 0        ;high word
    mov si, ok_msg
    call print_string_green
    call print_newline 
get_data:
    mov si, file_content
    call print_string_white
    pusha
    push di
    ;call read_string2
    pop di
    popa
    call print_newline
    ;mov si, read_buffer2
    mov si, test_txt
write_disk:
    mov ax, bx
    call cluster_to_sec

    mov [file_dap+0x08], ax
    mov [file_dap+0x02], 1       ;1 sector !!! change it to calculate the sector amount

    mov [file_dap+4], si         ;offset
    mov [file_dap+6], ds         ;segment

    mov si, file_dap
    call write_sectors
    mov si, write_success_msg
    call print_string_green
    call print_newline
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

file_test_txt db "TEST    TXT"
test_txt: db 'Success!'
;----------------list contents of a directory------------
get_file_list:
    xor ax, ax
    mov es, ax
    mov dx, [root_entries]
    mov di, 0x500
file_list_loop:
    mov al, [es:di]
    cmp al, 0x00
    je empty_entry
    cmp al, 0xe5
    je empty_entry

    push di
    push es
    push es
    pop ds
    mov si, di
    mov di, dir_files_buffer
    mov cx, 11
    rep movsb       ;[ds:si] = [es:di]
    cmp dx, 0
    je add_null_terminator
    pop es
    pop di

    mov ax, kernel_seg
    mov ds, ax

    add di, 32
    dec dx
    cmp dx, 0
    jnz file_list_loop
    jmp print_file_names
empty_entry:
    add di, 32
    dec dx
    cmp dx, 0
    jnz file_list_loop
add_null_terminator:
    mov byte [di], 0
    mov [dir_files_buffer], di
    pop es
    pop di    
print_file_names:
    mov si, dir_files_buffer
    call print_string_white
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret
