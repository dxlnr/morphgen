import struct
import glob
from elftools.elf.elffile import ELFFile

# CPU operates on 32-bit units
registers = [0] * 32
# Programm Counter
PC = 32
# Stackpointer
S = 0
# Processor Flag
P = [False] * 32
# 4GB mem 
memory = b'\x00' * 0x1000

def fetch32(addr):
    addr -= 0x80000000
    return struct.unpack("I", memory[addr:addr+4])[0]

def step():
    pass
# Instruction Fetch

# Instruction Decode

# Execute

# Memory Access

# Writeback

if __name__ == "__main__":
    for x in glob.glob("modules/riscv-tests/isa/rv32ui-*"):
        if x.endswith(".dump"):
            continue
        with open(x, "rb") as f:
            elf = ELFFile(f)
            print(x, elf)