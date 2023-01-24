import struct
import glob
from elftools.elf.elffile import ELFFile

from elf import elf_reader, elf_str_ins

# CPU operates on 32-bit units, attach the pc for 33 entries.
registers = [0] * 33
# Programm Counter
PC = 32
# Stackpointer
S = 0
# Processor Flag
P = [False] * 32

def fetch32(addr):
    addr -= 0x80000000
    assert addr >= 0 and addr < len(memory)
    return struct.unpack("I", memory[addr:addr+4])[0]

def step():
    # Instruction Fetch
    ins = fetch32(registers[PC])
    # Instruction Decode
    print(elf_str_ins(ins))
    # Execute

    # Memory Access

    # Writeback
    return False

if __name__ == "__main__":
    # 64k memory 
    memory = b'\x00' * 0x10000

    for x in glob.glob("modules/riscv-tests/isa/rv32ui-*"):
        if x.endswith('.dump'):
            continue
        print("test : ", x)
        # Reading the elf program header to memory.
        memory = elf_reader(memory, x)
        
        registers[PC] = 0x80000000
        while step():
            pass
        break
