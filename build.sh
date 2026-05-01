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
nasm -f bin programs/ascii.asm -o programs/ascii.bin
nasm -f bin programs/xir.asm -o programs/xir.bin
nasm -f bin programs/xfetch.asm -o programs/xfetch.bin
nasm -f bin programs/lsdisk.asm -o programs/lsdisk.bin
nasm -f bin programs/xedit.asm -o programs/xedit.bin
nasm -f bin programs/xformat.asm -o programs/xformat.bin
nasm -f bin programs/help.asm -o programs/help.bin
nasm -f bin programs/font.asm -o programs/font.bin
nasm -f bin programs/scancode.asm -o programs/scancode.bin
printf "${GREEN}Succesfully compiled files!${RESET}\n"
cp programs/ascii.bin zprograms/
cp programs/calc.bin zprograms/
cp programs/font.bin zprograms/
cp programs/hello.bin zprograms/
cp programs/help.bin zprograms/
cp programs/hwinfo.bin zprograms/
cp programs/lsdisk.bin zprograms/
cp programs/scancode.bin zprograms/
cp programs/xedit.bin zprograms/
cp programs/xfetch.bin zprograms/
cp programs/xformat.bin zprograms/
cp programs/xir.bin zprograms/

# nasm -f bin ~/Downloads/xmode/kernel/kernel.asm -o ~/Downloads/xmode/kernel/kernel.bin                # Uncomment to use XMODE
# nasm -f bin ~/Downloads/xmode/programs/help.asm -o ~/Downloads/xmode/programs/help.bin                # Uncomment to use XMODE


# rm disk.img
dd if=/dev/zero of=disk.img bs=1M count=9
mkdosfs -F 16 -v disk.img
dd if=boot.bin of=disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc
mcopy -i disk.img kernel/kernel.bin ::KERNEL.BIN
# mcopy -i disk.img ~/Downloads/xmode/kernel/kernel.bin ::XMODE.BIN                                     # Uncomment to use XMODE
# mcopy -i disk.img programs/help.bin ::HELP.BIN
mcopy -i disk.img ~/Downloads/xmode/programs/help.bin ::HELP.BIN
mcopy -i disk.img txt/ ::TXT
mcopy -i disk.img zprograms/ ::PROGRAMS
mcopy -i disk.img -s a ::/
mcopy -i disk.img txt/fscmds.txt ::TEST.TXT
# mattrib -i disk.img +s ::KERNEL.BIN
# mattrib -i disk.img +s ::XMODE.BIN
printf "${MAGENTA}Disk layout:${RESET}\n"
mdir -i disk.img ::
# mdir -i floppy.img ::
printf "${GREEN}Copied data to disk image. Loading QEMU...${RESET}\n"
qemu-system-i386 -hda disk.img -hdb disk2.img -fda floppy.img -fdb floppy8.img -m 64M # -d int -no-reboot # -hdc disk3.img
# mkdosfs -F 12 -v disk3.img
# mkdosfs -F 16 -v disk2.img

# memory map
# 0x0x0000:0500: root directory
# 0x0000:0x3999: FAT
# 0x0000:0x7c00: boot code
# 0x1000:x0000: kernel.bin
# 0x5000:0x0000: programs
# 0xFFFE: kernel stack
# 0x9000:0x0000: directories
# 0x9000:0x7c00: boot code of external disks

# write on USB stick:
# lsblk
# sudo dd if=disk.img of=/dev/sdb bs=4M status=progress conv=fsync
# sync