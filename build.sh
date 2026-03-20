RED="\033[31m"
GREEN="\033[32m"
MAGENTA="\033[35m"
RESET="\033[0m"

set -e
trap 'printf "${RED}Build failed!${RESET}\n"; exit 1' ERR

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel/kernel.asm -o kernel/kernel.bin
nasm -f bin programs/hwinfo.asm -o programs/hwinfo.bin
nasm -f bin programs/calc.asm -o programs/calc.bin
nasm -f bin programs/hello.asm -o programs/hello.bin
nasm -f bin programs/xir.asm -o programs/xir.bin
printf "${GREEN}Succesfully compiled files!${RESET}\n"
rm disk.img
dd if=/dev/zero of=disk.img bs=1M count=16
mkdosfs -F 16 -v disk.img
dd if=boot.bin of=disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc
mcopy -i disk.img kernel/kernel.bin ::KERNEL.BIN
mcopy -i disk.img programs/hwinfo.bin ::HWINFO.BIN
mcopy -i disk.img programs/calc.bin ::CALC.BIN
mcopy -i disk.img programs/hello.bin ::HELLO.BIN
mcopy -i disk.img programs/xir.bin ::XIR.BIN
mcopy -i disk.img programs/test.txt ::TEST.TXT
printf "${MAGENTA}Disk layout:${RESET}\n"
mdir -i disk.img ::
printf "${GREEN}Copied data to disk image. Loading QEMU...${RESET}\n"
qemu-system-i386 -hda disk.img -m 2M


# memory map
# 0x0x0000:0500: root directory
# 0x0000:0x3999: FAT
# 0x1000:x0000: kernel.bin
# 0x2000:0x0000: programs
# 0xFFFE: kernel stack
# 0x0000:0x8000: int 0x20

# TODO
# -write own emulator
# -design own CPU
# -write own AI
# -write own programming language with compiler
# -write own assembler
# -write own CUDA driver
# -write own BIOS
# -