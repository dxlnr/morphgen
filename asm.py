"""RISCV Assembler"""
import sys
import re
from enum import Enum


class Program(Enum):
    LABEL = 1
    INSTRUCTION = 2
    DIRECTIVE = 3
    COMMENT = 4
    NA = 5


def parse(content: str):
    """Reads the assmbly code and returns list of tokenized symbols.""" 
    program = list()
    lines = content.split("\n")
    for line in lines:
        sl = list(filter(None, re.split(r'\t+|,| ', line)))
         
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


def main():
    try:
        x= sys.argv[1]
    except:
        raise ValueError("No input file provided.")

    print(f"Read : {x}")

    content = open(x, "r").read()

    t = parse(content)
    for line in t:
        print(line)


if __name__ == "__main__" : main ()
