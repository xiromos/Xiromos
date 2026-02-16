[org 0x7c00]
bits 16

main:
    cli
    mov ax, 0
    mov ds, ax      ;start adress of the data segment
    mov es, ax      ;start point of the extra segment
    mov ss, ax
    mov sp, 0x7c00
    mov si, os_boot_msg
    sti
    call print   
    hlt

halt:
    jmp halt

print:
    push si
    push ax
    push bx

print_loop:
    lodsb
    or al, al
    jz done_print
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    jmp print_loop
    
done_print:
    pop bx
    pop si
    pop ax
    ret

os_boot_msg: db 'Press Any Key To Boot...', 0x0d, 0x0a
times 510 - ($ - $$) db 0
dw 0xAA55