"""RISCV Assembler"""
import sys
import re
from enum import Enum

from riscv import ISA, REG


class Program(Enum):
    LABEL = 1
    INSTRUCTION = 2
    DIRECTIVE = 3
    COMMENT = 4


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
    pc = 0
    for line in lines:
        sl = list(filter(None, re.split(r"\t+|,| |\(|\)", line)))

        if sl:
            if re.match("\.+", sl[0]):
                program.append((Program.DIRECTIVE, sl))
            elif re.match("\w+(?: \w+)*:", sl[0]):
                program.append((Program.LABEL, sl, pc))
            elif re.match("\#+", sl[0]):
                program.append((Program.COMMENT, sl))
            else:
                program.append((Program.INSTRUCTION, sl, pc))
                pc += 4

    return program


def encode(enc: list[int], ins: list[str]) -> int:
    code = ins[1]
    if code[0] == "addi" or code[0] == "mv":
        if code[0] == "mv":
            value = 0
        else:
            try:
                value = two_compl(int(code[3]), 12)
            except:
                value = 0
        enc.append(
            ISA[code[0]][0]
            + (REG[code[1]] << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[2]] << 15)
            + (value << 20)
        )

    if code[0] == "sb" or code[0] == "sh" or code[0] == "sw":
        value = two_compl(int(code[2]), 32)
        enc.append(
            ISA[code[0]][0]
            + ((value & bm(5)) << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[3]] << 15)
            + (REG[code[1]] << 20)
            + (((value >> 5) & bm(7)) << 25)
        )

    if code[0] == "li":
        value = two_compl(int(code[2]), 12)
        enc.append(
            ISA[code[0]][0]
            + (REG[code[1]] << 7)
            + (ISA[code[0]][1] << 12)
            + (ISA[code[0]][2] << 15)
            + (value << 20)
        )

    if code[0] == "lb" or code[0] == "lh" or code[0] == "lw":
        value = two_compl(int(code[2]), 12)
        enc.append(
            ISA[code[0]][0]
            + (REG[code[1]] << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[3]] << 15)
            + (value << 20)
        )

    if code[0] == "add" or code[0] == "sub":
        enc.append(
            ISA[code[0]][0]
            + (REG[code[1]] << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[2]] << 15)
            + (REG[code[3]] << 20)
            + (ISA[code[0]][2] << 25)
        )

    if code[0] == "jalr":
        value = two_compl(int(code[2]), 12)
        enc.append(
            ISA[code[0]][0]
            + (REG[code[1]] << 7)
            + (ISA[code[0]][1] << 12)
            + (REG[code[3]] << 15)
            + (value << 20)
        )

    if code[0] == "lui":
        enc.append(ISA[code[0]][0] + (REG[code[1]] << 7))

    if code[0] == "jr":
        enc.append(ISA[code[0]][0] + (REG[code[1]] << 7) + (ISA[code[0]][1] << 12))

    if code[0] == "call":
        enc.append(ISA["auipc"][0] + (REG["ra"] << 7))
        enc.append(
            ISA["jalr"][0] + (REG["ra"] << 7) + (ISA["jalr"][1] << 12) + (1 << 15)
        )

    return enc


def main():
    try:
        x = sys.argv[1]
    except ValueError:
        raise ValueError("No input file provided.")

    print(f"Read : {x}")
    content = open(x, "r").read()

    t = parse(content)
    print(t)
    enc = list()
    for line in t:
        if line[0] == Program.INSTRUCTION:
            enc = encode(enc, line)

    # Print results.
    print("    Instructions:")
    for e in enc:
        print("\t%08x " % e)


if __name__ == "__main__":
    main()
