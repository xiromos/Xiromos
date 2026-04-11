;======================================================
;Interrupt for fileoperations, designed for the kernel
;AH = 0x01: search a file in the root directory and print it    (filename in SI)
;AH = 0x02: write a file to the disk, asks for user input       (filename in SI)
;AH = 0x03: list the files of the root directory and prints it
;AH = 0x04: rename a file, asks for user input                  (filename in SI)
;AH = 0x05: delete a file                                       (filename in SI)
;AH = 0x06: change the root directory to the root directory of another drive    (drive letter in SI)
;AH = 0x08: transform a string from the name.ext format (eg: TEST.TXT) to the FAT format (eg: TEST    TXT)  (filename in SI)
;-------------------------------------------------------
;Copyright (C) 2026 Technodon 
;----------------search and read a file--------------
search_file:
    cmp byte [sub_dir], 1
    je .search_subdir
    xor ax, ax
    mov es, ax
    xor dx, dx
    mov dx, word [root_entries]
    mov di, 0x0500          ;search kernel at [ES:DI]
    jmp search_file_loop
.search_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
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
    cmp byte [es:di+0xb], 0x10
    je .directory
    jmp load_file
.directory:
    mov ax, kernel_seg
    mov es, ax
    mov si, read_dir_str
    call print_string_red
    call print_newline
    iret
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
    shl bx, 1                                   ;fat entry is 16bit
    mov ax, [0x3999+bx]                         ;read the value for the next cluster number
    mov [program_cluster], ax                   ;save the value for next cluster
;------NOT WORKING------
    ;cmp ax, 2
    ;jb invalid_cluster
    ;cmp ax, 0xFFF8                              ;check if its the last cluster
    ;jb load_file_loop
;-----------------------
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
    push si

    cmp byte [sub_dir], 1
    je .search_subdir

    xor ax, ax
    mov es, ax
    mov dx, [root_entries]
    mov di, 0x500
    jmp search_entry_loop
.search_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
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
    pop si
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
    xor ax, ax
    mov ds, ax
search_fat:
    mov si, fat_offset
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
    mov si, fat_offset        ;adress of the FAT
    add si, dx            ;add the FAT adress our cluster number
    mov [si], ax          ;mark this FAT adress as reserved
    mov ax, kernel_seg
    mov ds, ax
    push bx
    call write_fat
    jmp get_data
write_fat:
    pusha
    mov ax, [reserved_sectors]
    mov [file_dap+0x08], ax               ;LBA
    mov cx, [fat_size]
    mov [file_dap+2], cx                 ;size of FAT
    mov [file_dap+4], word fat_offset             ;offset
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
    pop si
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    mov si, fat_error_msg
    call print_string_red
    call print_newline
    iret
get_data:
    pusha
    mov si, file_content
    call print_string_white
    mov ax, kernel_seg
    mov es, ax
    call read_string2
    mov [text_length], cx
    popa
write_entry:
    ;write filename attribute
    cmp byte [sub_dir], 1
    jne .write_root
    mov ax, dir_seg
    mov es, ax
    jmp .write_entry
.write_root:
    xor ax, ax
    mov es, ax
.write_entry:
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
    cmp byte [sub_dir], 1
    je .write_subdir
    call write_root
    jmp .continue
.write_subdir:
    call write_subdir
.continue:
    mov si, input_buffer
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
    call print_newline
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
    call print_newline
    mov si, write_sec_err
    call print_string_red
    call print_newline
    iret
read_string2:
    mov di, input_buffer
    xor cx, cx
read_string_loop2:
    xor ah, ah
    int 0x16
    cmp al, 0x0d
    je read_string_done
    cmp al, 0x08
    je rs_handle_backspace2
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
read_string2_done:
    ret
write_root:
    mov ax, [root_size]
    mov [file_dap+0x02], ax
    mov [file_dap+0x04], word 0x0500
    mov [file_dap+0x06], word 0x0000
    mov ax, [root_start_sec]
    mov [file_dap+0x08], ax
    mov [file_dap+0x0a], word 0
    mov [file_dap+0x0c], word 0
    mov [file_dap+0x0e], word 0
    mov dl, [drive_number]
    mov si, file_dap
    mov ah, 0x43
    int 0x13
    jc write_root_error
    ret
write_root_error:
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    pop ax
    call print_newline
    mov si, write_root_msg
    call print_string_red
    call print_newline
    iret

write_subdir:
    push di
    mov di, dir_seg
    mov es, di
    xor di, di
    mov si, dot_str
    mov dx, 512
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

    pop di
    pop bx
    pop bx
    mov si, no_dot_str
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret

