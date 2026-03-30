bits 16
[org 0x0000]

exec_cmd:
    ; compare input with valid commands
    mov si, command_buffer
    mov di, help_str
    call compare_str
    jc help

    mov si, command_buffer
    mov di, clear_str
    call compare_str
    jc clear

    mov si, command_buffer
    mov di, ver_str
    call compare_str
    jc show_ver

    mov si, command_buffer
    mov di, ram_str
    call compare_str
    jc display_ram

    mov si, command_buffer
    mov di, reboot_str
    call compare_str
    jc reboot

    mov si, command_buffer
    mov di, calc_str
    call compare_str
    mov si, program_calc_bin
    jc start_program

    mov si, command_buffer
    mov di, hwinfo_str
    call compare_str
    mov si, program_hwinfo_bin
    jc start_program

    mov si, command_buffer
    mov di, hello_str
    call compare_str
    mov si, program_hello_bin
    jc start_program

    mov si, command_buffer
    mov di, xir_str
    call compare_str
    mov si, program_xir_bin
    jc start_program

    mov si, command_buffer
    mov di, ascii_str
    call compare_str
    mov si, program_ascii_bin
    jc start_program

    mov si, command_buffer
    mov di, read_str
    call compare_str
    jc read_file

    mov si, command_buffer
    mov di, write_str
    call compare_str
    jc write_file

    mov si, command_buffer
    mov di, ls_str
    call compare_str
    jc ls_dir

    mov si, command_buffer
    mov di, rename_str
    call compare_str
    jc rename_file

    mov si, command_buffer
    mov di, del_str
    call compare_str
    jc delete_file

    mov si, command_buffer
    mov di, lsdisk_str
    call compare_str
    jc list_drives

    mov si, command_buffer
    mov di, cd_str
    call compare_str
    jc cd_drives

    mov si, command_buffer
    mov di, pwd_str
    call compare_str
    jc print_working_dir
    
    mov si, command_buffer
    mov di, whoami_str
    call compare_str
    jc whoami

    mov si, command_buffer
    mov di, info_str
    call compare_str
    jc info

    mov si, command_buffer
    mov di, setuser_str
    call compare_str
    jc read_username
    
    cmp byte [command_buffer], 0x00
    je return_shell

    ; if unknown command
    call unknown_cmd
    ret