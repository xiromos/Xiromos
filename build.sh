#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
MAGENTA="\033[35m"
RESET="\033[0m"

set -e
trap 'printf "${RED}Build failed!${RESET}\n"; exit 1' ERR

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
nasm -f bin calc.asm -o calc.bin
nasm -f bin hwinfo.asm -o hwinfo.bin
printf "${GREEN}Succesfully compiled files!${RESET}\n"
dd if=/dev/zero of=disk.img bs=512 count=16
dd if=boot.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img bs=512 seek=1 conv=notrunc
dd if=calc.bin of=disk.img bs=512 seek=4 conv=notrunc
dd if=hwinfo.bin of=disk.img bs=512 seek=9 conv=notrunc
printf "${GREEN}Copied data to disk image. Loading QEMU...${RESET}\n"
qemu-system-i386 -hda disk.img -m 512M