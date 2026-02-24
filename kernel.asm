;================================================
;Xiromos Kernel Color-Version
;by Technodon
;credits: This project wouldnt be possible without this tutorial:
;https://osdev.netlify.app/x16/mini_kernel.html
;================================================


bits 16
[org 0x500]


start:

    mov ax, 0x03
    int 0x10

    call set_video_mode
    
    call print_logo

    ;print welcome_msg
    mov si, welcome_msg
    call print_string_green

    call shell

hang:
    jmp hang

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
    ; VGA 640*480, 16 colors
    mov ax, 0x12
    int 0x10
    ret


;===========================COLORED STRINGS===========================

;--cyan--
print_string_cyan:
    mov ah, 0x0E
    mov bl, 0x0B
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

;--red--
print_string_red:
    mov ah, 0x0E
    mov bl, 0x0C
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

;--green--
print_string_green:
    mov ah, 0x0E
    mov bl, 0x0A
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

;--yellow--
print_string_yellow:
    mov ah, 0x0E
    mov bl, 0x0E
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

;--darkblue--
print_string_darkblue:
    mov ah, 0x0E
    mov bl, 0x01
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

;--white--
print_string_white:
    mov ah, 0x0E
    mov bl, 0x0f
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret
;--dark-red--
print_string_darkred:
    mov ah, 0x0E
    mov bl, 0x04
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

;===============================================================

print_logo:
    mov si, header1
    call print_string_cyan
    call print_newline

    mov si, os_name
    call print_string_cyan
    call print_newline

    mov si, header1
    call print_string_cyan
    call print_newline

    ret
shell:
    mov si, prompt
    call print_string_white

; ask user for input
    call read_command
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
    mov di, command_buffer  ;SI - Quelle, DI - Ziel
    xor cx, cx              ;?
read_loop:
    mov ah, 0x00
    int 0x16            ;call BIOS write function
    cmp al, 0x0d        ;check if ENTER was pressed
    je read_end
    cmp al, 0x08        ;0x08 checks if backspace was pressed
    je handle_backspace
    cmp cx, 255         ;zählt wie viel zeichen geschrieben wurden
    jge read_end
    stosb
    mov ah, 0x0e
    mov bl, 0x1f
    int 0x10
    inc cx              ;pro zeichen wird cx um 1 erhöht
    jmp read_loop

handle_backspace:
    cmp di, command_buffer
    je read_loop
    dec di
    dec cx          ;1 zeichen wird entfernt
    mov ah, 0x0e
    mov al, 0x08    ;0x08 = BACKSPACE
    int 0x10
    mov al, ' '     ;Zeichen ist da, aber es wird optisch mit ' ' erstetzt
    int 0x10        ;leerzeichen überschreibt altes zeichen
    mov al, 0x08    ;cursor geht noch einmal zurück
    int 0x10
    jmp read_loop

read_end:
    mov byte [di], 0
    ret

exec_cmd:
    ; compare input with valid commands
    mov si, command_buffer
    mov di, help_str
    call compare_str
    je help

    mov si, command_buffer
    mov di, clear_str
    call compare_str
    je clear

    mov si, command_buffer
    mov di, ver_str
    call compare_str
    je show_ver

    mov si, command_buffer
    mov di, cyan
    call compare_str
    je color_cyan

    mov si, command_buffer
    mov di, green
    call compare_str
    je color_green

    mov si, command_buffer
    mov di, load_str
    call compare_str
    je load_program

    mov si, command_buffer
    mov di, ram_str
    call compare_str
    je display_ram

    mov si, command_buffer
    mov di, reboot_str
    call compare_str
    je reboot

    mov si, command_buffer
    mov di, calc_str
    call compare_str
    je start_calc

    mov si, command_buffer
    mov di, hwinfo_str
    call compare_str
    je start_hwinfo



    ; if unknown command
    call unknown_cmd
    ret
compare_str:
    xor cx, cx
next_char:
    lodsb
    cmp al, [di]
    jne not_equal
    cmp al, 0
    je equal
    inc di
    jmp next_char
not_equal:
    ret
equal:
    ret
help:
    mov si, help_msg
    call print_start
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
color_cyan:
    mov ax, 0x03
    int 0x10

    mov ah, 09h
    mov cx, 1000h
    mov bh, 0
    mov al, 20h

    mov bl, 30h ; 30h = cyan, 20h = green
    int 10h
    mov si, return_msg
    call print_start
    call print_newline
    ret
color_green:
    mov ax, 0x03
    int 0x10

    mov ah, 09h
    mov cx, 1000h
    mov bh, 0
    mov al, 20h

    mov bl, 20h ; 30h = cyan, 20h = green
    int 10h
    mov si, return_msg
    call print_start
    call print_newline
    ret
unknown_cmd:
    mov si, unknown_msg
    call print_start
    ret
load_program:
    mov si, load_prompt
    call print_start
    call read_number

    mov si, mt

    call start_program
    ret
read_number:
    mov di, number_buffer
    xor cx, cx
