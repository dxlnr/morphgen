"""32-Bit Processor"""
import struct
import glob

from elf import elf_reader
from riscv import OPCODE

# Programm Counter
PC = 32
# Stackpointer
S = 0
# Processor Flag
P = [False] * 32


def registers_to_str(registers) -> str:
    """Returns formatted str of all registers."""
    s = ""
    for i, c in enumerate(registers):
        if i % 5 == 0 and i != 0:
            s += "\n"
        s += f"\t%3s : %08x " % ("x%d" % i, c)
    return s


def bitmask(bits: int = 32) -> int:
    """Returns a bitmask based on number of bits."""
    return 2**bits - 1


def dins(ins: int, e: int, s: int):
    """Decode single instruction by slices.

    :param ins: Instruction as binary str.
    :param s: Starting point of chunk.
    :param e: Ending point of chunk.
    """
    return ins >> s & ((1 << (e - s + 1)) - 1)


def sext(val: int, bits: int):
    """Performs sign extension by number of bits given."""
    sb = 1 << (bits - 1)
    return (val & (sb - 1)) - (val & sb)


def fetch32(addr):
    addr -= 0x80000000
    if addr < 0 or addr >= len(memory):
        raise Exception("read out of memory: 0x%x" % addr)
    return struct.unpack("I", memory[addr : addr + 4])[0]


