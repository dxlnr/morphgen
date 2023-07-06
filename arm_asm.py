"""ARM Assembler"""
import sys

if __name__ == '__main__':
    try:
        x = sys.argv[1]
    except ValueError:
        raise ValueError("No input file provided.")

    print(f"Read : {x}")
    content = open(x, "r").read()
