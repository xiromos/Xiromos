void kernel_main() {
    unsigned char* vga = (unsigned char*) 0xb8000;
    vga[0] = 'X'; //need to make sure that this is a character
    vga[1] = 0x09; //append the attribute byte
    for(;;); //make sure our kernel never stops, with an infinite loop
}