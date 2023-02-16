"""32-Bit Processor"""
import struct
import glob

from elf import elf_reader
from riscv import ABI, OPCODE

# Programm Counter
PC = 32


class Registers:
    def __init__(self):
        self.registers = [0] * 33

    def __getitem__(self, key):
        return self.registers[key]

    def __setitem__(self, key, value):
        if key == 0:
            return
        self.registers[key] = value & bitmask()


def set():
    """Initializes memory."""
    global registers, memory
    # 64k memory
    memory = b"\x00" * 0x10000
    # Instruction registers: 31 general purpose registers & 2 special-purpose
    # registers that each contain 32 bits in RV32 CPU,
    #
    # x0 will always be zero while x32 will hold the program counter.
    registers = Registers()


def registers_to_str(registers) -> str:
    """Returns formatted str of all registers."""
    s = ""
    for i, c in enumerate(registers):
        if i % 5 == 0 and i != 0:
            s += "\n"
        s += f"\t%3s : %08x " % (ABI[i], c)
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
    return (ins >> s) & ((1 << (e - s + 1)) - 1)


def sext(val: int, bits: int):
    """Performs sign extension by number of bits given."""
    if val >> (bits - 1) == 1:
        return -((1 << bits) - val)
    else:
        return val


def fetch32(addr):
    addr -= 0x80000000
    if addr < 0 or addr >= len(memory):
        raise Exception("read out of memory: 0x%x" % addr)
    return struct.unpack("I", memory[addr : addr + 4])[0]


def mem32(addr, dat):
    global memory
    addr -= 0x80000000
    assert addr >= 0 and addr < len(memory)
    memory = memory[:addr] + dat + memory[addr + len(dat) :]


def imm_j(ins: int) -> int:
    """J-type instruction format."""
    # return sext(
    #     (
    #         (dins(ins, 31, 31) << 12)
    #         | (dins(ins, 19, 12) << 11)
    #         | (dins(ins, 20, 20) << 10)
    #         | dins(ins, 31, 21)
    #     )
    #     << 1,
    #     21,
    # )
    return sext(
        (dins(ins, 32, 31) << 20)
        | (dins(ins, 30, 21) << 1)
        | (dins(ins, 21, 20) << 11)
        | (dins(ins, 19, 12) << 12),
        21,
    )


def imm_u(ins: int) -> int:
    """U-type instruction format."""
    return sext(dins(ins, 31, 12) << 12, 32)


def imm_i(ins: int) -> int:
    """I-type instruction format."""
    return sext(dins(ins, 31, 20), 12)


def imm_s(ins: int) -> int:
    """S-type instruction format."""
    return sext(((dins(ins, 31, 25) << 5) | dins(ins, 11, 7)), 12)


def imm_b(ins: int) -> int:
    """B-type instruction format."""
    return sext(
        (
            (dins(ins, 31, 31) << 10)
            | (dins(ins, 7, 7) << 9)
            | (dins(ins, 30, 25) << 4)
            | dins(ins, 11, 8)
        )
        << 1,
        12,
    )
    # return sext((dins(ins, 32, 31)<<12) | (dins(ins, 30, 25)<<5) | (dins(ins, 11, 8)<<1) | (dins(ins, 8, 7)<<11), 13)


