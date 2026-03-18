;================================================
;Xiromos Bootloader for FAT16 file system
;by Technodon
;Copyright (C) 2026 Technodon
;================================================

[org 0x7c00]
bits 16

start:
    jmp main
    nop

;=============FAT16==============================

;can be all ignored because this bootloader use the BPB of the mkdosfs tool

    BPB_OEM db "MSWIN4.1"                   ;OEM identifier (can be ignored)
    BPB_BytesPerSec dw 512              ;sector size in bytes
    BPB_SectorsPerCluster db 8             ;amount of sectors in one cluster
    BPB_ReservedAreaCnt dw 1               ;number of sectors in reserved area(0 = bootsector)
    BPB_NumberOfFATs db 2                   ;if a sector in FAT area is damaged, data is not lost, duplicated to another FAT
    BPB_RootEntry dw 512                    ;defines number of directory entries in root directory
    BPB_TotalSectors dw 32768                  ;number of all sectors
    BPB_Media db 0xF8                         ;media descriptor byte, F8 is commonly used for partitioned disks
    BPB_FATSz16 dw 8                        ;number of sectors, occupied by a FAT
    BPB_SectorsPerTrack dw 0
    BPB_NumberOfHeads dw 0
    BPB_HiddenSectors dd 0                  ;number of sectors before a partition,(eg. if this would be on the second partition with 4096 sectors before it, number would be 4096)
    BPB_TotalSectors32 dd 0                 ;0 because i already have BPB_TotalSectors
    BS_DriveNumber db 0x80
    BS_Reserved db 0
    BS_BootSignature db 0x29
    BS_VolumeID dd 0
    BS_VolumeLabel db "Xiromos    "
    BS_FileSystemType db "FAT16   "

dap:
    db 0x10                         ;size of packet (16 bytes)
    db 0                            ;always 0
    dw 32                           ;number of sectors to read
    dw 0x0800                       ;offset
    dw 0x0000                       ;adress
    dq 0                            ;LBA

main:
    cli
    xor ax, ax
    mov ds, ax      ;start adress of the data segment
    mov es, ax      ;start point of the extra segment
    mov ss, ax
    mov sp, 0xFFFF
    sti

    mov byte [BS_DriveNumber], dl  ;get drive number (should be 0x80)

    ;calculate root sectors
    ;(BPB_RootEntry * 32) + (BytesPerSec - 1) / BytesPerSec
    mov ax, [BPB_RootEntry]
    mov bx, 32
    mul bx

    mov bx, [BPB_BytesPerSec]
    add ax, bx
    dec ax
    xor dx, dx
    div bx

    mov [RootDirSectors], ax
    mov [dap+2], ax

    ;calculate root dir start
    ;ReservedAreaCnt + (NumberOfFATs * FATSz16)

    xor ax, ax
    mov al, [BPB_NumberOfFATs]
    mov bx, [BPB_FATSz16]
    mul bx
    add ax, [BPB_ReservedAreaCnt]
    mov [RootStartSec], ax
    mov [dap+0x08], ax
    mov word [dap+10], 0
    mov word [dap+12], 0
    mov word [dap+14], 0

    ;calculate data start sector
    xor ax, ax
    mov ax, [RootStartSec]
    add ax, [RootDirSectors]
    mov [DataStartSector], ax

    ;data sectors
    ;-----------
    
    ;check if BIOS supports EDD
    ;mov ah, 0x41
    ;mov bx, 0x55aa
    ;mov dl, [BS_DriveNumber]
    ;int 0x13
    ;jc error

    ;cmp bx, 0xaa55
    ;je load_root

    ;mov si, no_supp
    ;call print_start
    ;jmp halt
    ;mov ah, 0x02            ;BIOS reads sectors 
    ;mov al, 1               ;amount of sectors, the BIOS has to read
    ;mov ch, 0               ;Cylinder
    ;mov dh, 0               ;Head
    ;mov cl, 70              ;number of the first sector
    ;mov bx, 0x500           ;Offset
    ;int 0x13
    ;jc error

load_root:
    ;BIOS extended disk read function
    ;load the root directory into memory
    mov si, dap              ;disk adress packet
    call read_sectors

    xor dx, dx
    mov dx, word [BPB_RootEntry]
    mov di, 0x0800          ;adress where to search kernel.bin, [ES:DI]
