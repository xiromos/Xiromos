load_interrupts:
    mov word [0x20*4+2], 0x1000         ;write segment
    mov word [0x20*4], search_program   ;write offset
    ret

%include "programs/ints/0x20.asm"
    