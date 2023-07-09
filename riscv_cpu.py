"""32-Bit Processor"""
import struct
import glob

from elf import elf_reader
from riscv import ABI, OPCODE


class Registers:
    def __init__(self):
        self.registers = [0] * 33

    def __getitem__(self, key):
        return self.registers[key]

    def __setitem__(self, key, value):
        if key == 0:
            return
        self.registers[key] = value & bm()


def set():
    """Initializes memory."""
    global registers, memory, PC
    # 64k memory
    memory = b"\x00" * 0x10000
    # Instruction registers: 31 general purpose registers & 2 special-purpose
    # registers that each contain 32 bits in RV32 CPU,
    #
    # x0 will always be zero while x32 will hold the program counter.
    registers = Registers()
    # Set PC to 32
    PC = 32


def registers_to_str(registers) -> str:
    """Returns formatted str of all registers."""
    s = ""
    for i, c in enumerate(registers):
        if i % 5 == 0 and i != 0:
            s += "\n"
        s += f"\t%3s : %08x " % (ABI[i], c)
    return s


def bm(bits: int = 32) -> int:
    """Returns a bitmask based for the number of bits given."""
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


def wmem(addr, data):
    """Write back to memory."""
    global memory
    addr -= 0x80000000
    assert addr >= 0 and addr < len(memory)
    memory = memory[:addr] + data + memory[addr + len(data) :]


def fetch32(addr):
    addr -= 0x80000000
    if addr < 0 or addr >= len(memory):
        raise Exception("read out of memory: 0x%x" % addr)
    return struct.unpack("I", memory[addr: addr + 4])[0]


def imm_j(ins: int) -> int:
    """J-type instruction format."""
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


