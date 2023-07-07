"""ARM Assembler"""
import sys
import re
from enum import Enum


class OPCODE(Enum):
    ADD = 'add'


class Program(Enum):
    DIRECTIVE = 1
    LABEL = 2
    INSTRUCTION = 2
    COMMENT = 3


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

def asm(tokens):
    """ARM assambler."""
    for t in tokens:
        if t[0] == Program.INSTRUCTION:
            if t[1][0


    # if opdc:
    #     print(opdc)
    # else:
    #     raise RuntimeError('OPCODE not supported.')


if __name__ == '__main__':
    try:
        x = sys.argv[1]
    except ValueError:
        raise ValueError("No input file provided.")

    print(f"Read : {x}\n")

    with open(x, "r") as f:
        c = f.read()

        ts = parser(c)
        # arm_assambler(c)