.found:
    mov ax, [es:di+0x1a]    ;cluster number
    mov [fat_cluster], ax
    pop di

    mov [file_dap+4], word 0x0000
    mov [file_dap+6], word dir_seg

.write_loop:
    mov ax, [fat_cluster]
    call cluster_to_sec

    mov [file_dap+8], ax
    xor ax, ax
    mov al, [sec_per_cluster]
    mov [file_dap+2], ax

    mov si, file_dap
    mov dl, [drive_number]
    mov ah, 0x43
    int 0x13
    jc write_root_error
    ret

text_length: dw 0
;----------------list contents of a directory------------
get_file_list:
    mov si, ls_header
    call print_string_white
    mov dx, [drive_number]
    call print_hex
    call print_newline

    cmp byte [sub_dir], 1
    je .list_subdir

    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov bx, [root_entries]
    jmp file_list_loop

.list_subdir:
    mov ax, dir_seg
    mov es, ax
    xor di, di
    jmp list_subdir_loop
file_list_loop:
    mov al, [es:di]
    cmp al, 0x00
    je empty_entry
    cmp al, 0xe5
    je empty_entry
    cmp al, ' '
    je empty_entry
    cmp al, 0x20
    jb empty_entry
    cmp al, 0x7e
    ja empty_entry

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

    cmp byte [es:di+0xb], 0x10
    jne .print_size
    mov si, dir_str
    mov bl, 0x02
    call print_start
    jmp .print_cluster
.print_size:
    mov ax, [ls_size]
    call print_decimal
.print_cluster:
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
list_subdir_loop:
    mov al, [es:di]
    cmp al, 0x00
    je .done
    cmp al, 0xe5
    je .empty_entry

    mov ax, [es:di+0x1c]
    mov [ls_size], ax
    mov ax, [es:di+0x1a]
    mov [first_cluster], ax
    cmp byte [es:di+0x0b], 0x02     ;hidden
    je .empty_entry
    push di
    mov si, di
    mov di, dir_files_buffer
    mov ax, kernel_seg
    mov es, ax
    mov cx, 8
    mov ax, dir_seg
    mov ds, ax
    rep movsb
    mov byte [di], 0
    mov ax, kernel_seg
    mov ds, ax
    mov di, extension_files_buffer
    mov cx, 3
    mov ax, dir_seg
    mov ds, ax
    rep movsb
    mov byte [di], 0
    pop di

    mov ax, kernel_seg
    mov ds, ax
    
    mov ax, dir_seg
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

    cmp byte [es:di+0xb], 0x10
    jne .print_size
    mov si, dir_str
    mov bl, 0x02
    call print_start
    jmp .print_cluster
.print_size:
    mov ax, [ls_size]
    call print_decimal
.print_cluster:
    mov cx, 12
    call print_spaces
    mov si, first_cluster_str
    call print_string_white
    mov ax, [first_cluster]
    call print_decimal
    call print_newline
.empty_entry:
    add di, 32
    dec dx
    jnz list_subdir_loop
.done:
    mov ax, kernel_seg
    mov es, ax
    iret
;--------------renames a file name----------------
rename_file_name:
    cmp byte [sub_dir], 1
    je .write_subdir

    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov dx, [root_entries]
    jmp search_root
.write_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
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
    jmp file_notfound
file_found:
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

    cmp byte [sub_dir], 1
    je .write_subdir
    jmp .write_root
.write_subdir:
    mov ax, dir_seg
    mov es, ax
    jmp .continue
.write_root:
    xor ax, ax
    mov es, ax
.continue:

    call print_newline
    
    mov si, read_buffer
    pop di
    mov cx, 11
    rep movsb
    cmp byte [sub_dir], 1
    je .update_subdir
    jmp .update_root
.update_subdir:
    call write_subdir
    jmp .done
.update_root:
    call write_root
.done:
    mov ax, kernel_seg
    mov es, ax
    iret
;---------------deletes a file------------------
search_filename:
    cmp byte [sub_dir], 1
    je .search_subdir
    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov dx, [root_entries]
    jmp search_filename_loop
.search_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
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
    cmp byte [es:di+0xb], 0x04
    je del_system_file
    mov byte [es:di], 0xe5      ;deleted file marker

    cmp byte [sub_dir], 1
    je .write_subdir
    jmp .write_root
.write_subdir:
    call write_subdir
    jmp .continue
.write_root:
    call write_root
