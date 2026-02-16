[org 0x0000]
bits 16

start:
    ;BIOS needs to print somethin the (AH)function-number(0x0e) and the (AL)ASCII charachter,
    ;optional (BH) number of sites, (BL) color
    ;mov ah, 0x09    ;0x0e -> Teletype Output // 0x09 graphical mode
    ;mov al, 'X'     ;AX = 16bit, ah and al are required for bios interrupt 0x10
    ;mov bh, 0       ;page number
    ;mov bl, 0x1e    ;color
    ;mov cx, 1       ;amount
    ;int 0x10
    mov ah, 0x0e
    mov al, 'x'
    int 0x10

hang:
    jmp hang