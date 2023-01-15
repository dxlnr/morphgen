import struct
import glob

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
print(type(memory))
print(memory)

def fetch32(addr):
    return struct.unpack("I", memory[addr:addr+4])[0]

def step():
    pass
# Instruction Fetch

# Instruction Decode

# Execute

# Memory Access

# Writeback

print(struct.unpack("I", b"\x00"*4))

if __name__ == "__main__":
    glob.glob()