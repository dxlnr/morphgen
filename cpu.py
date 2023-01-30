"""32-Bit Processor"""
import struct
import glob

from elf import elf_reader
from riscv import OPCODE

# CPU operates on 32-bit units, attach the pc for 33 entries.
registers = [0] * 33
# Programm Counter
PC = 32
# Stackpointer
S = 0
# Processor Flag
P = [False] * 32


def decode_ins(ins: int, e: int, s: int):
    """Decode single instruction by slices.

    :param ins: Instruction as binary str.
    :param s: Starting point of chunk.
    :param e: Ending point of chunk.
    """
    return ins >> s & ((1 << (e - s + 1)) - 1)


def fetch32(addr):
    addr -= 0x80000000
    assert addr >= 0 and addr < len(memory)
    return struct.unpack("I", memory[addr : addr + 4])[0]


def decode32(ins):
    # Bitwise ops to decode the instruction.
    opscode = decode_ins(ins, 6, 0)
    # Keep track where the program is.
    print(f"  {hex(registers[PC])} : {hex(ins)} : {OPCODE[opscode]}")
    # Compute register destination.
    rd = decode_ins(ins, 11, 7)

    if opscode == 0b1101111:
        assert rd == 0
        imm = decode_ins(ins, 31, 12)

        offset = (
            ((decode_ins(imm, 19, 19) << 12) - decode_ins(imm, 19, 19))
            | decode_ins(imm, 7, 0)
            | decode_ins(imm, 8, 8)
            | decode_ins(imm, 18, 9)
        ) << 1

        registers[PC] += offset

    elif opscode == 0b0010011:
        # Needs some work.
        func3 = decode_ins(ins, 14, 12)
        rs1 = decode_ins(ins, 19, 15)
        imm = decode_ins(ins, 31, 20)

        offset = (
            (decode_ins(imm, 11, 11) << 21) - decode_ins(imm, 11, 11)
        ) | decode_ins(imm, 10, 0)

        registers[PC] += 4

    elif opscode == 0b0010111:
        imm = decode_ins(ins, 31, 12)

        offset = imm << 12

        registers[rd] = offset
        registers[PC] += 4
    
    elif opscode == 0b1110011:
        pass
    else:
        return False
    
    return True

def step():
    # Instruction Fetch
    ins = fetch32(registers[PC])

    # Instruction Decode

    # Execute

    # Memory Access

    # Writeback

    return decode32(ins)


if __name__ == "__main__":
    # 64k memory
    memory = b"\x00" * 0x10000

    for x in glob.glob("modules/riscv-tests/isa/rv32ui-*"):
        if x.endswith(".dump"):
            continue
        print(f"Execute : {x}\n")
        # Reading the elf program header to memory.
        memory = elf_reader(memory, x)

        registers[PC] = 0x80000000
        i = 0
        while step():
            pass
        break