.continue:
    mov bx, [es:di+0x1a]
    xor ax, ax
    mov ds, ax
delete_loop:
    mov ax, bx          ;copy cluster into AX
    shl ax, 1
    mov si, fat_offset      ;offset
    add si, ax
    mov dx, [si]        ;next cluster

    mov word [si], 0x0000
    cmp dx, 0xfff8
    jae delete_loop_done
    mov bx, dx
    jmp delete_loop
delete_loop_done:
    mov ax, kernel_seg
    mov ds, ax
    call write_fat
    mov ax, kernel_seg
    mov es, ax
    mov si, delete_success
    call print_string_green
    call print_newline
    iret
del_system_file:
    mov si, sys_file_str
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret
;-----------change drive------------------
change_drive:
    mov ax, [drives]
    cmp ax, 0
    je count_floppies
    jmp check_drive_number
count_floppies:
    mov ax, [floppies]
    cmp ax, 0
    jne check_drive_number
no_drive:
    mov si, no_drive_msg
    call print_string_red
    call print_newline
    iret
check_drive_number:
    xor di, di
    cmp byte [si], 0x61    ;a
    je check_floppies
    cmp byte [si], 0x41    ;A
    je check_floppies
    inc di
    cmp byte [si], 0x62
    je check_floppies
    cmp byte [si], 0x42
    je check_floppies
    cmp byte [si], 0x63     ;c
    je current_disk
    cmp byte [si], 0x43      ;C
    je current_disk
    mov di, 0x81
    cmp byte [si], 0x64
    je check_drives
    cmp byte [si], 0x44
    je check_drives
    inc di
    cmp byte [si], 0x65
    je check_drives
    cmp byte [si], 0x45
    je check_drives
no_valid_drives:
    mov si, no_valid_drive
    call print_string_red
    call print_newline
    iret
current_disk:
    mov ax, kernel_seg
    mov es, ax
    call get_bpb_data
    call reload_root
    call reload_fat
    mov si, get_bpb_ok
    call print_string_green
    call print_newline
    iret
check_floppies:
    mov ah, 0x01        ;drive number in DI
    int 0x24
    iret
check_drives:
    mov si, drive_num_str
    call print_string_white
    mov [external_drive_number], di
    mov dx, di
    call print_hex
    call print_newline

    mov ax, [drives]
    add ax, 0x80
    cmp ax, di
    jb no_valid_drives

    mov [file_dap+0x02], 1
    mov [file_dap+0x04], word 0x7c00
    mov [file_dap+0x06], word 0x9000
    mov [file_dap+0x08], 0
    mov [file_dap+0x0a], word 0
    mov [file_dap+0x0c], word 0
    mov [file_dap+0x0e], word 0
    mov si, file_dap
    mov dl, [external_drive_number]
    mov ah, 0x42
    int 0x13
    jc disk_change_err
get_external_bpb:
    mov ax, 0x9000
    mov es, ax
    mov di, 0x7c00
    mov al, byte [external_drive_number]
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
    cmp word [es:di+510], 0xaa55
    jne disk_error
    mov ax, kernel_seg
    mov es, ax
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

    mov [file_dap+0x04], word 0x0500
    mov [file_dap+0x06], word 0x0000
    mov ah, 0x42
    mov si, file_dap
    mov dl, [external_drive_number]
    int 0x13
    jc disk_change_err

    mov ax, [fat_size]
    mov [file_dap+0x02], 64
    mov [file_dap+0x04], word fat_offset
    mov [file_dap+0x06], word 0x0000
    mov ax, [reserved_sectors]
    mov [file_dap+0x08], ax
    mov [file_dap+0xa], word 0
    mov [file_dap+0xc], word 0
    mov [file_dap+0xe], word 0

    mov ah, 0x42
    mov si, file_dap
    mov dl, [external_drive_number]
    int 0x13
    jc disk_change_err
    
disk_loaded:
    mov ax, kernel_seg
    mov es, ax
    mov si, disk_loaded_msg
    call print_string_green
    call print_newline
    mov [current_dir], word 0
    mov [parent_dir], word 0
    mov [sub_dir], byte 0
    iret
disk_change_err:
    call get_bpb_data
    call reload_root
    call reload_fat
    iret

parse_arg_loop:
    mov al, [si]
    cmp al, 0       ;check for 0-terminator
    je add_spaces     ;invalid string
    cmp al, '.'     ;chech for extension
    je add_spaces
    stosb           ;stores al in ES:DI
    inc si
    inc cx
    cmp cx, 8
    jnz parse_arg_loop
