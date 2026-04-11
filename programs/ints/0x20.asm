;======================================================
;Interrupt for loading and executing a program from the root directory
;Expects the filename in FAT format (eg: "CALC    BIN") in SI
;loads the program at 0x5000:0x0000
;----------------------------------
;Copyright (C) 2026 Technodon
;======================================================
search_program:
    cmp byte [sub_dir], 1
    je .search_subdir

    xor ax, ax
    mov es, ax
    xor dx, dx
    mov dx, [root_entries]
    mov di, 0x0500          ;search kernel at [ES:DI]
    jmp search_program_loop
.search_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
search_program_loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je search_program_done
    add di, 32
    dec dx
    jnz search_program_loop
    jmp program_notfound
search_program_done:
    mov di, [es:di+0x01a]
    mov [program_cluster], di
load_program:
    mov [program_dap+4], word 0x0000
    mov [program_dap+6], word 0x5000        ;0x1000*16+0x0000 = 10000
load_programs_loop:
    ;mov si, ok_msg
    ;call print_string_green
    ;call print_newline

    mov ax, word [program_cluster]          ;first cluster of the program
    call cluster_to_sec                     ;get the first sector
    mov [program_dap+8], ax                 ;set LBA
    xor bx, bx
    mov bl, [sec_per_cluster]
    mov [program_dap+2], bx                 ;number of sectors to read
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
    mov ax, [fat_offset+bx]                         ;read the value for the next cluster number
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
    call far 0x5000:0x0000
    mov ax, kernel_seg
    mov es, ax
    mov ds, ax
    call print_newline
    iret
read_sectors:
    mov ah, 0x42                ;BIOS extended read
    mov dl, [drive_number]              ;!!!
    int 0x13
    jc disk_error
    ret
cluster_to_sec:
;FirstSectorOfCluster = (cluster - 2) * BPB_SectorsPerCluster + DataStartSector
    sub ax, 2
    xor cx, cx 
    mov cl, [sec_per_cluster]
    mul cx
    add ax, word [data_start_sec]
    ret
invalid_cluster:
    mov ax, kernel_seg
    mov es, ax
    mov si, filecluster_notfound
    call print_string_red
    call print_newline
    iret
disk_error:
    mov ax, kernel_seg
    mov es, ax
    mov si, disk_error_msg
    call print_string_red
    call print_newline
    iret

reload_root:
    mov ax, [root_size]
    mov [program_dap+0x02], ax
    mov [program_dap+0x04], word 0x0500
    mov [program_dap+0x06], word 0x0000
    mov ax, [root_start_sec]
    mov [program_dap+0x08], ax

    call reload_sectors
    ret
reload_fat:
    mov ax, [fat_size]
    mov [program_dap+0x02], ax
    mov [program_dap+0x04], word fat_offset
    mov [program_dap+0x06], word 0x0000
    mov ax, [reserved_sectors]
    mov [program_dap+0x08], ax          ;!!! no calculating of hidden sectors

    call reload_sectors
    ret
reload_sectors:
    mov ah, 0x42
    mov dl, [drive_number]
    mov si, program_dap
    int 0x13
    jc rsod         ;emergency restart
    ret

program_notfound:
    xor ax, ax
    mov es, ax
    mov di, 0x500
    mov dx, [root_entries]
    push si
    mov si, dir_programs
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
    pop si
.not_found:
    mov si, programnotfound_str
    call print_string_red
    call print_newline
    mov ax, kernel_seg
    mov es, ax
    iret

.found:
    mov ax, [es:di+0x1a]
    mov [program_cluster], ax
    cmp byte [es:di+0xb], 0x10
    jne .not_found

    mov [file_dap+4], word 0x0000
    mov [file_dap+6], word 0x8000

.load:
    mov ax, [program_cluster]
    call cluster_to_sec
    mov [file_dap+8], ax

    xor cx, cx
    mov cl, [sec_per_cluster]
    mov [file_dap+2], cx

    mov si, file_dap
    mov ah, 0x42
    mov dl, [drive_number]
    int 0x13
    pop si
    jc .not_found
    push si

    mov cl, [sec_per_cluster]
    mov ax, 512                                 ;standard size of cluster in FAT16
    mul cl
    add [program_dap+4], ax                     ;add one cluster to the memory adress
    adc word [program_dap+6], 0                ;increase buffer for next cluster
    mov bx, [program_cluster]                   ;get the cluster-number
    shl bx, 1                                   ;fat entry is 16bit
    xor dx, dx
    mov ds, dx
    mov ax, [fat_offset+bx]                         ;read the value for the next cluster number
    mov dx, kernel_seg
    mov ds, dx
    mov [program_cluster], ax                   ;save the value for next cluster
    
    cmp ax, 2
    jb invalid_cluster
    cmp ax, 0xFFF8                              ;check if its the last cluster
    jb load_file_loop

    mov di, 0x8000
    mov es, di
    xor di, di
    mov dx, 512
    pop si

.search_loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je search_program_done
    add di, 32
    dec dx
    jnz .search_loop

    jmp .not_found