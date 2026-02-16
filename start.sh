nasm -f bin boot.asm -o boot.bin && qemu-system-i386 -drive format=raw,file=boot.bin -display gtk
