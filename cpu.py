import struct
import glob
from elftools.elf.elffile import ELFFile

from elf import elf_reader

# CPU operates on 32-bit units, attach the pc for 33 entries.
registers = [0] * 33
# Programm Counter
PC = 32
# Stackpointer
S = 0
# Processor Flag
P = [False] * 32
# 4GB mem 
memory = b'\x00' * 0x10000

def fetch32(addr):
    addr -= 0x80000000
    assert addr >= 0 and addr < len(memory)
    return struct.unpack("I", memory[addr:addr+4])[0]

def step():
    # Instruction Fetch
    ins = fetch32(registers[PC])
    # Instruction Decode
    # Execute

    # Memory Access

    # Writeback
    return ins

if __name__ == "__main__":
    for x in glob.glob("modules/riscv-tests/isa/rv32ui-*"):
        memory = elf_reader(memory, x)
        break
