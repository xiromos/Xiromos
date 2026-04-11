;expects the number in AX
print_dec:
    pusha
    mov cx, 0
    mov bx, 10
.div_loop:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .div_loop
.print_loop:
    pop ax
    add al, '0'
    mov ah, 0x0e
    int 0x10
    loop .print_loop
    popa
    iret

print:
    push ax
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    pop ax
    iret

print_hexa:
    mov cx, 2       ;counter to print 4 chars !!!!change it to print less or more chars!!!!
.char_loop:
    dec cx

    mov ax, dx      ;copy dx
    shr dx, 4       ;shift 4 bits to the right
    and ax, 0xf     ;mask ah to get the last 4 bits

    mov si, hex_out ;memory adress of the string
    add si, 2       ;skip the 0x
    add si, cx      ;add counter to adress

    cmp ax, 0xa     ;checkk if its a letter or a number
    jl .set_letter   ;if its a number, go to set the value
    add al, 0x27    ;ASCII letters start at 0x61 for 'a'
    jl .set_letter
.set_letter:
    add al, 0x30    ;ASCII number
    mov byte [si], al   ;add the value of the char at bx
    cmp cx, 0       ;check the counter
    je .print_hex_done
    jmp .char_loop
.print_hex_done:
    mov bx, hex_out
    call print_hex_string
    iret