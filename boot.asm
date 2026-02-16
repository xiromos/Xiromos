[org 0x7c00]
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax      ;start adress of the data segment
    mov es, ax      ;start point of the extra segment
    mov ss, ax
    mov sp, 0x7c00
    sti
    mov si, os_boot_msg
    call print_loop
    call key_input
    mov si, booting_msg
    call print_loop

    hlt


halt:
    jmp halt

key_input:
    xor ah, ah
    int 0x16        ;keyboard interrupt
    ;AL = key is pressed
    mov ah, 0x0e
    int 0x10
    ret  


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

os_boot_msg: db 'Press Any Key To Boot...', 0
booting_msg: db 'Key Pressed. Booting...', 0
times 510 - ($ - $$) db 0
dw 0xAA55