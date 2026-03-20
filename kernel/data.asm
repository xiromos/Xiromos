bits 16
[org 0x0000]

;================================
; Strings and Buffers
;================================
;start
welcome_msg: db 'Type "help" For Help.', 0x0d, 0x0a, 0
github_link: db 'GITHUB: https://github.com/xiromos/Xiromos', 0
copyright_str: db 'Copyright (C) 2026 Technodon', 0
;header db 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xDB, 0xDB, ' ', 'x16 PRos v0.6', ' ', 0xDB, 0xDB, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0
os_name: db '| Xiromos Bootloader and Kernel Filesystem-Version |', 0
header1: db ' -------------------------------------------------- ', 0

logo: db '___      ___  __   __    ', 13, 10
      db '\  \    /  / |__| |   \_ ', 13, 10
      db ' \  \  /  /   __  |   __|', 13, 10
      db '  \  \/  /   |  | |  |   ', 13, 10 
      db '  /  /\  \   |  | |  |   ', 13, 10
      db ' /  /  \  \  |  | |  |   ', 13, 10
      db '/_ /    \ _\ |__| |__|   ', 13, 10, 0

prompt_front: db '[', 0
prompt_back: db ']', 0
prompt: db '> ', 0
mt db 13, 10,  0
drive_num_str: db 'Drive Number: ', 0
prefix_0x: db '0x', 0

command_buffer db 25 dup(0)
number_buffer db 7 dup(0)
sector_number dw 0
hwinfo_buf dw 0
username db 15 dup(0)

ok_msg: db '[ OK ]', 0
hex_out: db '0x00', 0
kernel_seg_str: db 'Kernel Segment: ', 0
kernel_seg equ 0x1000
kernel_off equ 0x0000
;commands
help_str: db 'help', 0
clear_str: db 'clear', 0
ver_str: db 'ver', 0
info_str: db 'info', 0
ram_str: db 'ram', 0
setuser_str: db 'setuser', 0
reboot_str: db 'reboot', 0
whoami_str: db 'whoami', 0
unknown_msg: db 'No Command or Program found', 0
;programs
hwinfo_str: db 'hwinfo', 0
calc_str: db 'calc', 0
hello_str: db 'hello', 0
xir_str: db 'xir', 0
;command_output
help_msg: db 'Commands:                                  Programs: ', 0x0D, 0x0A,
          db 'HELP [shows all commands]                  CALC [calculator]', 0x0D, 0x0A,
          db 'CLEAR [clear the screen]                   HWINFO [hardware-information]', 0x0D, 0x0A,
          db 'GREEN/CYAN [change color]                  XIR [text editor]', 0x0D, 0x0A,
          db 'VER [shows current version]                ASCII [ascii table]', 0x0D, 0x0A,
          db 'RAM [show usable ram]', 0x0d, 0x0a,
          db 'WHOAMI [show current user (debug cmd)]', 0x0d, 0x0a, 
          db 'SETUSER [set a username]', 0x0d, 0x0a, 0

ver_msg: db 'Copyright (C) Technodon, Xiromos Bootloader and Kernel Filesystem-Version', 0

info__logo: db ' __ ', 13, 10, 
            db '|__|', 13, 10,
            db ' __     Host-PC: x86', 13, 10,
            db '|  |    Video-Mode: VGA Mode 0x12', 13, 10,
            db '|  |    Resolution: 640x480, 16 Colors', 13, 10,
            db '|  |    Kernel: Xir FS-Ver', 13, 10,
            db '|  |    Version: Xiromos Filesystem Version', 13, 10,
            db '|  |    Font: Standard', 13, 10,
            db '|__|    Terminal: Standard', 13, 10, 0

whoami_msg: db 'Current User: ', 0
no_user: db 'No User Set', 0
username_msg: db 'Enter your username...', 0x0d, 0x0a, 0
username_success: db '                  Username saved!', 0x0d, 0x0a, 0

k_str: db ' KB', 0
base_mem_kb dw 0
mem_base_str: db 'Base Memory: ', 0
first_boot_value: db 0
username_set: db 0
;filesystem
program_hwinfo_bin db "HWINFO  BIN"
program_calc_bin   db "CALC    BIN"
program_hello_bin  db "HELLO   BIN"
program_xir_bin    db "XIR     BIN"
program_ascii_bin  db "ASCII   BIN"
file_test_txt      db "TEST    TXT"

root_entries: dw 0
program_cluster: dw 0
sec_per_cluster: db 0
data_start_sec: dw 0
drive_number: db 0

program_dap:
    db 0x10                        ;size of packet (16 bytes)      [program_dap+0]
    db 0                           ;always 0                       [program_dap+1]
    dw 0                           ;number of sectors to read      [program_dap+2]
    dw 0x0000                      ;offset                         [program_dap+4]
    dw 0x0000                      ;segment                        [program_dap+6]
    dq 0                           ;LBA                            [program_dap+8]

filecluster_notfound: db 'Invalid File CLuster', 0
programnotfound_str: db 'No Program Found', 0
disk_error_msg: db 'Disk Read Error Occured...', 0
