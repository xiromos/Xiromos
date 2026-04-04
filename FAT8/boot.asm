;===============================================
;FAT8 Bootloader
;Copyright (C) 2026 Technodon
;===============================================
[org 0x7c00]
bits 16

start:
    jmp main
    nop

    BS_OEMName          db "XIROMOS8"
    BPB_BytesPerSec     dw 512
    BPB_SecPerClus      db 1
    BPB_RsvdSecCnt      dw 1                ;boot sector
    BPB_NumFATs         db 1
    BPB_RootEntries     dw 32               ;2 sectors
    BPB_TotalSec16      dw 256              ;2^8
    BPB_Media           db 0xf0
    BPB_FATSz16         dw 1
    BPB_SecPerTrk       dw 16               ;CHS = 16, 1, 16
    BPB_NumHeads        dw 1
    BPB_HiddSec         dd 0
    BPB_TotalSec32      dd 0

    BS_DriveNumber      db 0x00
    BS_Reserved         db 0
    BS_BootSig          db 0x29
    BS_VolID            dd 0
    BS_VolLab           db "XIROMOSFAT8"
    BS_FilSysType       db "FAT8    "

    dap:
        db 0x10
        db 0
        dw 2
        dw 0x500
        dw 0x0000
        dq 0
    
    RootStartSec dw 0
    RootDirSectors dw 0
    DataStartSector dw 0

main:
    cli
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov byte [BS_DriveNumber], dl

    ;calculate root sectors
    mov ax, [BPB_RootEntries]
    mov bx, 32
    mul bx

    mov bx, [BPB_BytesPerSec]
    add ax, bx
    dec ax
    xor dx, dx
    div bx

    mov [RootDirSectors], ax
    mov [dap+2], ax

    ;calculate root start

    xor ax, ax
    mov al, [BPB_NumFATs]
    mov bx, [BPB_FATSz16]
    mul bx
    add ax, [BPB_RsvdSecCnt]
    mov [RootStartSec], ax
    mov [dap+0x08], ax

    ;calculate data start sector
    xor ax, ax
    mov ax, [RootStartSec]
    add ax, [RootDirSectors]
    mov [DataStartSector], ax

load_root:
    mov si, dap
    call read_sectors

    mov dx, [BPB_RootEntries]
    mov di, 0x500
search_kernel:
    mov si, file_kernel_bin
    push di
    repe cmpsb
    pop di
    je found_kernel

    add di, 32
    dec dx
    jnz search_kernel

    call error

found_kernel:
    hlt

read_sectors:
    mov ah, 0x42
    mov dl, [BS_DriveNumber]
    int 0x13
    jc error
    ret

error:
    mov si, error_msg
    call print_start
    xor ah, ah
    int 0x16
    int 0x19

print_start:
    mov ah, 0x0e
print_loop:
    lodsb
    cmp al, 0
    je done
    int 0x10
    jmp print_loop
done:
    ret

error_msg: db 'Error', 0
file_kernel_bin db "KERNEL  BIN"
times 510 - ($ - $$) db 0
dw 0xAA55