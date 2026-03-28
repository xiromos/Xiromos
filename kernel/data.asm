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

logo: db '___      ___  __   __      _____   __    __   _____           ', 13, 10
      db '\  \    /  / |__| |   \_  | ___ | |  \  /  | | ___ |  _____   ', 13, 10
      db ' \  \  /  /   __  |   __| | | | | |   \/   | | | | | |  ___|  ', 13, 10
      db '  \  \/  /   |  | |  |    | | | | |  \  /  | | | | | | |___   ', 13, 10 
      db '  /  /\  \   |  | |  |    | | | | |  |  |  | | | | | |___  |  ', 13, 10
      db ' /  /  \  \  |  | |  |    | |_| | |  |  |  | | |_| |  ___| |  ', 13, 10
      db '/_ /    \ _\ |__| |__|    |_____| |__|  |__| |_____| |_____|  ', 13, 10, 0

prompt_front: db '[', 0
prompt_back: db ']', 0
prompt: db '> ', 0
drive_num_str: db 'Drive Number: ', 0
prefix_0x: db '0x', 0

command_buffer db 25 dup(0)
number_buffer db 7 dup(0)
read_buffer db 11 dup(0)
read_buffer2 db 255 dup(0)
sector_number dw 0
hwinfo_buf dw 0
username db 15 dup(0)
dir_files_buffer db 8 dup(0), 0
extension_files_buffer db 3 dup(0), 0

ok_msg: db '[ OK ]', 0
hex_out: db '0x00', 0
zero_zero: db '00', 0
kernel_seg_str: db 'Kernel Segment: ', 0
kernel_seg equ 0x1000
kernel_off equ 0x0000
a20_seg: dw 0
;commands
help_str: db 'help', 0
clear_str: db 'clear', 0
ver_str: db 'ver', 0
info_str: db 'info', 0
ram_str: db 'ram', 0
setuser_str: db 'setuser', 0
reboot_str: db 'reboot', 0
whoami_str: db 'whoami', 0
read_str: db 'read', 0
write_str: db 'write', 0
ls_str: db 'ls', 0
rename_str: db 'rename', 0
del_str: db 'del', 0
unknown_msg: db 'No Command or Program found', 0
;programs
hwinfo_str: db 'hwinfo', 0
calc_str: db 'calc', 0
hello_str: db 'hello', 0
xir_str: db 'xir', 0
ascii_str: db 'ascii', 0
;command_output
help_msg: db 'Commands:                                  Programs: ', 0x0D, 0x0A,
          db 'HELP [show all commands]                   CALC [calculator]', 0x0D, 0x0A,
          db 'CLEAR [clear the screen]                   HWINFO [hardware-information]', 0x0D, 0x0A,
          db 'VER [show current version]                 ASCII [ascii table]', 0x0D, 0x0A,
          db 'RAM [show usable ram]                      XIR [assembly texteditor]', 0x0d, 0x0a,
          db 'WHOAMI [show current username]', 0x0d, 0x0a, 
          db 'SETUSER [set a username]                   To execute a program just type its', 0x0d, 0x0a, 
          db 'INFO [shows general information]           name into the terminal', 0x0d, 0x0a, 
          db 'REBOOT [restart system]', 0x0d, 0x0a,
          db 'READ [read a .txt or an .asm file]', 0x0d, 0x0a,
          db 'WRITE [write a .txt or .asm file]', 0x0d, 0x0a,
          db 'LS [shows content of root directory]', 0x0d, 0x0a,
          db 'RENAME [rename a file]', 0x0d, 0x0a,
          db 'DEL [delete a file]', 0x0d, 0x0a, 0

ver_msg: db 'Copyright (C) Technodon, Xiromos Filesystem-Version', 0

info__logo: db ' __ ', 13, 10, 
            db '|__|', 13, 10,
            db ' __     Host-PC: x86', 13, 10,
            db '|  |    Video-Mode: VGA Mode 0x12', 13, 10,
            db '|  |    Resolution: 640x480, 16 Colors', 13, 10,
            db '|  |    Filesystem: FAT16', 13, 10,
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
file_kernel_bin    db "KERNEL  BIN"
program_hwinfo_bin db "HWINFO  BIN"
program_calc_bin   db "CALC    BIN"
program_hello_bin  db "HELLO   BIN"
program_xir_bin    db "XIR     BIN"
program_ascii_bin  db "ASCII   BIN"
;file_test_txt     db "TEST    TXT"

root_entries: dw 0
program_cluster: dw 0
sec_per_cluster: db 0
data_start_sec: dw 0
drive_number: db 0
fat_size: dw 0
reserved_sectors: dw 0
root_start_sec: dw 0
root_size: dw 0

program_dap:
    db 0x10                        ;size of packet (16 bytes)      [program_dap+0]
    db 0                           ;always 0                       [program_dap+1]
    dw 0                           ;number of sectors to read      [program_dap+2]
    dw 0x0000                      ;offset                         [program_dap+4]
    dw 0x0000                      ;segment                        [program_dap+6]
    dq 0                           ;LBA                            [program_dap+8]

filecluster_notfound: db 'Invalid File CLuster', 0
programnotfound_str: db 'No Program Found', 0
filenotfound: db 'No File Found', 0
disk_error_msg: db 'Disk Read Error...', 0

read_prompt: db 'Enter a file name: ', 0
long_file_instruction: db 'To Read More Press A Key. To Quit Press Q', 0
file_content: db 'Enter File Content: ', 0
file_found_str: db 'File Found!', 0
file_content_str: db 'File Content: ', 0
no_entries: db 'No Free Entries Found', 0
entry_found: db 'Found Entry in Directory', 0
found_free_cluster: db 'Found free Cluster!', 0
write_sec_err: db 'Error while writing Data to Disk', 0
fat_error_msg: db 'Error while writing FAT Entry', 0
write_root_msg: db 'Error while writing directory entry', 0
write_success_msg: db 'File created successfully', 0
ls_header: db 'Name:          Size (bytes):', 0
ls_size: dw 0
first_cluster: dw 0
first_cluster_str: db 'Data Cluster: ', 0
rename_msg: db 'Enter the new file name: ', 0
a20_gate: db 'A20 Gate: ', 0
a20_enabled: db 'Enabled', 0
a20_disabled: db 'Disabled', 0
invalid_rename: db 'Cant rename or delete KERNEL.BIN', 0
delete_success: db 'File deleted successfully!', 0