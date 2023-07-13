"""ARM Assembler"""
import re
import sys
from enum import Enum


class REGISTERS(Enum):
    r0 = 0
    r1 = 1
    r2 = 2
    r3 = 3
    r4 = 4
    r5 = 5
    r6 = 6
    r7 = 7
    r8 = 8
    r9 = 9
    r10 = 10
    fp = 11
    r12 = 12
    sp = 13
    lr = 14
    pc = 15

    @classmethod
    def as_strs(cls):
        return list(map(lambda c: c.name, cls))


class CONDITION(Enum):
    EQ = 0b0000  # Equal
    NE = 0b0001  # Not equal
    CS = 0b0010  # Carry set (identical to HS)
    HS = 0b0010  # Unsigned higher or same (identical to CS)
    CC = 0b0011  # Carry clear (identical to LO)
    LO = 0b0011  # Unsigned lower (identical to CC)
    MI = 0b0100  # Minus or negative result
    PL = 0b0101  # Positive or zero result
    VS = 0b0110  # Overflow
    VC = 0b0111  # No overflow
    HI = 0b1000  # Unsigned higher
    LS = 0b1001  # Unsigned lower or same
    GE = 0b1010  # Signed greater than or equal
    LT = 0b1011  # Signed less than
    GT = 0b1100  # Signed greater than
    LE = 0b1101  # Signed less than or equal
    AL = 0b1110  # Always (this is the default)

    @classmethod
    def as_strs(cls):
        return list(map(lambda c: c.name.lower(), cls))


class OPCODE(Enum):
    """ARM 32 bit opcodes."""

    # ALU
    ADD = "add"  # Addition
    SUB = "sub"  # Subtraction
    MUL = "mul"  # Multiplication
    # Load & Store
    STR = "str"  # Store
    STM = "stm"  # Store Multiple
    LDR = "ldr"  # Load
    LDM = "ldm"  # Load Multiple
    MOV = "mov"  # Move data
    MVN = "mvn"  # Move data and negate
    POP = "pop"  # Pop off Stack
    PUSH = "push"  # Push on Stack
    # Branching
    B = "b"  # Branch
    BL = "bl"  # Branch with Link
    BX = "bx"  # Branch and eXchange
    CMP = "cmp"  # Compare
    # Extra
    EOR = "eor"  # Bitwise XOR
    LSL = "lsl"  # Logical Shift Left
    LSR = "lsr"  # Logical Shift Right
    ASR = "asr"  # Arithmetic Shift Right
    ROR = "ror"  # Rotate Right
    AND = "and"  # Bitwise AND
    ORR = "orr"  # Bitwise OR
    SWI = "swi"  # System Call
    SVC = "svc"  # System Call


class Program(Enum):
    DIRECTIVE = 1
    LABEL = 2
    INSTRUCTION = 3
    COMMENT = 4


def bm(b: int = 32):
    """Performs sign extension by number of bits given."""
    return 2**b - 1


def sext(val: int, bits: int = 32):
    """Performs sign extension by number of bits given."""
    if val < 0:
        return (2**bits - 1) & val
    else:
        return val


def dump_to_hex(ins: list[int], fn: str) -> None:
    """Writes the output to hex file."""
    with open(f"{fn}", "w") as fp:
        for i in ins:
            fp.write("%08x\n" % i)


def split_words(str_in: str, sl: list[str]) -> list[str]:
    """Reads in a string and splits it into words based on a list of symbols."""
    for w in sl:
        m = list(filter(None, re.split(f"({str(re.escape(w))})", str_in)))
        if len(m) > 1:
            return m
    return [str_in]


def check_const(insb: list[str]) -> bool:
    """Checks if the instruction contains a #<const>."""
    return list(filter(lambda x: x.startswith("#"), insb))


def check_label(insb: list[str]) -> bool:
    """Checks if the instruction contains a <label>."""
    return list(filter(lambda x: x.startswith("."), insb))


def check_pc(insb: list[str]) -> bool:
    """Checks if the instruction contains a <label>."""
    return list(filter(lambda x: x == "pc", insb))


def parser(opdc: str):
    """Reads the assmebly code and returns list of tokenized symbols.

    :param opdc: The assembly code to be parsed in string format.
    :return: A list of tuples containing the type of the program and its symbols.
    """
    ts, pc = [], 0
    for line in opdc.split("\n"):
        sl = list(filter(None, re.split(r"\t+|,| |\(|\)|(\[)|(\]+)|(\{)|(\}+)", line)))
        if sl:
            if re.match("\.(\w+):", sl[0]):
                ts.append((Program.LABEL, sl, pc))
            elif re.match("\.+", sl[0]):
                ts.append((Program.DIRECTIVE, sl))
            elif re.match("\w+(?: \w+)*:", sl[0]):
                ts.append((Program.LABEL, sl, pc))
            elif re.match("\@+", sl[0]):
                ts.append((Program.COMMENT, sl))
            elif re.match("\//+", sl[0]):
                ts.append((Program.COMMENT, sl))
            else:
                ts.append((Program.INSTRUCTION, sl, pc))
                pc += 1
    return ts


