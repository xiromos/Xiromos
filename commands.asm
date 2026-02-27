bits 16
[org 0x1000]

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

display_ram:
    mov si, mem_base_str
    call print_string_white
    int 12h         ;interrupt to detect memory
    mov [base_mem_kb], ax
    call print_decimal
    call print_k_suffix
    ret

no_user: db 'No User Set', 0