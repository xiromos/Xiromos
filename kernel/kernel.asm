;================================================
;Xiromos Kernel Filesystem-Version
;by Technodon
;Copyright (C) 2026 Technodon
;================================================
bits 16
[org 0x0000]

start:
    ;read boot info from 0x7e00 (segment 0)
    ;mov al, [0x7e00]
    ;mov [drive_number], 0x80
    ;mov al, [0x7e00+1]
    ;mov [sec_per_cluster], 4
    ;mov ax, [0x7e00+2]
    ;mov [root_entries], word 512
    ;mov ax, [0x7e00+4]
    ;mov [data_start_sec], word 65
    ;mov ax, [0x7e00+22]
    ;mov [fat_size], ax

    call load_interrupts
    
    cli
    mov ax, kernel_seg
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE
    sti

    ;clear screen
    mov ax, 0x03
    int 0x10

    call set_video_mode
    call print_logo
    call get_bpb_data
    call init_drives

    ;enable A20 gate
    mov si, a20_gate
    call print_string_white
    mov ax, 0x2401
    int 0x15
    jc a20_error
    mov [a20_seg], word 0xFFFF
    mov si, a20_enabled
    call print_string_green
    call print_newline
    call print_newline

    call print_blocks

    jmp shell
    jmp start
hang:
    jmp hang

a20_error:
    mov [a20_seg], word 0x9000
    mov si, a20_disabled
    call print_string_red
    call print_newline
    call print_newline

    call print_blocks
    jmp shell
print_start:
    mov ah, 0x0e
print_loop:
    lodsb           ;loads next byte
    or al, al
    jz done_print
    int 0x10
    jmp print_loop
done_print:
    ret

set_video_mode:
    mov ax, 0x12
    int 0x10
    ret

;===========================COLORED STRINGS===========================

;--cyan--
print_string_cyan:
    mov ah, 0x0e
    mov bl, 0x0b
    jmp print_char
;--red--
print_string_red:
    mov ah, 0x0e
    mov bl, 0x0c
    jmp print_char
;--green--
print_string_green:
    mov ah, 0x0e
    mov bl, 0x0a
    jmp print_char
;--white--
print_string_white:
    mov ah, 0x0e
    mov bl, 0x0f
    jmp print_char
;--dark-red--
print_string_darkred:
    mov ah, 0x0e
    mov bl, 0x04
print_char:
    lodsb
    cmp al, 0
    je print_char_done
    int 0x10
    jmp print_char
print_char_done:
    ret
print_hex:
    mov cx, 2       ;counter to print 4 chars !!!!change it to print less or more chars!!!!
char_loop:
    dec cx

    mov ax, dx      ;copy dx
    shr dx, 4       ;shift 4 bits to the right
    and ax, 0xf     ;mask ah to get the last 4 bits

    mov si, hex_out ;memory adress of the string
    add si, 2       ;skip the 0x
    add si, cx      ;add counter to adress

    cmp ax, 0xa     ;checkk if its a letter or a number
    jl set_letter   ;if its a number, go to set the value
    add al, 0x27    ;ASCII letters start at 0x61 for 'a'
    jl set_letter
set_letter:
    add al, 0x30    ;ASCII number
    mov byte [si], al   ;add the value of the char at bx
    cmp cx, 0       ;check the counter
    je print_hex_done
    jmp char_loop
print_hex_done:
    mov bx, hex_out
    call print_hex_string
    ret
print_hex_string:
    mov al, [si]
    cmp al, 0
    je hex_string_done
    mov ah, 0x0e
    mov bl, 0x0b
    int 0x10
    add si, 1       ;shift bx to the next character
    jmp print_hex_string
hex_string_done:
    ret
;===============================================================

print_logo:
    mov si, logo
    call print_string_white
    call print_newline

    mov si, header1
    call print_string_white
    call print_newline

    mov si, os_name
    call print_string_cyan
    call print_newline

    mov si, header1
    call print_string_white
    call print_newline

    mov si, github_link
    call print_string_cyan
    call print_newline

    mov si, copyright_str
    call print_string_cyan
    call print_newline

    mov si, welcome_msg
    call print_string_white
    call print_newline

    mov si, drive_num_str
    call print_string_white
    mov si, prefix_0x
    call print_string_cyan

    mov dx, [drive_number]
    call print_hex
    call print_newline
    mov si, kernel_seg_str
    call print_string_white
    mov si, prefix_0x
    call print_string_cyan
    mov dx, 0x10
    call print_hex
    mov si, zero_zero
    call print_string_cyan
    call print_newline
    ret
print_blocks:
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0a
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0c
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x04
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0b
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x05
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x0f
    int 0x10
    mov ah, 0x0e
    mov al, 0xdb
    mov bl, 0x03
    int 0x10
    call print_newline
    call print_newline
    ret
shell:
    ;mov si, prompt_front
    ;call print_string_white

    ;mov si, username
    ;call print_string_cyan

    ;mov si, prompt_back
    ;call print_string_white

    mov si, prompt
    call print_string_white

; ask user for input
    call read_command
    call check_args
    call print_newline

; execute the command
    call exec_cmd
    jmp shell

print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret

read_command:
    mov di, command_buffer  ;SI - source, DI - Ziel
    xor cx, cx              ;?
