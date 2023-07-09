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


class Program(Enum):
    DIRECTIVE = 1
    LABEL = 2
    INSTRUCTION = 3
    COMMENT = 4


def split_words(str_in: str, sl: list[str]) -> list[str]:
    """Reads in a string and splits it into words based on a list of symbols."""
    for w in sl:
        m = list(filter(None, re.split(f'({str(re.escape(w))})', str_in)))
        if len(m) > 1:
            return m
    return [str_in]


def parser(opdc: str):
    """Reads the assmbly code and returns list of tokenized symbols.

    :param opdc: The assembly code to be parsed in string format.
    :return: A list of tuples containing the type of the program and its symbols.
    """
    ts, pc = [], 0
    for line in opdc.split("\n"):
        sl = list(filter(None, re.split(r"\t+|,| |\(|\)|(\[)|(\]+)", line)))
        if sl:
            if re.match("\.+", sl[0]):
                ts.append((Program.DIRECTIVE, sl))
            elif re.match("\w+(?: \w+)*:", sl[0]):
                ts.append((Program.LABEL, sl, pc))
            elif re.match("\@+", sl[0]):
                ts.append((Program.COMMENT, sl))
            else:
                ts.append((Program.INSTRUCTION, sl, pc))
                pc += 4

    return ts


def asm32(tokens):
    """ARM 32 bit assembler.

    :param tokens: List of a tuple cotaining the type of the program and its symbols.
    :returns: A list of 32 bit machine code.
    :raises: RuntimeError if the instruction is not supported.
    """
    regs, conds = frozenset(REGISTERS.as_strs()), frozenset(CONDITION.as_strs())

    ins = []
    for t in tokens:
        print(t)
        if t[0] == Program.INSTRUCTION:
            inn = split_words(t[1].pop(0), conds)
            cond = CONDITION[inn[1].upper()].value if len(inn) > 1 else CONDITION.AL.value
            insb = inn + t[1]

            rs = [s for s in insb if s in regs]
            if insb[0] == OPCODE.ADD.value:
                rd = REGISTERS[str(rs[0])].value
                rn = 1 if rs[1] == "pc" else REGISTERS[str(rs[1])].value
                s_bit = 0
                imm = list(filter(None, [re.findall(r"#(-?\d+)", s) for s in insb]))[0][
                    0
                ]
                ins.append(
                    abs(int(imm))
                    + (rd << 12)
                    + (rn << 16)
                    + (s_bit << 20)
                    + (0b100 << 21)
                    + (0b0010 << 24)
                    + (cond << 28)
                )
            elif insb[0] == OPCODE.SUB.value:
                pass
            elif insb[0] == OPCODE.STR.value:
                # 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 ... 0
                # != 1111	   0  1	 0	P  U o2	 W o1 Rn          Rt          imm12
                #
                # STR{<c>}{<q>} <Rt>, [<Rn> {, #{+/-}<imm>}] immediate offset
                # STR{<c>}{<q>} <Rt>, [<Rn>, #{+/-}<imm>]! pre-indexed
                # STR{<c>}{<q>} <Rt>, [<Rn>], #{+/-}<imm> post-indexed
                #
                imm = list(filter(None, [re.findall(r"#(-?\d+)", s) for s in insb]))[0][
                    0
                ]
                u_bit = 0 if int(imm) < 0 else 1

                if "[" in insb and "]" in insb and "!" not in insb:
                    o2wo1, p_bit = 0, 1
                elif "[" in insb and "]" in insb and "!" in insb:
                    o2wo1, p_bit = 2, 1
                else:
                    o2wo1, p_bit = 2, 0
                ins.append(
                        abs(int(imm))
                        + (REGISTERS[str(rs[0])].value << 12)
                        + (REGISTERS[str(rs[1])].value << 16)
                        + (o2wo1 << 20)
                        + (u_bit << 23)
                        + (p_bit << 24)
                        + (0b010 << 25)
                        + (cond << 28)
                    )

            elif insb[0] == OPCODE.LDR.value:
                pass
            elif insb[0] == OPCODE.MOV.value:
                pass
            elif insb[0] == OPCODE.BX.value:
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