search_kernel:
    mov cx, 11               ;length of file name, needed for 'rep'
    mov si, file_kernel_bin  ;ds:si = name
    ;cmp byte [es:di], 0
    ;je error
    push di
    repe cmpsb                ;compare si with , compare it 512 times
    pop di
    je load_FAT
    add di, 32               ;add 32 because one dir entry is 32 bytes
    dec dx
    jnz search_kernel
    jmp error
    
load_FAT:
    mov di, [es:di+0x1a]             ;di = cluster no.
    mov word [cluster], di
    mov si, ok_msg
    call print_start

    mov ax, [BPB_FATSz16]
    ;mov bx, [BPB_NumberOfFATs]
    ;mul bx
    mov [dap+0x02], ax
    mov [dap+0x04], word 0x1300
    mov [dap+0x06], word 0x0000
    mov ax, [BPB_ReservedAreaCnt]
    add ax, [BPB_HiddenSectors]
    mov [dap+0x08], ax
    mov word [dap+10], 0
    mov dword [dap+12], 0
    mov si, dap
    call read_sectors
load_kernel:
    mov si, ok_msg
    call print_start
    mov [dap+0x04], word 0x0000
    mov [dap+0x06], word 0x2000
kernel_loop:
    mov si, ok_msg
    call print_start
    mov ax, word [cluster]
    call cluster_to_sec         ;get the first sector of the cluster
    mov word [dap+0x08], ax          ;ax = first sector of cluster in data area
    ;mov word [dap+10], 0
    ;mov dword [dap+12], 0
    xor bx, bx
    mov bl, [BPB_SectorsPerCluster]        
    mov [dap+0x02], bx           ;number of sectors to read
    mov word  [dap+10], 0
    mov dword [dap+12], 0
    mov si, dap
    call read_sectors           ;load the cluster into memory
    mov cl, [BPB_SectorsPerCluster]
    mov ax, 512
    mul cl
    add [dap+0x04], ax
    add word [dap+0x06], 0x1000 >> 4   ; = 0x100

    mov bx, [cluster]
    shl bx, 1                   ;cluster * 2
    mov ax, [0x1300+bx]         ;[bx+0x1300] 
    mov [cluster], ax
    cmp ax, 2
    jb error
    cmp ax, 0xFFF8              ;check if its the last cluster
    jb kernel_loop              ;if not, load the next cluster
loaded:
    mov si, ok_msg
    call print_start
    jmp 0x2000:0x0000
    hlt
halt:
    jmp halt

print_start:
    mov ah, 0x0e
print_loop:
    lodsb
    cmp al, 0
    je print_done
    int 0x10
    jmp print_loop
print_done:
    ret

error:
    mov si, error_msg
    call print_start
    xor ah, ah
    int 0x16                        ;first check for user input
    int 0x19                        ;reboot system

cluster_to_sec:
;FirstSectorOfCluster = (cluster - 2) * BPB_SectorsPerCluster + DataStartSector
    sub ax, 2
    xor cx, cx 
    mov cl, [BPB_SectorsPerCluster]
    mul cx
    add ax, word [DataStartSector]
    ret
read_sectors:
    mov ah, 0x42
    mov dl, [BS_DriveNumber]
    int 0x13
    jc error
    ret

;=========================================
;variables and buffer
;=========================================
ok_msg: db '[ OK ]', 0x0d, 0x0a, 0
;no_supp: db '[ No EDD ]', 0x0d, 0x0a, 0
error_msg: db '[ Error... ]', 0x0d, 0x0a, 0
cluster: dw 0

;FAT start sector = ReservedAreaCnt
RootStartSec dw 0
RootDirSectors dw 0
DataStartSector dw 0

file_kernel_bin db "KERNEL  BIN"
;--Description--
;Bootloader first initialize the stack, then clears the screen and prints a message
;After, the Bootloader calculates the RootStartSec, RootDirSectors, DataStartSector and DataSectors
;Then it checks if BIOS supports EDD, if yes it loads the root directory into memory (unfortunatly the bootloader doesnt support CHS - will be maybe added)
;In the root directory it searches for the kernel.bin file, if found, the bootloader saves it cluster number
;finally the bootloader loads the FAT sectors into memory and jumps to the kernel
;----
times 510 - ($ - $$) db 0
dw 0xAA55
;================================================



