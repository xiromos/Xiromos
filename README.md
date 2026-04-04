
<h1 class="title">Xiromos Operating System</h1>
<p>A lightweight, terminal-based operating system</p>
<p>It works in 16Bit mode and is fully written in assembly</p>
<p>The operating system is in active work, new commands, programs or features are continuous updated</p>
<p>It contains a bootloader, kernel and some programs</p>

<h2><u>COMMANDS</u></h2>
<p>help: shows existing commands</p>
<p>clear: clears screen</p>
<p>info: shows general information</p>
<p>setuser: set a username</p>
<p>ram: show available ram</p>
<p>read: read a textfile</p>
<p>write: write a textfile to the disk</p>
<p>rename: rename a file</p>
<p>del: delete a file or a program</p>
<p>ls: list content of root directory</p>
</br></br>

<h2><u>PROGRAMS</u></h2>
<p>calc: simple calculator</p>
<p>hwinfo: shows some hardware information</p>
<p>xir: text editor </p>
<p>edit: another (better) texteditor</p>
<p>lsdisk: show status of available disks</p>
<p>info: general system information (fetch-like)</p>
<p>ascii: ascii table</p></br>
<h2><u>FEATURES</u></h2>
<p>- FAT16 filesystem support</p>
<p>- FAT12 filesystem support</p>
<p>- Multi Disk Support</p>
<p>- floppy and hard disk support</p>
<p>- file operations on both disks available</p>
<p>- many systemcalls for file operations</p></br>
<p>IMPORTANT - Unfortunatly you cant start OS this on older mainboards, <br/>
   because the might not support EDD (Enhanced Disk Services)<br/>
   I will try to implement CHS Reading, so these boards will work too, <br/>
   but for now there is no support for them.
</p>
</br></br>

<h3>TODOs</h3>
<p>- implement own assembler</p>
<p>- implement own compiler</p>
<p>- implement a game :)</p>
<p>- fix bugs</p>
<p>- make a better text editor</p>
<p>- make a mouse driver</p>
<p>- implement own fonts</p>
<p>- FAT32 support</p>

<h2>UPDATE: FILESYSTEM VERSION</h2>
<p>- FAT16 support</p>
<p>- FAT12 support</p>
<p>- updated theme and terminal</p>
<p>- fixed bugs</p>
<p>- 2 editor programs</p>
<p>- hello.bin program</p>
<p>- lsdisk program</p>
<p>- int 0x20 - loads and executes a program (expects the filename in SI)</p>
<p>- int 0x22 - file operations</p>
<p>- AH = 0x01, filename in SI: read file</p>
<p>- AH = 0x02, filename in SI: write an empty file</p>
<p>- AH = 0x03, filename in SI: list content of root directory</p>
<p>- AH = 0x04, filename in SI: rename an existing file</p>
<p>- AH = 0x05, filename in SI: delete a file</p>
<p>- programs use RETF to return to kernel, instead of reloading it</p>
<p>- argument support</p>
<p>- better command interpreter</p>
<p>- multi disk support</p>
<p>- file operation on hard disks AND floppy disks</p>
<p>- programs run on both disks</p>
<h3>New commands:</h3>
<p>- READ (read a text file)</p>
<p>- WRITE (write a text file)</p>
<p>- RENAME (rename a text file)</p>
<p>- DEL (delete a file or program)</p>
<p>- LSDISK (show available disks)</p>
<p>- CDISK (change disk to save data on it)</p>
<p>> _</p>
<p>Download disk image <a href="xiromos.netlify.app">here</a></p><br/>
<a href="https://youtube.com/@Xiromos">Youtube</a><br/>
