load_interrupts:
    cli
    mov word [0x20*4+2], kernel_seg         ;write segment
    mov word [0x20*4], search_program       ;write offset

    mov word [0x22*4+2], kernel_seg
    mov word [0x22*4], int0x22

    mov word [0x23*4+2], kernel_seg
    mov word [0x23*4], int0x23

    mov word [0x24*4+2], kernel_seg
    mov word [0x24*4], int0x24

    mov word [0x27*4+2], kernel_seg
    mov word [0x27*4], int0x27

    mov word [0x30*4+2], kernel_seg
    mov word [0x30*4], int0x30

    ; xor ax, ax
    ; mov es, ax

    ; mov ax, word [es:0x9*4]
    ; mov [int9_addr], ax
    ; mov ax, word [es:0x9*4+2]
    ; mov [int9_addr+2], ax

    ; mov word [es:0x9*4+2], kernel_seg
    ; mov word [es:0x9*4], int0x9
    ; mov ax, kernel_seg
    ; mov es, ax
    sti
    ret

int0x22:
    cmp ah, 0x01            ;read file
    je search_file
    cmp ah, 0x02            ;write file
    je search_entry
    cmp ah, 0x03            ;list content of root directory
    je get_file_list
    cmp ah, 0x04            ;rename a file
    je rename_file_name
    cmp ah, 0x05            ;delete a file
    je search_filename
    cmp ah, 0x06
    je change_drive
    cmp ah, 0x08
    je parse_arg_loop
    cmp ah, 0x0a
    je change_directory
    iret
int0x23:
    cmp ah, 0x01
    je openfile
    cmp ah, 0x02
    je api_write_file
    iret
int0x24:
    cmp ah, 0x01
    je check_floppy
    cmp ah, 0x02
    je read_flp_file
    cmp ah, 0x03
    je search_file_flp
    cmp ah, 0x04
    je del_file_flp
    cmp ah, 0x05
    je ren_file_flp
    cmp ah, 0x08
    je flp_search_program
    cmp ah, 0x09
    je flp_change_dir
    cmp ah, 0x0a
    je flp_mkdir
    cmp ah, 0x0b
    je flp_deldir
    iret
int0x27:
    cmp bh, 0x01
    je print_dec
    cmp bh, 0x02
    je print
    cmp bh, 0x03
    je print_hexa
    iret

int0x30:
    cmp ah, 0x01
    je fat8_read_file
    cmp ah, 0x02
    je fat8_write_file
    cmp ah, 0x03
    je fat8_delete_file
    iret

int0x9:
    push ax
    in al, 0x60
    cmp al, 0x53    ;DEL
    jne .bios_int0x9

    pop ax
    mov al, 0x20
    out 0x20, al
    pop bx
    pop cx
    pop dx
    pop ax
    jmp reboot
.bios_int0x9:
    pop ax
    push ax
    xor ax, ax
    mov ds, ax
    pop ax
    pushf
    call far [int9_addr]
    push ax
    mov ax, kernel_seg
    mov ds, ax
    pop ax
    iret

%include "programs/ints/0x20.asm"
%include "programs/ints/0x22.asm"
%include "programs/ints/0x23.asm"
%include "programs/ints/0x24.asm"
%include "programs/ints/0x27.asm"
%include "programs/ints/0x30.asm"