read_loop_load:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0d
    je done_read
    cmp al, 0x08
    je r_l_handle_backspace
    cmp cx, 5
    jge read_loop_load
    cmp al, '0'
    jb read_loop_load    ;?
    cmp al, '9'
    ja read_loop_load
    stosb
    mov ah, 0x0e
    mov bl, 0x0a
    cmp al, 'q'
    je quit_load
;    cmp al, '7'
;    je print_green
;    cmp al, '9'
;    je print_green
;    mov bl, 0x0c
;    jmp go
;print_green:
;    mov bl, 0x0a
;go:
    int 0x10
    inc cx
    jmp read_loop_load
r_l_handle_backspace:
    cmp cx, 0
    je read_loop_load
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08    ;Backspace
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_loop_load
done_read:
    call print_newline
    cmp [number_buffer], '1'
    je read_loop_load

    cmp [number_buffer], '2'
    je read_loop_load

    mov byte [di], 0    ; Завершаем строку нулевым символом
    call convert_to_num
    ret
convert_to_num:
    mov si, number_buffer
    xor ax, ax
    xor cx, cx
convert_loop:
    lodsb
    cmp al, 0
    je done_convert
    sub al, '0'         ;add
    imul cx, 10
    add cx, ax
    jmp convert_loop
done_convert:
    mov [sector_number], cx     ;save number
    ret
start_program:
    pusha
    mov ah, 0x02        ;function to read sector
    mov al, 2           ; how much sectors to load? 
    mov ch, 0            ;cylinder
    mov dh, 0
    mov cl, [sector_number] ;number of sector
    mov bx, 1000h         ;adress where to load
    int 0x13
    jc disk_error
    popa 
    jmp 1000h
    ret
disk_error:
    mov si, disk_error_msg
    call print_string_red
    call print_newline
    clc
    popa
    ret
quit_load:
    ret
display_ram:
    mov si, mem_base_str
    call print_string_white
    int 12h         ;interrupt to detect memory
    mov [base_mem_kb], ax
    call print_decimal
    call print_k_suffix
    ret

print_decimal:
    pusha
    mov cx, 0
    mov ebx, 10
.div_loop:
    mov edx, 0
    div ebx
    push edx
    inc cx
    cmp eax, 0
    jne .div_loop
.print_loop:
    pop eax
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
    mov ax, 0x03
    int 0x10
    ;jmp 0x7c00
    int 0x19
start_calc:
    pusha
    mov ah, 0x02        ;function to read sector
    mov al, 2           ; how much sectors to load? 
    mov ch, 0            ;cylinder
    mov dh, 0
    mov cl, 7            ;number of sector
    mov bx, 1000h         ;adress where to load
    int 0x13
    jc disk_error
    popa 
    jmp 1000h
    ret
start_hwinfo:
    pusha
    mov ah, 0x02        ;function to read sector
    mov al, 2           ; how much sectors to load? 
    mov ch, 0            ;cylinder
    mov dh, 0
    mov cl, 10            ;number of sector
    mov bx, 1000h         ;adress where to load
    int 0x13
    jc disk_error
    popa 
    jmp 1000h
    ret  

;================================
; Strings and Buffers
;================================

welcome_msg: db 'Kernel Loaded Successfully. Type "help" For Help.', 0x0d, 0x0a, 0
;header db 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xDB, 0xDB, ' ', 'x16 PRos v0.6', ' ', 0xDB, 0xDB, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0
os_name: db '| Xiromos Bootloader and Kernel Color-Version |', 0
header1: db ' --------------------------------------------- ', 0

str1: db '---       ---', 0
str2: db '\  \    /   /', 0
str3: db ' \  \  /   / ', 0
str4: db '  \  \/   /  ', 0 
str5: db '  /  /\   \  ', 0
str6: db ' /  /  \   \ ', 0
str7: db '/  /    \   \', 0
str8: db '---      ----', 0 

;commands
help_str: db 'help', 0
clear_str: db 'clear', 0

help_msg: db 'Commands: ', '                              Programs: ', 0x0D, 0x0A, 'HELP [shows all commands]', '               CALC [calculator]', 0x0D, 0x0A, 'CLEAR [cleas the screen]', '                HWINFO [hardware-information]', 0x0D, 0x0A, 'GREEN/CYAN [change color]', 0x0D, 0x0A, 'VER [shows current version]', 0x0D, 0x0A, 'LOAD [start program]', 0x0D, 0x0A, 0
unknown_msg: db 'Invalid command', 0x0D, 0x0A, 0

ver_msg: db 'Xiromos Bootloader and Kernel Color-Version', 0
ver_str: db 'ver', 0

cyan: db 'cyan', 0
return_msg: db 'To Return Standard Color-Theme Type "clear"', 0

green: db 'green', 0
prompt: db '> ', 0

load_prompt: db 'Enter sector number: ', 0
load_str: db 'load', 0

mt db 13, 10,  0

disk_error_msg: db 'Disk Read Error Occured...', 0

reboot_str: db 'reboot', 0
calc_str: db 'calc', 0

k_str: db ' KB', 0
ram_str: db 'ram', 0
base_mem_kb dw 0
mem_base_str: db 'Base Memory: ', 0
hwinfo_str: db 'hwinfo', 0
command_buffer db 25 dup(0)
number_buffer db 7 dup(0)
sector_number dw 0
hwinfo_buf dw 0