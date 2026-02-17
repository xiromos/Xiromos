[org 0x7c00]
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax      ;start adress of the data segment
    mov es, ax      ;start point of the extra segment
    mov ss, ax
    mov sp, 0x7c00
    ;mov [boot_drive], dl
    sti
    mov si, os_boot_msg
    call print_start
    call key_input
    mov si, booting_msg
    call print_start
    call load_kernel

    jmp 0x500


halt:
    jmp halt

load_kernel:
    mov ah, 0x02            ; BIOS reads sectors 
    mov al, 8               ; amount of sectors, the BIOS has to read
    mov ch, 0               ; Cylinder
    mov dh, 0               ; Head
    mov cl, 2               ; number of the first sector
    mov bx, 0x500           ; Offset
    ;mov ax, 0x1000
    ;mov es, ax              ; Zielsegment 0x1000
    int 0x13
    jc disk_error
    ret

disk_error:
    mov si, disk_error_msg
    mov di, 0xB800
    call print_loop
    jmp $

key_input:
    xor ah, ah
    int 0x16        ;keyboard interrupt
    ;AL = key is pressed
    mov ah, 0x0e
    int 0x10
    ret  

print_start:
    mov ah, 0x0e
print_loop:
    lodsb           ;loads the next byte of os_boot_msg
    or al, al
    jz done_print
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    jmp print_loop

    
done_print:
    ret       

boot_drive db 0
os_boot_msg: db 'Press Any Key To Boot...', 0x0d, 0x0a, 0
booting_msg: db 0x0d, 0x0a, 'Key Pressed. Booting...', 0
disk_error_msg: db 'Disk Error Occured', 0
times 510 - ($ - $$) db 0
dw 0xAA55            ;v1.0
