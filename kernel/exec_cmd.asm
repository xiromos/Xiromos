bits 16
[org 0x0000]

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
    mov si, program_calc_bin
    je start_program

    mov si, command_buffer
    mov di, hwinfo_str
    call compare_str
    mov si, program_hwinfo_bin
    je start_program

    mov si, command_buffer
    mov di, hello_str
    call compare_str
    mov si, program_hello_bin
    je start_program

    mov si, command_buffer
    mov di, xir_str
    call compare_str
    mov si, program_xir_bin
    je start_program

    mov si, command_buffer
    mov di, whoami_str
    call compare_str
    je whoami

    mov si, command_buffer
    mov di, info_str
    call compare_str
    je info

    mov si, command_buffer
    mov di, setuser_str
    call compare_str
    je read_username
    
    cmp byte [command_buffer], 0x00
    je return_shell

    ; if unknown command
    call unknown_cmd
    ret