def step():
    """Process instructions."""
    # (1) Instruction Fetch
    ins = fetch32(registers[PC])

    # Instruction Decode
    # Execute
    # Memory Access
    # Writeback

    # (2) Instruction Decode
    #
    # Bitwise ops to decode the instruction.
    opscode = dins(ins, 6, 0)
    # Keep track where the program is.
    print(f"  {hex(registers[PC])} : {hex(ins)} : {OPCODE[opscode]}")
    # Compute register destination.
    rd = dins(ins, 11, 7)
    # Compute register sources.
    rs1 = dins(ins, 19, 15)
    rs2 = dins(ins, 24, 20)
    #
    func3 = dins(ins, 14, 12)
    #
    func7 = dins(ins, 31, 25)
    #
    imm_i = sext(dins(ins, 31, 20), 12)
    imm_u = sext(dins(ins, 31, 12) << 12, 32)
    # imm_s = sext(dins(ins, 31, 25) << 5 | dins(11, 7), 12)
    # imm_b = sign_extend((gibi(32, 31)<<12) | (gibi(30, 25)<<5) | (gibi(11, 8)<<1) | (gibi(8, 7)<<11), 13)
    # imm_u = sign_extend(gibi(31, 12)<<12, 32)
    # imm_j = sign_extend((gibi(32, 31)<<20) | (gibi(30, 21)<<1) | (gibi(21, 20)<<11) | (gibi(19, 12)<<12), 21)

    # JAL (Jump And Link)
    if opscode == 0b1101111:
        offset = (
            (dins(ins, 31, 31) << 12)
            | (dins(ins, 19, 12) << 11)
            | (dins(ins, 20, 20) << 10)
            | dins(ins, 31, 21)
        ) << 1

        registers[PC] += offset
        if rd != 0:
            registers[rd] = registers[PC] + 4

    # JALR (Jump And Link Register)
    elif opscode == 0b1100111:
        assert dins(ins, 14, 12) == 0
        rs1 = dins(ins, 19, 15)
        registers[rd] = registers[PC] + 4
        registers[PC] = (imm_i + registers[rs1]) & ~1

    # ALU
    elif opscode == 0b0010011:
        # ADDI (Add Immediate)
        if func3 == 0b000:
            registers[rd] = registers[rs1] + imm_i
        # SLLI (Shift Left Logical Immediate)
        elif func3 == 0b001:
            registers[rd] = (registers[rs1] << dins(ins, 24, 20)) & bitmask(32)
        # SLTI (Set Less Than Immediate)
        elif func3 == 0b010:
            registers[rd] = 1 if registers[rs1] < imm_i else 0
        # SLTIU (Set Less Than Immediate Unsigned)
        elif func3 == 0b011:
            registers[rd] = 1 if registers[rs1] < imm_i else 0
        # XORI (Exclusive OR Immediate)
        elif func3 == 0b100:
            registers[rd] = registers[rs1] ^ imm_i
        # SRLI (Shift Right Logical Immediate) & SRAI (Shift Right Arithmetic Immediate)
        elif func3 == 0b101:
            registers[rd] = registers[rs1] >> registers[rs2]
        # ORI (OR Immediate)
        elif func3 == 0b110:
            registers[rd] = registers[rs1] | imm_i
        # ANDI (AND Immediate)
        elif func3 == 0b111:
            registers[rd] = registers[rs1] & imm_i
        else:
            raise ValueError(
                f"func3 {hex(func3)} not processable for {OPCODE[opscode]}."
            )

        registers[PC] += 4

    # AUIPC
    elif opscode == 0b0010111:
        # imm = dins(ins, 31, 12)
        imm_u = sext(dins(ins, 31, 12), 32)

        registers[rd] = registers[PC] + imm_u
        registers[PC] += 4

    # OP
    elif opscode == 0b0110011:
        # ADD & SUB
        if func3 == 0b000:
            if func7 == 0b0:
                registers[rd] = (registers[rs1] + registers[rs2]) & bitmask()
            else:
                registers[rd] = (registers[rs1] - registers[rs2]) & bitmask()
        # SLL 
        elif func3 == 0b001:
            registers[rd] = registers[rs1] << (registers[rs2] & bitmask(5))
        # SLT (Set Less Than) & SLTU (Set Less Than Unsigned)
        elif func3 == 0b010 or func3 == 0b011:
            registers[rd] = 1 if registers[rs1] < registers[rs2] else 0
        # XOR (Exclusive OR)
        elif func3 == 0b100:
            registers[rd] = registers[rs1] ^ registers[rs2]
        # SRL (Shift Right Logical) & SRA (Shift Right Arithmetic)
        elif func3 == 0b101:
            registers[rd] = registers[rs1] >> (registers[rs2] & bitmask(5))
        # OR
        elif func3 == 0b110:
            registers[rd] = registers[rs1] | registers[rs2]
        # AND
        elif func3 == 0b111:
            registers[rd] = registers[rs1] & registers[rs2]
        else:
            raise ValueError

        registers[PC] += 4

    # SYSTEM
    elif opscode == 0b1110011:
        # ECALL
        if rd == 0b000 and func3 == 0b000:
            raise Exception("EnvironmentCall")
        # csrrw & csrrwi
        elif (func3 == 0b001) | (func3 == 0b101):
            if rd != 0:
                csr = registers[rs1]
                registers[rd] = csr
        # csrrs & csrrsi
        elif (func3 == 0b010) | (func3 == 0b110):
            csr = dins(ins, 31, 20) | registers[rs1]
            registers[rd] = csr
        # csrrc & csrrci
        elif (func3 == 0b011) | (func3 == 0b111):
            csr = dins(ins, 31, 20) & ~registers[rs1]
            registers[rd] = csr
        else:
            raise ValueError(
                f"func3 {bin(func3)} - {hex(func3)} - {func3} not processable for {OPCODE[opscode]}."
            )

        registers[PC] += 4

    # LUI
    elif opscode == 0b0110111:
        registers[rd] = sext(dins(ins, 31, 12), 20)
        registers[PC] += 4

    # BRANCH
    elif opscode == 0b1100011:
        offset = (
            (dins(ins, 31, 31) << 20) << 11
            | dins(ins, 7, 7) << 10
            | dins(ins, 30, 25) << 4
            | dins(ins, 11, 8)
        ) << 1

        func3 = dins(ins, 14, 12)
        rs1 = dins(ins, 19, 15)
        rs2 = dins(ins, 24, 20)

        # beq | bne | blt | bge | bltu | bgeu
        if (
            (func3 == 0b000 and registers[rs1] == registers[rs2])
            | (func3 == 0b001 and registers[rs1] != registers[rs2])
            | (func3 == 0b100 and registers[rs1] < registers[rs2])
            | (func3 == 0b101 and registers[rs1] >= registers[rs2])
            | (func3 == 0b110 and registers[rs1] < registers[rs2])
            | (func3 == 0b111 and registers[rs1] >= registers[rs2])
        ):
            registers[PC] += offset
        else:
            registers[PC] += 4
    else:
        raise NotImplemented

    return True


if __name__ == "__main__":
    # Keep some variables around.
    global memory, registers

    # 64k memory
    memory = b"\x00" * 0x10000
    # Instruction registers: 31 general purpose registers & 2 special-purpose
    # registers that each contain 32 bits in RV32 CPU,
    #
    # x0 will always be zero while x32 will hold the program counter.
    registers = [0] * 33

    for x in glob.glob("modules/riscv-tests/isa/rv32ui-v-add"):
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
