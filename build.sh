RED="\033[31m"
GREEN="\033[32m"
MAGENTA="\033[35m"
RESET="\033[0m"

set -e
trap 'printf "${RED}Build failed!${RESET}\n"; exit 1' ERR

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
printf "${GREEN}Succesfully compiled files!${RESET}\n"
dd if=/dev/zero of=disk.img bs=1M count=16
#mkfs.fat -F 16 disk.img
#dd if=boot.bin of=disk.img conv=notrunc
#dd if=kernel.bin of=disk.img bs=512 seek=18 conv=notrunc
mkdosfs -F 16 disk.img 
#dd if=boot.bin of=disk.img bs=1 count=11 conv=notrunc
dd if=boot.bin of=disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc
mcopy -i disk.img kernel.bin ::KERNEL.BIN
printf "${MAGENTA}Disk layout:${RESET}\n"
mdir -i disk.img ::
printf "${GREEN}Copied data to disk image. Loading QEMU...${RESET}\n"
qemu-system-i386 -hda disk.img


# memory map
# 0x0800: root directory
# 0x1300: FATs
# 0x????: data
# 0x2000: kernel.bin
# 0xFFFF: Stack