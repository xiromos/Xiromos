;==============================================
;Program to show hardware information
;Copyright (C) 2026 Technodon
;==============================================


bits 16
[org 0x0000]


start:
    cli
    mov ax, 0x5000
    mov ds, ax
    mov es, ax
    sti

    mov ax, 0x03
    int 0x10

    call set_video_mode
    mov si, title_msg
    call print_start
    call print_newline
    call print_newline

    call detect_memory
    call detect_cpu
    call detect_cpu_features
    call print_cores

    call print_newline
    call detect_drives
    call print_sectors
    call print_newline

    mov si, quit_msg
    call print_start

    jmp quit

print_start:
    mov ah, 0x0e
    mov bl, 0x0f
print_loop:
    lodsb
    cmp al, 0
    je done_print
    int 0x10
    jmp print_loop
done_print:
    ret
print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret
print_start_green:
    mov ah, 0x0e
    mov bl, 0x0a
    jmp print_loop
set_video_mode:
    ; VGA 640*480, 16 colors
    mov ax, 0x12
    int 0x10
    ret
detect_memory:
    ;base memory
    mov si, mem_base_str
    call print_start
    int 12h         
    mov [base_mem_kb], ax
    call print_decimal
    call print_k_suffix

    mov si, mem_ext2_label
    call print_start
    int 0x15
    jc .no_e801
    mov [ext2_mem_16k_blocks], cx
    mov [ext2_mem_64k_blocks], dx
    mov dx, 0
    mov ax, [ext2_mem_64k_blocks]
    mov cx, 16
    div cx
    mov [ext2_mem_mb], ax
    call print_decimal
    call print_M_suffix
    jmp sum_total

.no_e801:
    mov si, not_supported_str
    call print_start
    mov word [ext2_mem_mb], 0
    
    sum_total:
    mov si, mem_total_label
    call print_start
    mov eax, 0
    movzx ebx, word [base_mem_kb]
    add eax, ebx
    movzx ebx, word [ext_mem_kb]
    add eax, ebx
    movzx ebx, word [ext2_mem_mb]
    mov ecx, 1024
    imul ebx, ecx
    add eax, ebx
    mov edx, 0
    mov ecx, 1024
    div ecx
    call print_decimal
    call print_M_suffix
    ret

print_decimal:
    pusha
    mov cx, 0
    mov ebx, 10
.div_loop:
    mov edx, 0
    div ebx
    push edx
    inc cx
    cmp eax, 0
    jne .div_loop
.print_loop:
    pop eax
    add al, '0'
    mov ah, 0x0e
    int 0x10
    loop .print_loop
    popa
    ret
print_k_suffix:
    pusha
    mov si, k_str
    call print_start
    call print_newline
    popa
    ret
print_M_suffix:
    pusha
    mov si, M_str
    call print_start
    call print_newline
    popa
    ret
detect_drives:
    mov si, hdd_label
    call print_start
    push es
    mov ax, 0x0040
    mov es, ax
    mov al, [es:0x0075]
    mov ah, 0
    pop es
    call print_decimal
    call print_newline
    ret
detect_cpu:
    mov si, cpu_vendor_label
    call print_start
    mov eax, 0
    cpuid
    mov [cpu_vendor_str+0], ebx
    mov [cpu_vendor_str+4], edx
    mov [cpu_vendor_str+8], ecx
    mov si, cpu_vendor_str
    call print_start_green
    call print_newline

    mov si, cpu_desc_label
    call print_start
    mov eax, 0x80000002
    cpuid
    mov [cpu_type_str+0], eax
    mov [cpu_type_str+4], ebx
    mov [cpu_type_str+8], ecx
    mov [cpu_type_str+12], edx
    mov eax, 0x80000003
    cpuid
    mov [cpu_type_str+16], eax
    mov [cpu_type_str+20], ebx
    mov [cpu_type_str+24], ecx
    mov [cpu_type_str+28], edx
    mov eax, 0x80000004
    cpuid
    mov [cpu_type_str+32], eax
    mov [cpu_type_str+36], ebx
    mov [cpu_type_str+40], ecx
    mov [cpu_type_str+44], edx
    mov si, cpu_type_str
    call print_start_green
    call print_newline
    ret
detect_cpu_features:
    mov si, features_label
    call print_start
    mov eax, 1
    cpuid
    mov [feature_flags_edx], edx
    test edx, 1 << 0
    jz no_fpu
    mov si, fpu_str
    call print_start_green
no_fpu:
    test edx, 1 << 23
    jz no_mmx
    mov si, mmx_str
    call print_start_green
no_mmx:
    test edx, 1 << 25
    jz no_sse
    mov si, sse_str
    call print_start_green
no_sse:
    test edx, 1 << 26
    jz no_sse2
    mov si, sse2_str
    call print_start_green
no_sse2:
    call print_newline
    ret
print_cores:
    mov si, cores
    call print_start
    mov eax, 1
    cpuid
    ror ebx, 16
    mov al, bl
    call print_al
    ret
print_al:
    mov ah, 0
    mov dl, 10
    div dl
    add ax, '00'
    mov dx, ax

    mov ah, 0eh
    mov al, dl
    cmp dl, '0'
    jz skip_fn
    mov bl, 0x0a
    int 10h
skip_fn:
    mov al, dh
    mov bl, 0x0a
    int 10h
    ret
print_sectors:
    mov si, sector_number
    call print_start
    xor ax, ax
    mov es, ax
    lea di, [0x7c00+0x13]
    mov bx, [es:di]
    mov ax, bx
    mov di, total_sectors+5
    mov cx, 0
.convert_loop:
    xor dx, dx
    mov bx, 10
    div bx
    add dl, '0'
    dec di
    mov [di], dl
    inc cx
    cmp ax, 0
    jne .convert_loop
    mov si, di
    call print_start_green
    call print_newline
    ret
quit:
    xor ah, ah
    int 0x16
    mov ax, 0x12
    int 0x10
    retf



;========================================================
;Strings And Buffers
;========================================================

title_msg: db 'Hardware Information', 0
quit_msg: db 'Press Any Key To Return To Terminal...', 0

mem_base_str: db 'Base Memory: ', 0
base_mem_kb dw 0
ext_mem_kb dw 0
k_str: db ' KB', 0
M_str: db ' MB', 0

hdd_label: db 'Number Of Harddrives: ', 0

cpu_vendor_label: db 'CPU Vendor: ', 0
cpu_desc_label: db 'CPU Description: ', 0
cpu_vendor_str      times 13 db 0
cpu_type_str        times 49 db 0
feature_flags_edx   dd 0
features_label: db 'CPU Features:  ', 0
fpu_str: db 'FPU ', 0
mmx_str: db 'MMX ', 0
sse_str: db 'SSE ', 0
sse2_str: db 'SSE2 ', 0
cores: db 'Cores: ', 0



mem_ext_label       db 'Extended memory between (1M - 16M): ', 0
mem_ext2_label      db 'Extended memory above 16M: ', 0
mem_total_label     db 'Total memory: ', 0

serial_count_label  db 'Number of serial port: ', 0
serial_addr_label   db 'Base I/O address for serial port 1: ', 0

not_supported_str   db 'Not Supported', 0x0d, 0x0a, 0

ext2_mem_16k_blocks dw 0
ext2_mem_64k_blocks dw 0
ext2_mem_mb         dw 0

sector_number: db 'Number of Sectors: ', 0
total_sectors: times 5 db '0'
