[org 0x0000]

start:
    mov ax, 0x5000
    mov es, ax
    mov ds, ax

    mov si, header
    mov bh, 0x02
    mov bl, 0x0b
    int 0x27

    mov si, help
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, clear
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, ram
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, reboot
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, header2
    mov bh, 0x02
    mov bl, 0x0b
    int 0x27

    mov si, read
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, write
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, rename
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, del
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, ls
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, mkdir
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, cd
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, deldir
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, cdisk
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov si, syntax_header
    mov bh, 0x02
    mov bl, 0x0b
    int 0x27

    mov si, syntax
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

exit:
    retf

;--data--
header: db '----Standard Commands----', 0x0a, 0x0d, 0
help: db 'HELP: shows this help message', 0x0a, 0x0d, 0
clear: db 'CLEAR: clears the screen', 0x0a, 0x0d, 0
ram: db 'RAM: shows available ram', 0x0a, 0x0d, 0
reboot: db 'REBOOT: restarts the system', 0x0a, 0x0d, 0x0a, 0

header2: db '----File Operation Commands----', 0x0a, 0x0d, 0
read: db 'READ: read a text file', 0x0a, 0x0d, 0
write: db 'WRITE: write a text file [max. 512 bytes]', 0x0a, 0x0d, 0
rename: db 'RENAME: rename a file', 0x0a, 0x0d, 0
del: db 'DEL: delete a file or a program [some are protected]', 0x0a, 0x0d, 0
ls: db 'LS: list content of the current directory', 0x0a, 0x0d, 0
mkdir: db 'MKDIR: create a directory', 0x0a, 0x0d, 0
cd: db 'CD: change directory, [arguments are "/" and "-"]', 0x0a, 0x0d, 0
deldir: db 'DELDIR: delete an empty directory', 0x0a, 0x0d, 0
cdisk: db 'CDISK: change disk', 0x0a, 0x0d, 0x0a, 0

syntax_header: db 'Syntax: command <argument>', 0x0a, 0x0d, 0
syntax: db 'You can give the command only one argument.', 0x0a, 0x0d,
        db 'If there is any command that requires two arguments,', 0x0a, 0x0d,
        db 'give it the first argument and then press Enter, because', 0x0a, 0x0d,
        db 'the command will ask you for the second argument.', 0x0a, 0x0d,
        db 'If there is any command you doesnt want to execute anymore', 0x0a, 0x0d,
        db 'press "q". This will always bring you back', 0x0a, 0x0d,
        db 'to the terminal.', 0x0a, 0x0d, 0