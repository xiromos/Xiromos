section .data
    text_msg: db 'Hello from the smallest Assembly program!', 0x0a, 0x0a, 0

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, text_msg
    mov rdx, 40
    syscall

    call print_newline

    mov rax, 60
    mov rdi, 0
    syscall

print_newline:
    mov rax, 1
    mov rsi, 0x0a
    syscall
    ret