read_loop:
    xor ah, ah
    int 0x16            ;call BIOS write function
    cmp al, 0x0d        ;check if ENTER was pressed
    je read_end
    cmp al, 0x08        ;0x08 checks if backspace was pressed
    je handle_backspace
    cmp ah, 0x53        ;scancode for DEL
    je reboot
    cmp cx, 255         ;checks, how much charachters were written
    jge read_end
    stosb
    mov ah, 0x0e
    mov bl, 0x02
    int 0x10
    inc cx              ;per charachter + 1
    jmp read_loop

handle_backspace:
    cmp di, command_buffer
    je read_loop
    dec di
    dec cx          ;remove charachter
    mov ah, 0x0e
    mov al, 0x08    ;0x08 = BACKSPACE
    int 0x10
    mov al, ' '     ;charachter is replaced with ' '
    int 0x10        
    mov al, 0x08    ;cursor wents one slot back
    int 0x10
    jmp read_loop

read_end:
    mov byte [di], 0
    ret

return_shell:
    ret
compare_str:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne not_equal
    cmp al, 0
    je equal
    inc di
    inc si
    jmp compare_str
not_equal:
    clc
    ret
equal:
    stc
    ret

check_args:
    mov si, command_buffer
    mov cx, 100
search_space:
    mov al, [si]
    cmp al, 0
    je return_shell
    cmp al, ' '
    je save_arg
    inc si
    dec cx
    jnz search_space
    ret
save_arg:
    mov byte [si], 0
    inc si
    mov [argument], si  ;pointer to argument
    ret

help:
    mov si, help_msg
    call print_string_white
    ret
clear:
    call clear_screen
    call set_video_mode
    ret
clear_screen:
    mov ax, 0x03
    int 0x10
    ret
show_ver:
    mov si, ver_msg
    call print_string_cyan
    call print_newline
    ret
unknown_cmd:
    mov si, unknown_msg
    call print_string_red
    call print_newline
    ret

print_decimal:
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
    ret
print_k_suffix:
    pusha
    mov si, k_str
    call print_string_white
    call print_newline
    popa
    ret
reboot:
    int 0x19
rsod:
    int 0x19
init_drives:
    xor cx, cx
    mov ah, 0x42
    mov si, program_dap
    mov dl, 0x81
init_drives_loop:
    int 0x13
    jc init_floppies
    inc cx
    inc dl
    cmp dl, 0x84
    jb init_drives_loop
init_floppies:
    mov [drives], cx
    xor cx, cx
    mov es, cx
    mov ah, 0x02
    mov dl, 0x00
    mov al, 1       ;1 sector
    mov ch, 0       ;cylinder 0
    mov cl, 1       ;sector 1
    mov dh, 0       ;head 0
    mov bx, 0x7000
    xor si, si
init_floppies_loop:
    int 0x13
    jc init_drives_done
    inc dl
    inc si
    cmp dl, 0x03
    jb init_floppies_loop
init_drives_done:
    mov [floppies], si
    mov ax, kernel_seg
    mov es, ax
    ret
list_drives:
    mov si, external_drives_str
    call print_string_white
    mov cx, [drives]
    mov ax, cx
    call print_decimal
    call print_newline
    mov si, external_floppies_str
    call print_string_white
    mov cx, [floppies]
    mov ax, cx
    call print_decimal
    call print_newline
    ret
;====================username====================
read_username:
    mov byte [first_boot_value], 0
    call print_newline
    mov byte [username_set], 1
    mov si, username_msg
    call print_string_white
    mov si, prompt
    call print_string_white
    mov di, username  ;SI - source, DI - Ziel
    xor cx, cx              
read_username_loop:
    xor ah, ah
    int 0x16            ;call BIOS write function
    cmp al, 0x0d        ;check if ENTER was pressed
    je username_newline
    cmp al, 0x08        ;0x08 checks if backspace was pressed
    je handle_backspace2
    cmp cx, 30         ;checks, how much charachters were written
    jge read_end
    stosb
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x10
    inc cx              ;per charachter + 1
    jmp read_username_loop

handle_backspace2:
    cmp di, username
    je read_username_loop
    dec di
    dec cx          ;remove charachter
    mov ah, 0x0e
    mov al, 0x08    ;0x08 = BACKSPACE
    int 0x10
    mov al, ' '     ;charachter is replaced with ' '
    int 0x10        
    mov al, 0x08    ;cursor wents one slot back
    int 0x10
    jmp read_username_loop
username_newline:
    mov si, username_success
    call print_string_green
    jmp shell
whoami:
    mov si, whoami_msg
    call print_string_white
    cmp [username_set], 1
    jne no_user_set
    cmp byte [username], 0x00
    je no_user_set
    mov si, username
    call print_string_cyan
    call print_newline
    ret

no_user_set:
    mov si, no_user
    call print_string_red
    call print_newline
    ret

info:
    mov si, info__logo
    call print_string_white
    call print_newline
    ret
display_ram:
    mov si, mem_base_str
    call print_string_white
    int 0x12         ;interrupt to detect memory
    mov [base_mem_kb], ax
    call print_decimal
    call print_k_suffix
    ret

;includes
%include "kernel/data.asm"
%include "kernel/fs16.asm"
%include "kernel/exec_cmd.asm"
%include "programs/ints/ints.asm"