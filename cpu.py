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
        if i % 5 == 0:
            s += "\n"
        if i < 10:
            s += f"x0{i} : {hex(c)} "
        else:
            s += f"x{i} : {hex(c)} "
    return s


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

    # JAL (Jump And Link)
    if opscode == 0b1101111:
        imm = decode_ins(ins, 31, 12)

        offset = (
            ((decode_ins(imm, 19, 19) << 12) - decode_ins(imm, 19, 19))
            | decode_ins(imm, 7, 0)
            | decode_ins(imm, 8, 8)
            | decode_ins(imm, 18, 9)
        ) << 1

        registers[rd] = registers[PC] + 4
        registers[PC] += offset

    # ALU
    elif opscode == 0b0010011:
        func3 = decode_ins(ins, 14, 12)
        rs1 = decode_ins(ins, 19, 15)

        # SLLI (Shift Left Logical Immediate)
        if func3 == 0b001:
            assert decode_ins(ins, 31, 25) == 0
            registers[rd] = registers[rs1] << decode_ins(ins, 24, 20)
        # SRLI (Shift Right Logical Immediate)
        elif func3 == 0b101:
            assert decode_ins(ins, 31, 25) == 0
            registers[rd] = registers[rs1] >> decode_ins(ins, 24, 20)
        # SRAI (Shift Right Arithmetic Immediate)
        elif func3 == 0b101:
            assert decode_ins(ins, 31, 25) == 0b010000
            registers[rd] = registers[rs1] >> decode_ins(ins, 24, 20)
        else:
            imm = decode_ins(ins, 31, 20)

            offset = (
                (decode_ins(imm, 11, 11) << 21) - decode_ins(imm, 11, 11)
            ) | decode_ins(imm, 10, 0)

            # ADDI (Add Immediate)
            if func3 == 0b000:
                registers[rd] = registers[rs1] + offset
            # SLTI (Set Less Than Immediate) & SLTIU (Set Less Than Immediate Unsigned)
            elif func3 == 0b010 or func3 == 0b011:
                if registers[rs1] < offset:
                    registers[rd] = 1
                else:
                    registers[rd] = 0
            # XORI (Exclusive OR Immediate)
            elif func3 == 0b100:
                registers[rd] = registers[rs1] ^ offset
            # ORI (OR Immediate)
            elif func3 == 0b110:
                registers[rd] = registers[rs1] | offset
            # ANDI (AND Immediate)
            elif func3 == 0b111:
                registers[rd] = registers[rs1] & offset
            else:
                raise ValueError(
                    f"func3 {hex(func3)} not processable for {OPCODE[opscode]}."
                )

        registers[PC] += 4

    # AUIPC
    elif opscode == 0b0010111:
        imm = decode_ins(ins, 31, 12)

        offset = imm << 12

        registers[rd] = offset
        registers[PC] += 4

    # OP
    elif opscode == 0b0110011:
        func3 = decode_ins(ins, 14, 12)
        rs1 = decode_ins(ins, 19, 15)
        rs2 = decode_ins(ins, 24, 20)
        func7 = decode_ins(ins, 31, 25)

        # ADD & SUB
        if func3 == 0b0:
            if func7 == 0b0:
                registers[rd] = registers[rs1] + registers[rs2]
            else:
                registers[rd] = registers[rs1] - registers[rs2]
        elif func3 == 0b001:
            pass
        # SLT (Set Less Than) & SLTU (Set Less Than Unsigned)
        elif func3 == 0b010 or func3 == 0b011:
            if registers[rs1] < registers[rs2]:
                registers[rd] = 1
            else:
                registers[rd] = 2
        # XOR (Exclusive OR)
        elif func3 == 0b100:
            registers[rd] = registers[rs1] ^ registers[rs2]
        # SRL (Shift Right Logical) & SRA (Shift Right Arithmetic)
        elif func3 == 0b101:
            pass
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
        func3 = decode_ins(ins, 14, 12)
        rs1 = decode_ins(ins, 19, 15)

        if func3 == 0b000:
            print("ECALL")

        # CSRRW
        elif func3 == 0b001:
            if not rd == 0:
                csr = registers[rs1]
                registers[rd] = csr
        # CSRRS
        elif func3 == 0b010:
            csr = decode_ins(ins, 31, 20)
        # CSRRC
        elif func3 == 0b011:
            csr = decode_ins(ins, 31, 20)
        elif func3 == 0b101:
            pass
        elif func3 == 0b110:
            pass
        elif func3 == 0b111:
            pass
        else:
            raise ValueError(
                f"func3 {hex(func3)} not processable for {OPCODE[opscode]}."
            )

        registers[PC] += 4

    return True


def step():
    # Instruction Fetch
    ins = fetch32(registers[PC])

    # Instruction Decode
    print(registers_to_str(registers))
    # Execute

    # Memory Access

    # Writeback

    return decode32(ins)


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
