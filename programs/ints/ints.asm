load_interrupts:
    mov word [0x20*4+2], kernel_seg         ;write segment
    mov word [0x20*4], search_program       ;write offset

    mov word [0x22*4+2], kernel_seg
    mov word [0x22*4], int0x22
    ret

int0x22:
    cmp ah, 0x01            ;read file
    je search_file
    cmp ah, 0x02            ;write file
    je search_entry
    cmp ah, 0x03            ;list content of root directory
    je get_file_list
    cmp ah, 0x04
    je rename_file_name
    cmp ah, 0x05
    je search_filename
    iret

%include "programs/ints/0x20.asm"
%include "programs/ints/0x22.asm"
    