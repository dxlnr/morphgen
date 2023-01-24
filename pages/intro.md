# On Writing a Processor

RISC-V is around and matured. The purpose of this text is pretty much to describe
my journey of writing a processor first in Python and afterwards in Verilog.

## ELF

#### Program headers

An ELF file consists of zero or more segments, and describe how to create a process/memory
image for runtime execution. When the kernel sees these segments, 
it uses them to map them into virtual address space, using the mmap(2) system call. 
In other words, it converts predefined instructions into a memory image.
