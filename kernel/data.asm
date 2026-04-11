bits 16
[org 0x0000]

;================================
; Strings and Buffers
;================================
;start
welcome_msg: db 'Type "help" For Help.', 0x0d, 0x0a, 0
github_link: db 'GITHUB: https://github.com/xiromos/Xiromos', 0
copyright_str: db 'Copyright (C) 2026 Technodon', 0
;header db 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xDB, 0xDB, ' ', 'Xiromos', ' ', 0xDB, 0xDB, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0
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
input_buffer: times 512 db 0
drive_buffer: db 0
arg_buffer: db 12 dup(0)

ok_msg: db '[ OK ]', 0
hex_out: db '0x00', 0
zero_zero: db '00', 0
kernel_seg_str: db 'Kernel Segment: ', 0
kernel_seg equ 0x1000
kernel_off equ 0x0000
fat_offset equ 0x3999
dir_seg    equ 0x9000
prog_seg   equ 0x5000
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
lsdisk_str: db 'lsdisk', 0
cdisk_str: db 'cdisk', 0
pwd_str: db 'pwd', 0
textedit_str: db 'edit', 0
cd_str: db 'cd', 0
mkdir_str: db 'mkdir', 0
deldir_str: db 'deldir', 0
shutdown_str: db 'shutdown', 0
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
          db 'WHOAMI [show current username]             XFETCH [shows system info]', 0x0d, 0x0a, 
          db 'SETUSER [set a username]                   To execute a program just type its', 0x0d, 0x0a, 
          db 'REBOOT [restart system]                    name into the terminal', 0x0d, 0x0a,
          db 'READ [read a .txt or an .asm file]', 0x0d, 0x0a,
          db 'WRITE [write a .txt or .asm file]', 0x0d, 0x0a,
          db 'LS [shows content of root directory]', 0x0d, 0x0a,
          db 'RENAME [rename a file]', 0x0d, 0x0a,
          db 'DEL [delete a file]', 0x0d, 0x0a,
          db 'CDISK [change disk]', 0x0d, 0x0a, 0

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
;filenames
file_kernel_bin    db "KERNEL  BIN"
program_hwinfo_bin db "HWINFO  BIN"
program_calc_bin   db "CALC    BIN"
program_hello_bin  db "HELLO   BIN"
program_xir_bin    db "XIR     BIN"
program_ascii_bin  db "ASCII   BIN"
program_edit_bin db "EDIT    BIN"
program_lsdisk_bin db "LSDISK  BIN"
program_help_bin: db "HELP    BIN"
dir_programs db "PROGRAMS   "
fat8_str db "FAT8    "
dot_str db ".          "
;red screen of death
rsod_header: db 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xDB, 0xDB, ' ','System Error', ' ', 0xDB, 0xDB, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB2, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB1, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0
rsod_str: db '      :(', 0
rsod_msg: db '      Your system ran into a serious problem. Press any key to reboot...', 0
rsod_link: db '         ', 0xaf, ' More Information: https://github.com/xiromos/Xiromos', 0
int9_addr:
    dw 0
    dw 0
;filesystem
root_entries: dw 0
program_cluster: dw 0
sec_per_cluster: db 0
data_start_sec: dw 0
drive_number: db 0
fat_size: dw 0
reserved_sectors: dw 0
root_start_sec: dw 0
root_size: dw 0
bytes_per_sec: dw 0
fat_num: db 0

drives: dw 0
floppies: dw 0
external_drive_number: db 0
string_length: dw 11
argument: dw 0

sec_per_track: dw 0
num_heads: dw 0

absolute_sector: db 0
absolute_head: db 0
absolute_cylinder: db 0
fat8: db 0
cluster8: db 0

program_dap:
    db 0x10                        ;size of packet (16 bytes)      [program_dap+0]
    db 0                           ;always 0                       [program_dap+1]
    dw 0                           ;number of sectors to read      [program_dap+2]
    dw 0x0000                      ;offset                         [program_dap+4]
    dw 0x0000                      ;segment                        [program_dap+6]
    dq 0                           ;LBA                            [program_dap+8]
;file operations
filecluster_notfound: db 'Invalid File CLuster', 0
programnotfound_str: db 'No Command or Program found', 0
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
ls_header: db 'Name:          Size (bytes):         Drive number: ', 0
ls_size: dw 0
first_cluster: dw 0
first_cluster_str: db 'Data Cluster: ', 0
rename_msg: db 'Enter the new file name: ', 0
a20_gate: db 'A20 Gate: ', 0
a20_enabled: db 'Enabled', 0
a20_disabled: db 'Disabled', 0
invalid_rename: db 'Cant rename or delete KERNEL.BIN', 0
delete_success: db 'File deleted successfully!', 0
sys_file_str: db 'This file is a system file. You cant delete it', 0
kernel_exec_err: db 'Cant execute kernel file', 0
;external drives
external_drives_str: db 'External Drives: ', 0
external_floppies_str: db 'External Floppies: ', 0
change_drive_str: db 'Enter Drive: ', 0
no_drive_msg: db 'No external drives found', 0
no_valid_drive: db 'Not a valid drive', 0
current_disk_msg: db 'You cant cd into the root disk', 0
no_floppy_sup: db 'This system doesnt support floppies right now. This will be changed in later', 0x0a, 0x0d, 
               db 'updates', 0
get_bpb_ok: db 'Successfully changed to root disk', 0
disk_loaded_msg: db 'Disk changed successfully. To return, type "cdisk C"', 0
no_ext_str: db 'Invalid extension', 0
buffer_adress: dw 0
;floppy
flp_error_msg: db 'Error while reading floppy disk', 0
floppy_read_success: db 'Successfully switched to floppy disk', 0
flp_file_error: db 'Error while reading file', 0
fat_cluster: dw 0
;directories
no_dir_str: db 'This is not a directory', 0
dir_success: db 'Directory created successfully', 0

sub_dir: db 0       ;0 = root, 1 = sub
parent_dir: dw 0   ;cluster of the parent directory, 0 = root
current_dir: dw 0       ;cluster of the current directory, 0 = root

changed_dir_root: db 'Successfully changed to root directory', 0
changed_dir_msg: db 'Successfully changed directory. To return to root type "cd /"', 0
root_only: db 'This function is root-only', 0
dot_entry_error: db 'Error while writing dot entries', 0
load_dir_err_msg: db 'Error while loading directory. You are in the root directory now', 0
dot_dot_str: db '..'
no_dot_str: db 'Dot Entry not found', 0
dir_str: db '<dir>', 0
read_dir_str: db 'This is a directory', 0