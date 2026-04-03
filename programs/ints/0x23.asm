;======================================================
;file API for hard disk (LBA)
;AH = 0x01: search a file in root direcory and then copy the content into a buffer      (filename in SI, output = buffer in DI)
;AH = 0x02: write a file to the disk and its content to the disk                        (filename in SI, buffer (with content) in DI, length of buffer in CX)
;------------------------------------------------------
;Copyright (C) 2026 Technodon
;======================================================
openfile:
    push di
    xor ax, ax
    mov es, ax
    mov ax, kernel_seg
    mov ds, ax
    xor dx, dx
    mov dx, word [root_entries]
    mov di, 0x0500          ;search kernel at [ES:DI]
openfile_loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je openfile_done
    add di, 32
    dec dx
    jnz openfile_loop
    pop di
    mov ax, 0x5000
    mov es, ax
    mov ds, ax
    mov cx, 0x67
    iret
openfile_done:
    mov cx, [es:di+0x1c]
    mov di, [es:di+0x01a]
    mov [program_cluster], di
    push cx
    mov [program_dap+4], word 0x0000
    mov [program_dap+6], word 0x8000        ;load file at 0x8000:0x0000
.loadfile:

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
    pop cx
    pop di
    call read_sectors
    push di
    push cx

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
    ;jb .loadfile
;-----------------------

    mov ax, 0x8000
    mov ds, ax
    mov ax, 0x5000
    mov es, ax
    pop cx
    pop di
    mov si, 0x0000
    call copy_filebuffer
    jmp copyfile_done
copy_filebuffer:
    lodsb
    cmp al, 0x0a
    je newline            ;handle carriage return and line feed
    stosb
    loop copy_filebuffer    ;CX--
    ret
newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    stosb
    jmp copy_filebuffer
copyfile_done:
    mov ax, 0x5000
    mov ds, ax
    mov es, ax
    call print_newline
    iret

;--------------------------write file to the disk--------------------------------------
api_write_file:
    push si
    mov [text_length], cx
    xor ax, ax
    mov ds, ax
    mov [buffer_adress], di
    mov ax, kernel_seg
    mov ds, ax

    xor di, di
    mov es, di
    mov di, 0x500
    mov dx, [root_entries]

api_search_root:
    mov al, [es:di]
    cmp al, 0x00
    je .free_entry
    cmp al, 0xe5
    je .free_entry

    add di, 32
    dec dx
    jnz api_search_root

    pop di
    pop si
    mov ax, 0x5000
    mov es, ax
    mov si, no_entries
    call print_string_red
    call print_newline
    iret

.free_entry:
    mov ax, [es:di+0x1a]
    mov [fat_cluster], ax

    ;calculate clusters
    mov ax, 512
    div cx
    mov cx, ax
    mov ax, [sec_per_cluster]
    div cx
    mov cx, ax

    mov bx, 2       ;cluster 0 and 1 are reserved
    xor ax, ax
    mov ds, ax
    push di
api_search_fat:
    mov si, fat_offset
    mov ax, bx            ;cluster number in ax
    shl ax, 1             ;ax * 2
    add si, ax
    mov dx, [si]
    cmp dx, 0x0000        ;the entries are 2byte arrays
    je .free_cluster       ;0x0000 = free entry
    inc bx
    jmp api_search_fat

.free_cluster:
    cmp di, 0
    je .first_cluster
    cmp word [first_cluster], 0
    jne .continue
    mov [first_cluster], bx

.continue:
    mov ax, di        ;end of cluster marker
    shl ax, 1             ;same as dx * 2 (cluster entry is 2 bytes long)
    mov si, fat_offset        ;adress of the FAT
    add si, ax            ;add the FAT adress our cluster number
    mov [si], bx          ;mark this FAT adress as reserved
.first_cluster:
    mov di, bx      ;save cluster
    push si
    mov si, [buffer_adress]
    call api_write_sectors
    pop si

    dec cx
    jz .done

    inc bx
    jmp api_search_fat

.last_cluster:
    mov ax, di
    shl ax, 1
    mov si, fat_offset
    add si, ax
    mov word [si], 0xfff8
    jmp api_search_fat
.done:
    pop di
    call write_fat

    mov ax, kernel_seg
    mov ds, ax
    xor ax, ax
    mov es, ax

    pop si
    mov cx, 11
    push di
    rep movsb
    pop di
    mov byte [es:di+0x0b], 0x20     ;archive
    
    mov bx, [first_cluster]
    mov [es:di+0x1a], bx
    mov cx, [text_length]
    mov [es:di+0x1c], cx

    mov word [es:di+0x1e], 0        ;high word
    call write_root
    mov ax, kernel_seg
    mov es, ax
    iret
api_write_sectors:
    mov si, di
    mov ax, bx
    call cluster_to_sec
    mov [file_dap+8], ax
    mov ax, [sec_per_cluster]
    mov [file_dap+2], ax
    mov [file_dap+4], si
    mov [file_dap+6], ds
    
    mov ah, 0x43
    mov si, file_dap
    int 0x13
    jc api_write_disk_error
    ret

api_write_disk_error:
    pop si
    pop di
    mov ax, kernel_seg
    mov ds, ax
    mov es, ax
    call print_newline
    mov si, write_sec_err
    call print_string_red
    call print_newline
    iret