def step():
    """Process instructions."""
    # (1) Instruction Fetch
    ins = fetch32(registers[PC])

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
    func7 = dins(ins, 31, 25)

    # JAL (Jump And Link)
    if opscode == 0b1101111:
        if rd != 0:
            registers[rd] = registers[PC] + 4
        registers[PC] += imm_j(ins)
    # LUI
    elif opscode == 0b0110111:
        registers[rd] = imm_u(ins)
        registers[PC] += 4

    # AUIPC
    elif opscode == 0b0010111:
        registers[rd] = registers[PC] + imm_u(ins)
        registers[PC] += 4

    # JALR (Jump And Link Register)
    elif opscode == 0b1100111:
        wpc = (registers[rs1] + imm_i(ins)) & ~1

        registers[rd] = registers[PC] + 4
        registers[PC] = wpc
    # ALU
    elif opscode == 0b0010011:
        # ADDI (Add Immediate)
        if func3 == 0b000:
            registers[rd] = registers[rs1] + imm_i(ins)
        # SLLI (Shift Left Logical Immediate)
        elif func3 == 0b001:
            registers[rd] = registers[rs1] << (imm_i(ins) & bitmask(5))
        # SLTI (Set Less Than Immediate)
        elif func3 == 0b010:
            registers[rd] = 1 if sext(registers[rs1], 32) < sext(imm_i(ins), 32) else 0
        # SLTIU (Set Less Than Immediate Unsigned)
        elif func3 == 0b011:
            registers[rd] = (
                1 if (registers[rs1] & bitmask()) < (imm_i(ins) & bitmask()) else 0
            )
        # XORI (Exclusive OR Immediate)
        elif func3 == 0b100:
            registers[rd] = registers[rs1] ^ imm_i(ins)
        # SRLI (Shift Right Logical Immediate) & SRAI (Shift Right Arithmetic Immediate)
        elif func3 == 0b101:
            if func7 == 0b0100000:
                sb = registers[rs1] >> 31
                if sb == 0:
                    registers[rd] = registers[rs1] >> (imm_i(ins) & bitmask(5))
                else:
                    shamt = imm_i(ins) & bitmask(5)
                    registers[rd] = (registers[rs1] >> shamt) ^ (
                        bitmask(shamt) << (32 - shamt)
                    )
            else:
                registers[rd] = registers[rs1] >> (imm_i(ins) & bitmask(5))
        # ORI (OR Immediate)
        elif func3 == 0b110:
            registers[rd] = registers[rs1] | imm_i(ins)
        # ANDI (AND Immediate)
        elif func3 == 0b111:
            registers[rd] = registers[rs1] & imm_i(ins)
        else:
            raise ValueError(
                f"func3 {hex(func3)} not processable for {OPCODE[opscode]}."
            )

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
        # SLT (Set Less Than)
        elif func3 == 0b010:
            registers[rd] = (
                1 if sext(registers[rs1], 32) < sext(registers[rs2], 32) else 0
            )
        # SLTU (Set Less Than Unsigned)
        elif func3 == 0b011:
            registers[rd] = (
                1 if (registers[rs1] & bitmask()) < (registers[rs2] & bitmask()) else 0
            )
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
        csr = dins(ins, 31, 20)
        # ECALL
        if rd == 0b000 and func3 == 0b000:
            if registers[3] > 1:
                raise Exception("failure with current test.")
        # CSRRW & CSRRWI
        elif (func3 == 0b001) | (func3 == 0b101):
            if csr == 3072:
                print("CSRRW", rd, rs1, csr, "success")
                return False
        # CSRRS & CSRRSI
        elif (func3 == 0b010) | (func3 == 0b110):
            registers[rd] = csr
        # CSRRC & CSRRCI
        elif (func3 == 0b011) | (func3 == 0b111):
            csr = dins(ins, 31, 20) & ~registers[rs1]
            registers[rd] = csr
        else:
            raise ValueError(
                f"func3 {bin(func3)} not processable for {OPCODE[opscode]}."
            )

        registers[PC] += 4

    # BRANCH
    elif opscode == 0b1100011:
        # beq | bne | blt | bge | bltu | bgeu
        if (
            (func3 == 0b000 and registers[rs1] == registers[rs2])
            | (func3 == 0b001 and registers[rs1] != registers[rs2])
            | (func3 == 0b100 and sext(registers[rs1], 32) < sext(registers[rs2], 32))
            | (func3 == 0b101 and sext(registers[rs1], 32) >= sext(registers[rs2], 32))
            | (func3 == 0b110 and registers[rs1] < registers[rs2])
            | (func3 == 0b111 and registers[rs1] >= registers[rs2])
        ):
            registers[PC] += imm_b(ins)
            if not imm_b(ins):
                registers[PC] += 4
        else:
            registers[PC] += 4

    # STORE
    elif opscode == 0b0100011:
        # sb (Store Byte)
        if func3 == 0b000:
            mem32(
                registers[rs1] + imm_s(ins),
                struct.pack("B", registers[rs2] & bitmask(8)),
            )
        # sh (Store Halfword)
        elif func3 == 0b001:
            mem32(
                registers[rs1] + imm_s(ins),
                struct.pack("H", registers[rs2] & bitmask(16)),
            )
        # sw (Store Word)
        elif func3 == 0b010:
            mem32(registers[rs1] + imm_s(ins), struct.pack("I", registers[rs2]))
        else:
            raise ValueError(f"func3 not processable for {OPCODE[opscode]}.")
        registers[PC] += 4

    # LOAD
    elif opscode == 0b0000011:
        # lb (Load Byte)
        if func3 == 0b000:
            registers[rd] = sext(fetch32(registers[rs1] + imm_i(ins)) & bitmask(8), 8)
        # lh (Load Halfword)
        elif func3 == 0b001:
            registers[rd] = sext(fetch32(registers[rs1] + imm_i(ins)) & bitmask(16), 16)
        # lw (Load Word)
        elif func3 == 0b010:
            registers[rd] = fetch32(registers[rs1] + imm_i(ins))
        # lbu (Load Byte Unsigned)
        elif func3 == 0b100:
            registers[rd] = fetch32(registers[rs1] + imm_i(ins)) & bitmask(8)
        # lhu (Load Halfword Unsigned)
        elif func3 == 0b101:
            registers[rd] = fetch32(registers[rs1] + imm_i(ins)) & bitmask(16)
        else:
            raise ValueError(f"func3 not processable for {OPCODE[opscode]}.")
        registers[PC] += 4

    # FENCE
    elif opscode == 0b0001111:
        registers[PC] += 4
    # A
    elif opscode == 0b0101111:
        registers[PC] += 4
    else:
        raise ValueError(f"{OPCODE[opscode]}")

    return True


if __name__ == "__main__":
    for x in glob.glob("modules/riscv-tests/isa/rv32ui-p-fence_i"):
        if x.endswith(".dump"):
            continue
        print(f"Execute : {x}\n")
        # Reset memory and registers.
        set()
        # Reading the elf program header to memory.
        memory = elf_reader(memory, x)

        registers[PC] = 0x80000000
        while step():
            pass