add_spaces:
    cmp cx, 8
    je parse_ext
    mov al, ' '     ;fill the rest of the name with spaces to achieve 8.3 format
    stosb
    inc cx
    jmp add_spaces
parse_ext:
    cmp byte [si], '.'
    jne parse_ext_loop
    inc si
parse_ext_loop:
    xor cx, cx
.loop:
    mov al, [si]
    cmp al, 0
    je add_spaces_ext
    stosb
    inc si
    inc cx
    cmp cx, 3
    jb .loop
add_spaces_ext:
    cmp cx, 3
    je done_parse
    mov al, ' '
    stosb
    inc cx
    jmp add_spaces_ext
done_parse:
    iret

;-----------------------change directory----------------------------
change_directory:
    mov al, [si]
    cmp al, '/'
    je cd_root
    mov al, [si]
    cmp al, '-'
    je cd_parent_dir

    cmp word [sub_dir], 0
    jne .cd_subdir
    xor di, di
    mov es, di
    mov di, 0x500
    mov dx, [root_entries]
    jmp .loop

.cd_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512

.loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je .dir_found

    add di, 32
    dec dx
    jnz .loop

    mov si, filenotfound
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret

.dir_found:
    cmp byte [es:di+0xb], 0x10
    jne .no_dir

    mov ax, [es:di+0x1a]
    mov [program_cluster], ax
    jmp load_dir

.no_dir:
    mov si, no_dir_str
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret

load_dir:
    mov ax, dir_seg
    mov es, ax
    xor di, di

    mov cx, 512
    xor ax, ax
    rep stosb

    mov ax, kernel_seg
    mov es, ax

    mov [file_dap+4], word 0x0000
    mov [file_dap+6], word dir_seg
.loop:
    mov ax, [program_cluster]          ;first cluster of the program
    call cluster_to_sec                     ;get the first sector

    mov [file_dap+8], ax                 ;set LBA
    xor bx, bx
    mov bl, [sec_per_cluster]
    mov [file_dap+2], bx                 ;number of sectors to read

    mov si, file_dap
    call read_sectors

    mov cl, [sec_per_cluster]
    mov ax, 512                                 ;standard size of cluster in FAT16
    mul cl
    add [file_dap+4], ax                     ;add one cluster to the memory adress
    adc word [file_dap+6], 0                ;increase buffer for next cluster
    mov bx, [program_cluster]                   ;get the cluster-number
    shl bx, 1
    xor dx, dx
    mov ds, dx
    mov ax, [ds:fat_offset+bx]                         ;read the value for the next cluster number
    mov [program_cluster], ax                   ;save the value for next cluster
    mov dx, kernel_seg
    mov ds, dx
    cmp ax, 2
    jb invalid_cluster
    cmp ax, 0xfff8                              ;check if its the last cluster
    jb .loop
    

    mov byte [sub_dir], 1           ;true
    mov ax, kernel_seg
    mov es, ax
    mov si, changed_dir_msg
    call print_string_green
    call print_newline
    iret
cd_parent_dir:
    cmp byte [sub_dir], 0
    je .done

    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
    mov si, dot_dot_str
.loop:
    mov cx, 2
    push di
    push si
    repe cmpsb
    pop si
    pop di
    je .found

    add di, 32
    dec dx
    jnz .loop

    mov ax, kernel_seg
    mov es, ax
    mov si, no_entries
    call print_string_red
    call print_newline
    iret
.found:
    mov ax, [es:di+0x1a]
    mov [program_cluster], ax
    cmp word [es:di+0x1a], 0
    je cd_root

.load_dir:
    mov ax, [program_cluster]
    call cluster_to_sec

    mov [file_dap+8], ax
    xor cx, cx
    mov cl, [sec_per_cluster]
    mov [file_dap+2], cx
    mov [file_dap+4], word 0x0000
    mov [file_dap+6], word dir_seg

    mov dl, [drive_number]
    mov si, file_dap
    mov ah, 0x42
    int 0x13
    jc load_dir_err

    mov cl, [sec_per_cluster]
    mov ax, 512
    mul cl
    add [file_dap+4], ax
    adc [file_dap+6], 0

    mov bx, [program_cluster]
    shl bx, 1
    xor dx, dx
    mov ds, dx
    mov ax, [fat_offset+bx]
    mov dx, kernel_seg
    mov ds, dx
    mov [program_cluster], ax
    cmp ax, 0xfff8
    jb .load_dir
.done:
    mov ax, kernel_seg
    mov es, ax
    iret