def asm32(tokens) -> list[int]:
    """ARM 32 bit assembler.

    :param tokens: List of a tuple holding the type of the program and its symbols.
    :returns: A list of 32 bit machine code.
    :raises: RuntimeError if the instruction is not supported.
    """
    regs, conds = frozenset(REGISTERS.as_strs()), frozenset(CONDITION.as_strs())
    labels = list(filter(lambda c: c[0] == Program.LABEL, tokens))

    ins = []
    for idx, t in enumerate(tokens):
        print(t)
        if t[0] == Program.INSTRUCTION:
            inn = split_words(t[1].pop(0), conds)
            cond = (
                CONDITION[inn[1].upper()].value if len(inn) > 1 else CONDITION.AL.value
            )
            insb = t[1]
            if wf := any(filter(lambda x: x in ["[", "]"], insb)):
                if insb.index(']') - insb.index('[') <= 2:
                    wf = False
                insb = list(filter(lambda x: x not in ["[", "]"], insb))
            if bbwf := any(filter(lambda x: x in ["{", "}"], insb)):
                insb = list(filter(lambda x: x not in ["{", "}"], insb))
            if ef := any(filter(lambda x: x[-1] == "!", insb)):
                insb = list(filter(lambda x: x not in ["[", "]", "{", "}"], insb))
            if rs := [s for s in insb if s in regs]:
                insb = list(filter(lambda x: x not in rs, insb))
            if len(insb) > 0:
                if const := list(
                    filter(None, [re.findall(r"#(-?\d+)", s) for s in insb])
                ):
                    insb = list(filter(lambda x: not x.startswith("#"), insb))
                    const = const[0][0]

                # TODO: Distinguish between <shift> and <label>
                label = insb[0] if len(insb) else None

            if inn[0] == OPCODE.ADD.value:
                rn = 0xF if rs[1] == "pc" else REGISTERS[rs[1]].value
                if len(rs) == 2:
                    s_bit, op = 0, 2
                    imm = abs(int(const))
                elif len(rs) == 3:
                    s_bit, op = 0, 0
                    imm = REGISTERS[rs[2]].value
                elif len(rs) == 4:
                    pass
                else:
                    raise RuntimeError(f"Invalid number of registers in {t[0][0]}.")
                ins.append(
                    imm
                    + (REGISTERS[rs[0]].value << 12)
                    + (rn << 16)
                    + (s_bit << 20)
                    + (0b100 << 21)
                    + (op << 24)
                    + (cond << 28)
                )
            elif inn[0] == OPCODE.SUB.value:
                rn = 0xF if rs[1] == "pc" else REGISTERS[rs[1]].value
                if len(rs) == 2:
                    s_bit, op = 0, 2
                    imm12 = abs(int(const))
                elif len(rs) == 3:
                    s_bit, op = 0, 0
                    imm12 = REGISTERS[rs[2]].value
                elif len(rs) == 4:
                    pass
                else:
                    raise RuntimeError(f"Invalid number of registers in {t[0][0]}.")
                ins.append(
                    imm12
                    + (REGISTERS[rs[0]].value << 12)
                    + (rn << 16)
                    + (s_bit << 20)
                    + (0b010 << 21)
                    + (op << 24)
                    + (cond << 28)
                )
            elif inn[0] == OPCODE.STR.value:
                if len(rs) == 2:
                    u_bit = 0 if int(const) < 0 else 1
                    if not wf:
                        o2wo1, p_bit = 2, 0
                    elif wf and ef:
                        o2wo1, p_bit = 2, 1
                    else:
                        o2wo1, p_bit = 0, 1
                    ins.append(
                        abs(int(const))
                        + (REGISTERS[rs[0]].value << 12)
                        + (REGISTERS[rs[1]].value << 16)
                        + (o2wo1 << 20)
                        + (u_bit << 23)
                        + (p_bit << 24)
                        + (0b010 << 25)
                        + (cond << 28)
                    )
                elif len(rs) == 3:
                    pass
                else:
                    raise RuntimeError(f"Invalid number of registers in {t[0][0]}.")

            elif inn[0] == OPCODE.LDR.value:
                if len(rs) == 1:
                    tl = next(x for x in labels if label == x[1][0].replace(":", ""))
                    imm = sext(tl[2] - t[2] - 2, 24)
                    rn = 0xF
                elif len(rs) == 2:
                    u_bit = 0 if int(const) < 0 else 1
                    rn = REGISTERS[rs[1]].value
                    imm = abs(int(const))
                    print(wf, ef)
                    if not wf:
                        o2wo1, p_bit = 1, 0
                    elif wf and ef:
                        o2wo1, p_bit = 3, 1
                    else:
                        o2wo1, p_bit = 1, 1
                elif len(rs) == 3:
                    pass
                else:
                    raise RuntimeError(f"Invalid number of registers in {t[0][0]}.")
                ins.append(
                    imm
                    + (REGISTERS[rs[0]].value << 12)
                    + (rn << 16)
                    + (o2wo1 << 20)
                    + (u_bit << 23)
                    + (p_bit << 24)
                    + (0b010 << 25)
                    + (cond << 28)
                )
            elif inn[0] == OPCODE.MOV.value:
                s_bit = 0
                if len(rs) == 1:
                    imm = abs(int(const))
                    op = 7
                elif len(rs) == 2:
                    op = 3
                    imm = REGISTERS[rs[1]].value
                elif len(rs) == 3:
                    pass
                else:
                    raise RuntimeError(f"Invalid number of registers in {t[0][0]}.")
                ins.append(
                    imm
                    + (REGISTERS[rs[0]].value << 12)
                    + (0 << 16)
                    + (s_bit << 20)
                    + (1 << 21)
                    + (op << 23)
                    + (cond << 28)
                )
                print(hex(ins[-1]))
            elif inn[0] == OPCODE.PUSH.value:
                registers_list = 0
                for i in reversed(REGISTERS.as_strs()):
                    if i in rs:
                        registers_list += 1 << REGISTERS[i].value
                ins.append(registers_list + (0x92D << 16) + (cond << 28))
            elif inn[0] == OPCODE.POP.value:
                registers_list = 0
                for i in reversed(REGISTERS.as_strs()):
                    if i in rs:
                        registers_list += 1 << REGISTERS[i].value
                ins.append(registers_list + (0x8BD << 16) + (cond << 28))
            elif inn[0] == OPCODE.CMP.value:
                if len(rs) == 1:
                    imm = abs(int(const))
                    op = 0x35
                elif len(rs) == 2:
                    op = 0x15
                elif len(rs) == 3:
                    op = 0x15
                else:
                    raise RuntimeError(f"Invalid number of registers in {t[0][0]}.")
                ins.append(
                    imm
                    + (0 << 12)
                    + (REGISTERS[rs[0]].value << 16)
                    + (op << 20)
                    + (cond << 28)
                )
            elif inn[0] == OPCODE.B.value:
                if label := check_label(insb):
                    tl = next(x for x in labels if label[0] == x[1][0].replace(":", ""))
                    off = sext(tl[2] - t[2] - 2, 24)
                else:
                    off = 0xFFFFFE
                ins.append(off + (0xA << 24) + (cond << 28))
            elif inn[0] == OPCODE.BL.value:
                if label := check_label(insb):
                    tl = next(x for x in labels if label[0] == x[1][0].replace(":", ""))
                    off = sext(tl[2] - t[2] - 2, 24)
                else:
                    off = 0xFFFFFE
                ins.append(off + (0xB << 24) + (cond << 28))
            elif inn[0] == OPCODE.BX.value:
                ins.append(
                    REGISTERS[rs[0]].value
                    + (1 << 4)
                    + (bm(1) << 8)
                    + (18 << 20)
                    + (cond << 28)
                )
            #             elif inn[0] == OPCODE.MUL.value:
            #                 pass
            #             elif inn[0] == OPCODE.STM.value:
            #                 pass
            #             elif inn[0] == OPCODE.LDM.value:
            #                 pass
            #             elif inn[0] == OPCODE.MVN.value:
            #                 pass
            #             elif inn[0] == OPCODE.EOR.value:
            #                 pass
            #             elif inn[0] == OPCODE.LSL.value:
            #                 pass
            #             elif inn[0] == OPCODE.LSR.value:
            #                 pass
            #             elif inn[0] == OPCODE.ASR.value:
            #                 pass
            #             elif inn[0] == OPCODE.AND.value:
            #                 pass
            #             elif inn[0] == OPCODE.ORR.value:
            #                 pass
            #             elif inn[0] == OPCODE.SWI.value:
            #                 pass
            #             elif inn[0] == OPCODE.SWC.value:
            #                 pass
            else:
                raise RuntimeError(f"OPCODE '{inn[0]}' not supported.")

    [print("{0:b}".format(i)) for i in ins]
    return ins


if __name__ == "__main__":
    try:
        x = sys.argv[1]
    except ValueError:
        raise ValueError("No input file provided.")

    print(f"Read : {x}\n")
    with open(x, "r") as f:
        ts = parser(f.read())
        ins = asm32(ts)

        [print(f"{idx + 1} %08x " % i) for (idx, i) in enumerate(ins)]
