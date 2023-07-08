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
    fd = 11
    r12 = 12
    sp = 13
    lr = 14
    pc = 15


class CONDITION(Enum):
    "eq"  # Equal
    "ne"  # Not equal
    "cs"  # Carry set (identical to HS)
    "hs"  # Unsigned higher or same (identical to CS)
    "cc"  # Carry clear (identical to LO)
    "lo"  # Unsigned lower (identical to CC)
    "mi"  # Minus or negative result
    "pl"  # Positive or zero result
    "vs"  # Overflow
    "vc"  # No overflow
    "hi"  # Unsigned higher
    "ls"  # Unsigned lower or same
    "ge"  # Signed greater than or equal
    "lt"  # Signed less than
    "gt"  # Signed greater than
    "le"  # Signed less than or equal
    "al"  # Always (this is the default)


class OPCODE(Enum):
    ADD = "add"
    STR = "str"
    SUB = "sub"


class Program(Enum):
    DIRECTIVE = 1
    LABEL = 2
    INSTRUCTION = 3
    COMMENT = 4


def parser(opdc: str):
    """Reads the assmbly code and returns list of tokenized symbols.

    :param opdc: The assembly code to be parsed in string format.
    :return: A list of tuples containing the type of the program and its symbols.
    """
    ts, pc = [], 0
    for line in opdc.split("\n"):
        sl = list(filter(None, re.split(r"\t+|,| |\(|\)", line)))
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
    """ARM 32 bit assambler.

    :param tokens: List of a tuple cotaining the type of the program and its symbols.
    :returns: A list of 32 bit machine code.
    """
    for t in tokens:
        if t[0] == Program.INSTRUCTION:
            if t[1][0] == OPCODE.ADD.value:
                pass
            elif t[1][0] == OPCODE.SUB.value:
                pass
            elif t[1][0] == OPCODE.STR.value:
                # STR{type}{cond} Rt, [Rn {, #offset}]
                print(t[1])
                if len(t[1]) == 3:
                    pass
            else:
                raise RuntimeError(f"OPCODE {t[1][0]} not supported.")


if __name__ == "__main__":
    try:
        x = sys.argv[1]
    except ValueError:
        raise ValueError("No input file provided.")

    print(f"Read : {x}\n")
    with open(x, "r") as f:
        c = f.read()
        ts = parser(c)
        asm32(ts)
