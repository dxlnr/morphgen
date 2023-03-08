"""RISCV Assembler"""
import glob 
from elftools.elf.elffile import ELFFile


if __name__ == "__main__":
    for x in glob.glob("modules/riscv-tests/isa/rv32ui-p-*"):
        if x.endswith(".dump"):
            continue
        print(f"Execute : {x}")
        
        with open(x, "rb") as f:
            elf = ELFFile(f)

            for s in elf.iter_segments(type="PT_LOAD"):
                print(type(s))
                print(s.data())

        break
