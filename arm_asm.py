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
    ADD = "add"
    STR = "str"
    SUB = "sub"
    LDR = "ldr"
    MOV = "mov"
    BX = "bx"
    PUSH = "push"
    CMP = "cmp"
    B = "b"
    BL = "bl"
    POP = "pop"


class Program(Enum):
    DIRECTIVE = 1
    LABEL = 2
    INSTRUCTION = 3
    COMMENT = 4


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


def get_imm12(insb: list[str], rs: list[str], rsl: int) -> int:
    """Returns the 12 bit immediate value.

    :param insb: The instruction body: List of strings defining the instruction.
    :param rs: List of strings defining the registers.
    :param rsl: The excpected number of registers in that particular instruction.
    :return: The 12 bit immediate value as integer.
    """
    return (
        REGISTERS[rs[rsl - 1]].value
        if len(rs) == rsl
        else list(filter(None, [re.findall(r"#(-?\d+)", s) for s in insb]))[0][0]
    )


def parser(opdc: str):
    """Reads the assmbly code and returns list of tokenized symbols.

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
        if t[0] == Program.INSTRUCTION:
            inn = split_words(t[1].pop(0), conds)
            cond = (
                CONDITION[inn[1].upper()].value if len(inn) > 1 else CONDITION.AL.value
            )
            insb = inn + t[1]

            rs = [s for s in insb if s in regs]
            if insb[0] == OPCODE.ADD.value:
                rd = REGISTERS[rs[0]].value
                rn = 1 if rs[1] == "pc" else REGISTERS[rs[1]].value
                s_bit = 0
                op = 0 if len(rs) == 3 else 0b0010
                imm = get_imm12(insb, rs, 3)
                ins.append(
                    abs(int(imm))
                    + (rd << 12)
                    + (rn << 16)
                    + (s_bit << 20)
                    + (0b100 << 21)
                    + (op << 24)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.SUB.value:
                rd = REGISTERS[rs[0]].value
                rn = 1 if rs[1] == "pc" else REGISTERS[rs[1]].value
                s_bit = 0
                op = 0 if len(rs) == 3 else 0b0010
                imm = get_imm12(insb, rs, 3)
                ins.append(
                    abs(int(imm))
                    + (rd << 12)
                    + (rn << 16)
                    + (s_bit << 20)
                    + (0b010 << 21)
                    + (op << 24)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.STR.value:
                imm = get_imm12(insb, rs, 3)
                u_bit = 0 if int(imm) < 0 else 1
                if "[" in insb and "]" in insb and "!" not in insb:
                    o2wo1, p_bit = 0, 1
                elif "[" in insb and "]" in insb and "!" in insb:
                    o2wo1, p_bit = 2, 1
                else:
                    o2wo1, p_bit = 2, 0
                ins.append(
                    abs(int(imm))
                    + (REGISTERS[rs[0]].value << 12)
                    + (REGISTERS[rs[1]].value << 16)
                    + (o2wo1 << 20)
                    + (u_bit << 23)
                    + (p_bit << 24)
                    + (0b010 << 25)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.LDR.value:
                imm = get_imm12(insb, rs, 3)
                u_bit = 0 if int(imm) < 0 else 1
                if insb[-1] == "!":
                    o2wo1, p_bit = 0b011, 1
                else:
                    o2wo1, p_bit = 0b001, 0
                    if insb[-1] == "]":
                        o2wo1, p_bit = 0b001, 1
                ins.append(
                    abs(int(imm))
                    + (REGISTERS[rs[0]].value << 12)
                    + (REGISTERS[rs[1]].value << 16)
                    + (o2wo1 << 20)
                    + (u_bit << 23)
                    + (p_bit << 24)
                    + (0b010 << 25)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.MOV.value:
                s_bit = 0
                imm = get_imm12(insb, rs, 2)
                op = 0b00111 if len(rs) == 1 else 0b00011
                ins.append(
                    abs(int(imm))
                    + (REGISTERS[rs[0]].value << 12)
                    + (0 << 16)
                    + (s_bit << 20)
                    + (0b01 << 21)
                    + (op << 23)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.BX.value:
                ins.append(
                    REGISTERS[rs[0]].value
                    + (0b0001 << 4)
                    + (0b111111111111 << 8)
                    + (0b00010010 << 20)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.PUSH.value:
                registers_list = 0
                for i in reversed(REGISTERS.as_strs()):
                    if i in rs:
                        registers_list += 1 << REGISTERS[i].value
                ins.append(registers_list + (0b100100101101 << 16) + (cond << 28))
            elif insb[0] == OPCODE.CMP.value:
                imm = get_imm12(insb, rs, 2)
                ins.append(
                    abs(int(imm))
                    + (0 << 12)
                    + (REGISTERS[rs[0]].value << 16)
                    + (0b00110101 << 20)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.B.value:
                label = list(filter(lambda x: x.startswith("."), insb))[0]
                tl = next(x for x in labels if label == x[1][0].replace(":", ""))
                offset = tl[2] - t[2] - 2
                ins.append(offset + (0b1010 << 24) + (cond << 28))
            elif insb[0] == OPCODE.BL.value:
                pass
            elif insb[0] == OPCODE.POP.value:
                pass
            else:
                raise RuntimeError(f"OPCODE '{insb[0]}' not supported.")

    # [print("{0:b}".format(i)) for i in ins]
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

        [print("%08x " % i) for i in ins]
