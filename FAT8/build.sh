
nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin

dd if=/dev/zero of=floppy8.img bs=1K count=128
dd if=boot.bin of=floppy8.img conv=notrunc
dd if=kernel.bin of=floppy8.img seek=4 conv=notrunc

qemu-system-i386 -hda floppy8.img