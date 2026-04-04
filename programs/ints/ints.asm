load_interrupts:
    mov word [0x20*4+2], kernel_seg         ;write segment
    mov word [0x20*4], search_program       ;write offset

    mov word [0x22*4+2], kernel_seg
    mov word [0x22*4], int0x22

    mov word [0x23*4+2], kernel_seg
    mov word [0x23*4], int0x23

    mov word [0x24*4+2], kernel_seg
    mov word [0x24*4], int0x24
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
    iret
int0x23:
    cmp ah, 0x01
    je openfile
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
    iret

%include "programs/ints/0x20.asm"
%include "programs/ints/0x22.asm"
%include "programs/ints/0x23.asm"
%include "programs/ints/0x24.asm"