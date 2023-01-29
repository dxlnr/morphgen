import struct
import glob
from elftools.elf.elffile import ELFFile

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


def fetch32(memory, addr):
    addr -= 0x80000000
    assert addr >= 0 and addr < len(memory)
    return struct.unpack("I", memory[addr : addr + 4])[0]

def decode32(ins):
    # Bitwise ops to decode the instruction.
    opscode = (ins >> 7, ins & 255)[1]
     
    if opscode == 0b1101111:
        print(f"Instruction: {OPCODE[opscode]}")
        ins = ins >> 12


def step(memory):
    # Instruction Fetch
    ins = fetch32(memory, registers[PC])
    
    # Instruction Decode
    decode32(ins)
    
    # Execute

    # Memory Access

    # Writeback
    return True

 
if __name__ == "__main__":
    # 64k memory
    memory = b"\x00" * 0x10000

    for x in glob.glob("modules/riscv-tests/isa/rv32ui-*"):
        if x.endswith(".dump"):
            continue
        print("test : ", x)
        # Reading the elf program header to memory.
        memory = elf_reader(memory, x)

        test = 0x0
        print(memory[test: test +4]) 
        print(memory[test: test +4].hex())


        registers[PC] = 0x80000000
        i = 0
        while step(memory):
            i += 1
            if i == 1:
                registers[PC] = 0x8000000c
            if i >= 2:
                break
        break
