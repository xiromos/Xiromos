
<h1 class="title">Xiromos Operating System</h1>
<p>A lightweight, terminal-based operating system</p>
<p>It works in 16Bit mode and is fully written in assembly</p>
<p>The operating system is in active work, new commands, programs or features are continuous updated</p>
<p>It contains a bootloader, kernel and 3 programs</p>

<h2><u>COMMANDS</u></h2>
<p>help: shows existing commands</p>
<p>ver: shows current version</p>
<p>clear: clears screen</p>
<p>green: turns background to green</p>
<p>cyan: turns background to cyan</p>
<p>info: shows general information</p>
<p>setuser: set a username</p>
<p></p>
</br></br>

<h2><u>PROGRAMS</u></h2>
<p>calc: simple calculator</p>
<p>hwinfo: shows some hardware information</p>
<p>xir: text editor [soon with highlighting assembly language]</p>
<h2><u>FEATURES</u></h2>
<p>FAT16 filesystem support</p>
<p>IMPORTANT - Unfortunatly you cant start OS this on older mainboards, <br/>
   because the might not support EDD (Enhanced Disk Services)<br/>
   I will try to implement CHS Reading, so these boards will work too, <br/>
   but for now there is no support for them.
</p>
</br></br>

<h3>TODOs</h3>
<p>- implement own assembler</p>
<p>- implement own compiler</p>
<p>- multiple disk support</p>
<p>- implement a game :)</p>
<p>- fix bugs</p>
<p>- make a better text editor</p>
<p>- FAT12 support</p>
<p>- make a mouse driver</p>
<p>- implement own fonts</p>

<h2>UPDATE: FILESYSTEM VERSION</h2>
<p>- FAT16 support</p>
<p>- updated theme and terminal</p>
<p>- fixed bugs</p>
<p>- editor program</p>
<p>- hello.bin program</p>
<p>- int 0x20 - loads and executes a program (expects the filename in SI)</p>
<p>- int 0x22 - file operations</p>
<p>- AH = 0x01, filename in SI: read file</p>
<p>- AH = 0x02, filename in SI: write an empty file</p>
<p>- AH = 0x03, filename in SI: list content of root directory</p>
<p>- AH = 0x04, filename in SI: rename an existing file</p>
<p>- AH = 0x05, filename in SI: delete a file</p>
<p>- programs use RETF to return to kernel, instead of reloading it</p>
<p>- argument support</p>
<p>- **new commands:**</p>
<p>- READ (read a text file)</p>
<p>- WRITE (write a text file)</p>
<p>- RENAME (rename a text file)</p>
<p>- DEL (delete a file or program)</p>
<p>- LSDISK (show available disks)</p>
<p>- CDISK (change disk to save data on it)</p>
<p>> _</p>
<p>DOWNLOAD disk image:</p>
<a href="xiromos.netlify.app">Here</a><br/>
<a href="https://youtube.com/@Xiromos">Youtube</a><br/>
<sub>© 2026 Technodon. All rights reserved</sub>
