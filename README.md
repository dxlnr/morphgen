# Morphgen

Implementing a Processor using the [RISC-V](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) instruction set.

#### ELF
Overview of The Executable and Linkable Format

The Executable and Linkable Format, also known as ELF, is the generic file format 
for executables in Linux systems.
ELF files are composed of three major components:
    - ELF Header
    - Sections
    - Segments

[ELF-101: Segments & Sections](https://www.intezer.com/blog/research/executable-linkable-format-101-part1-sections-segments/)

#### RISC-V ISA

## General registers

The RV32I base integer ISA includes 32 registers, named `x0` to `x31`. The
program counter `PC` is separate from these registers, in contrast to other
processors such as the ARM-32. The first register, `x0`, has a special function:
Reading it always returns 0 and writes to it are ignored. As we will see later,
this allows various tricks and simplifications.

In practice, the programmer doesn't use this notation for the registers. Though
`x1` to `x31` are all equally general-use registers as far as the processor is
concerned, by convention certain registers are used for special tasks. In
assembler, they are given standardized names as part of the RISC-V **application
binary interface** (ABI). This is what you will usually see in code listings. If
you really want to see the numeric register names, the `-M` argument to objdump
will provide them.

Register  | ABI         | Use by convention                     | Preserved?
:-------- | :---------- | :---------------                      | ------
x0        | zero        | hardwired to 0, ignores writes        | _n/a_
x1        | ra          | return address for jumps              | no
x2        | sp          | stack pointer                         | yes
x3        | gp          | global pointer                        | _n/a_
x4        | tp          | thread pointer                        | _n/a_
x5        | t0          | temporary register 0                  | no
x6        | t1          | temporary register 1                  | no
x7        | t2          | temporary register 2                  | no
x8        | s0 _or_ fp  | saved register 0 _or_ frame pointer   | yes
x9        | s1          | saved register 1                      | yes
x10       | a0          | return value _or_ function argument 0 | no
x11       | a1          | return value _or_ function argument 1 | no
x12       | a2          | function argument 2                   | no
x13       | a3          | function argument 3                   | no
x14       | a4          | function argument 4                   | no
x15       | a5          | function argument 5                   | no
x16       | a6          | function argument 6                   | no
x17       | a7          | function argument 7                   | no
x18       | s2          | saved register 2                      | yes
x19       | s3          | saved register 3                      | yes
x20       | s4          | saved register 4                      | yes
x21       | s5          | saved register 5                      | yes
x22       | s6          | saved register 6                      | yes
x23       | s7          | saved register 7                      | yes
x24       | s8          | saved register 8                      | yes
x25       | s9          | saved register 9                      | yes
x26       | s10         | saved register 10                     | yes
x27       | s11         | saved register 11                     | yes
x28       | t3          | temporary register 3                  | no
x29       | t4          | temporary register 4                  | no
x30       | t5          | temporary register 5                  | no
x31       | t6          | temporary register 6                  | no
pc        | _(none)_    | program counter                       | _n/a_

_Registers of the RV32I. Based on RISC-V documentation and Patterson and
Waterman "The RISC-V Reader" (2017)_

#### Additional Material

Course: [Computer Systems Organization](https://nyu-cso.github.io/index.html)

[Unofficial RISC-V Manual](https://jemu.oscc.cc/)

[rvcodec.js]: An online encoder/decoder for RISCV-V instructions.
