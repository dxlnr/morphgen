.section .text
.global _start

_start:
    // Your startup code here

    // Call main function
    bl main

    // Exit the program
    mov r7, #1
    mov r0, #0
    swi 0x0

