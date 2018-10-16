# Description
"Online" is a program for the Apple II series of computers running ProDOS. It displays all the "online volumes" which means that it displays all the disks that are currently connected to the system, along with their slot and drive numbers. ProDOS provides no built-in way to determine this information from inside the BASIC.SYSTEM command line. Here is an example of the output:

    ]-ONLINE
    S3,D2 /RAM
    S7,D1 /SYSTEM
    S7,D2 /VISICALC
    S6,D1 (NOT A PRODOS DISK)
    S6,D2 /ONLINE

# Etymology (which is different from [Entomology](https://en.wikipedia.org/wiki/Entomology))
It is named after the ProDOS [ON_LINE](http://www.easy68k.com/paulrsm/6502/PDOS8TRM.HTM#4.4.6) system call that is used to retrieve volume information.

# Download Binary Executable
See the https://github.com/gungwald/online/releases page for a disk image with a binary version that's ready to run.
