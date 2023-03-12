"""RISCV Assembler"""
import sys
import re
from enum import Enum

from riscv import ISA


class Program(Enum):
    LABEL = 1
    INSTRUCTION = 2
    DIRECTIVE = 3
    COMMENT = 4


REG = {
    "sp": 0b00010,
    "s0": 0b01000,
    "a0": 10,
    "a1": 11,
    "a2": 12,
    "a3": 13,
    "a4": 14,
    "a5": 15,
    "a6": 16,
    "a7": 17,
}


def bm(bits: int = 32) -> int:
    """Returns a bitmask based for the number of bits given."""
    return 2**bits - 1


def two_compl(val: int, bits: int = 32):
    """Performs sign extension by number of bits given."""
    if val < 0:
        return bm(bits) & val
    else:
        return val


def parse(content: str):
    """Reads the assmbly code and returns list of tokenized symbols."""
    program = list()
    lines = content.split("\n")
    for line in lines:
        sl = list(filter(None, re.split(r"\t+|,| |\(|\)", line)))

        if sl:
            if re.match("\.+", sl[0]):
                program.append((Program.DIRECTIVE, sl))
            elif re.match("\w+(?: \w+)*:", sl[0]):
                program.append((Program.LABEL, sl))
            elif re.match("\#+", sl[0]):
                program.append((Program.COMMENT, sl))
            else:
                program.append((Program.INSTRUCTION, sl))

    return program


def encode(ins: list[str]) -> int:
    code = ins[1]
    if code[0] == "addi":
        value = two_compl(int(code[3]), 12)
        res = (
            ISA["addi"][0]
            + (REG[code[1]] << 7)
            + (ISA["addi"][1] << 12)
            + (REG[code[2]] << 15)
            + (value << 20)
        )

    if code[0] == "sb" or code[0] == "sh" or code[0] == "sw":
        value = two_compl(int(code[2]), 32)
        res = (
            ISA[code[0]][0]
            + ((value & bm(5)) << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[3]] << 15)
            + (REG[code[1]] << 20)
            + (((value >> 5) & bm(7)) << 25)
        )

    if code[0] == "li":
        value = two_compl(int(code[2]), 12)
        res = (
            ISA["li"][0]
            + (REG[code[1]] << 7)
            + (ISA["li"][1] << 12)
            + (ISA["li"][2] << 15)
            + (value << 20)
        )

    if code[0] == "lb" or code[0] == "lh" or code[0] == "lw":
        value = two_compl(int(code[2]), 12)
        res = (
            ISA[code[0]][0]
            + (REG[code[1]] << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[3]] << 15)
            + (value << 20)
        )

    print("Ins : ", hex(res))
    return res


def main():
    try:
        x = sys.argv[1]
    except:
        raise ValueError("No input file provided.")

    print(f"Read : {x}")
    content = open(x, "r").read()

    t = parse(content)
    for line in t:
        print(line)
        if line[0] == Program.INSTRUCTION:
            encode(line)
    print("")


if __name__ == "__main__":
    main()