def step():
    """Process instructions."""
    #
    # (1) Instruction Fetch
    #
    ins = fetch32(registers[PC])
    #
    # (2) Instruction Decode
    #
    # Bitwise ops to decode the instruction.
    opscode = dins(ins, 6, 0)
    # Compute register destination.
    rd = dins(ins, 11, 7)
    # Compute register sources.
    rs1 = dins(ins, 19, 15)
    rs2 = dins(ins, 24, 20)
    # Get instruction defining encodings.
    func3 = dins(ins, 14, 12)
    func7 = dins(ins, 31, 25)

    write_new_pc = opscode in [OPCODE["JAL"], OPCODE["JALR"], OPCODE["BRANCH"]]
    imm = {
        OPCODE["LUI"]: imm_u(ins),
        OPCODE["AUIPC"]: imm_u(ins),
        OPCODE["JAL"]: imm_j(ins),
        OPCODE["JALR"]: imm_i(ins),
        OPCODE["BRANCH"]: imm_b(ins),
        OPCODE["LOAD"]: imm_i(ins),
        OPCODE["STORE"]: imm_s(ins),
        OPCODE["ALU"]: imm_i(ins),
        OPCODE["OP"]: rs2,
        OPCODE["SYSTEM"]: imm_i(ins),
        OPCODE["FENCE"]: imm_i(ins),
    }[opscode]

    #
    # (3) Execution
    #
    if opscode == OPCODE["JAL"]:
        if rd != 0:
            registers[rd] = registers[PC] + 4
        registers[PC] += imm

    elif opscode == OPCODE["LUI"]:
        registers[rd] = imm

    elif opscode == OPCODE["AUIPC"]:
        registers[rd] = registers[PC] + imm

    elif opscode == OPCODE["JALR"]:
        wpc = (registers[rs1] + imm) & ~1
        registers[rd] = registers[PC] + 4
        registers[PC] = wpc

    elif opscode == OPCODE["ALU"]:
        # ADDI (Add Immediate)
        if func3 == 0b000:
            registers[rd] = registers[rs1] + imm
        # SLLI (Shift Left Logical Immediate)
        elif func3 == 0b001:
            registers[rd] = registers[rs1] << (imm & bm(5))
        # SLTI (Set Less Than Immediate)
        elif func3 == 0b010:
            registers[rd] = 1 if sext(registers[rs1], 32) < sext(imm, 32) else 0
        # SLTIU (Set Less Than Immediate Unsigned)
        elif func3 == 0b011:
            registers[rd] = 1 if (registers[rs1] & bm()) < (imm & bm()) else 0
        # XORI (Exclusive OR Immediate)
        elif func3 == 0b100:
            registers[rd] = registers[rs1] ^ imm
        # SRLI (Shift Right Logical Immediate) & SRAI (Shift Right Arithmetic Immediate)
        elif func3 == 0b101:
            if func7 == 0b0100000:
                sb = registers[rs1] >> 31
                if sb == 0:
                    registers[rd] = registers[rs1] >> (imm & bm(5))
                else:
                    shamt = imm & bm(5)
                    registers[rd] = (registers[rs1] >> shamt) ^ (
                        bm(shamt) << (32 - shamt)
                    )
            else:
                registers[rd] = registers[rs1] >> (imm & bm(5))
        # ORI (OR Immediate)
        elif func3 == 0b110:
            registers[rd] = registers[rs1] | imm
        # ANDI (AND Immediate)
        elif func3 == 0b111:
            registers[rd] = registers[rs1] & imm
        else:
            raise ValueError(f"ALU instruction failure.")

    elif opscode == OPCODE["OP"]:
        # ADD & SUB
        if func3 == 0b000:
            if func7 == 0b0:
                registers[rd] = (registers[rs1] + registers[rs2]) & bm()
            else:
                registers[rd] = (registers[rs1] - registers[rs2]) & bm()
        # SLL
        elif func3 == 0b001:
            registers[rd] = registers[rs1] << (registers[rs2] & bm(5))
        # SLT (Set Less Than)
        elif func3 == 0b010:
            registers[rd] = (
                1 if sext(registers[rs1], 32) < sext(registers[rs2], 32) else 0
            )
        # SLTU (Set Less Than Unsigned)
        elif func3 == 0b011:
            registers[rd] = (
                1 if (registers[rs1] & bm()) < (registers[rs2] & bm()) else 0
            )
        # XOR (Exclusive OR)
        elif func3 == 0b100:
            registers[rd] = registers[rs1] ^ registers[rs2]
        # SRA (Shift Right Arithmetic) & SRL (Shift Right Logical)
        elif func3 == 0b101:
            if func7 == 0b0100000:
                registers[rd] = sext(registers[rs1], 32) >> sext(
                    (registers[rs2] & bm(5)), 32
                )
            else:
                registers[rd] = registers[rs1] >> (registers[rs2] & bm(5))
        # OR
        elif func3 == 0b110:
            registers[rd] = registers[rs1] | registers[rs2]
        # AND
        elif func3 == 0b111:
            registers[rd] = registers[rs1] & registers[rs2]
        else:
            raise ValueError(f"OP instruction failure.")

    elif opscode == OPCODE["SYSTEM"]:
        csr = dins(ins, 31, 20)
        # ECALL
        if rd == 0b000 and func3 == 0b000:
            if registers[3] > 1:
                raise Exception(f"Failure in current test. gp {registers[3]}")
        # CSRRW & CSRRWI
        elif (func3 == 0b001) | (func3 == 0b101):
            if csr == 3072:
                print("  ecall", rd, rs1, csr, "success")
                return False
        # CSRRS & CSRRSI
        elif (func3 == 0b010) | (func3 == 0b110):
            registers[rd] = csr
        # CSRRC & CSRRCI
        elif (func3 == 0b011) | (func3 == 0b111):
            csr &= ~registers[rs1]
            registers[rd] = csr
        else:
            raise ValueError(f"SYSTEM instruction failure.")

    elif opscode == OPCODE["BRANCH"]:
        # beq | bne | blt | bge | bltu | bgeu
        if (
            (func3 == 0b000 and registers[rs1] == registers[rs2])
            | (func3 == 0b001 and registers[rs1] != registers[rs2])
            | (func3 == 0b100 and sext(registers[rs1], 32) < sext(registers[rs2], 32))
            | (func3 == 0b101 and sext(registers[rs1], 32) >= sext(registers[rs2], 32))
            | (func3 == 0b110 and registers[rs1] < registers[rs2])
            | (func3 == 0b111 and registers[rs1] >= registers[rs2])
        ):
            registers[PC] += imm
            if not imm:
                registers[PC] += 4
        else:
            registers[PC] += 4

    #
    # (4) Memory Access
    #
    elif opscode == OPCODE["STORE"]:
        # sb (Store Byte)
        if func3 == 0b000:
            wmem(
                registers[rs1] + imm,
                struct.pack("B", registers[rs2] & bm(8)),
            )
        # sh (Store Halfword)
        elif func3 == 0b001:
            wmem(
                registers[rs1] + imm,
                struct.pack("H", registers[rs2] & bm(16)),
            )
        # sw (Store Word)
        elif func3 == 0b010:
            wmem(registers[rs1] + imm, struct.pack("I", registers[rs2]))
        else:
            raise ValueError("STORE instruction failure.")

    elif opscode == OPCODE["LOAD"]:
        # lb (Load Byte)
        if func3 == 0b000:
            registers[rd] = sext(fetch32(registers[rs1] + imm) & bm(8), 8)
        # lh (Load Halfword)
        elif func3 == 0b001:
            registers[rd] = sext(fetch32(registers[rs1] + imm) & bm(16), 16)
        # lw (Load Word)
        elif func3 == 0b010:
            registers[rd] = fetch32(registers[rs1] + imm)
        # lbu (Load Byte Unsigned)
        elif func3 == 0b100:
            registers[rd] = fetch32(registers[rs1] + imm) & bm(8)
        # lhu (Load Halfword Unsigned)
        elif func3 == 0b101:
            registers[rd] = fetch32(registers[rs1] + imm) & bm(16)
        else:
            raise ValueError("LOAD instruction failure.")
    #
    # (5) Write Back
    #
    if not write_new_pc:
        registers[PC] += 4
    return True


if __name__ == "__main__":
    for x in glob.glob("modules/riscv-tests/isa/rv32ui-p-*"):
        if x.endswith(".dump"):
            continue
        print(f"Execute : {x}")
        # Reset memory and registers.
        set()
        # Reading the elf program header to memory.
        memory = elf_reader(memory, x)

        registers[PC] = 0x80000000
        inscnt = 0
        while step():
            inscnt += 1
        print("  ran %d instructions\n" % inscnt)
