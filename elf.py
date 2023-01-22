"""ELF Reader"""
from elftools.elf.elffile import ELFFile


def read_to_mem(memory, data, addr):
    """Reads opscode from elf segment & bumps it to memory.

    :param memory:
    :param data:
    :param addr:
    """
    print(hex(addr), len(data))
    print(addr)
    print("\n")

    addr -= 0x80000000
    assert addr >= 0 and addr > len(memory)
    memory = memory[:addr] + data + memory[addr + len(data):]

    return memory


def elf_reader(memory, file: str):
    """Reads in an elf file format and returns opscode."""
    if not file.endswith(".dump"):
        with open(file, "rb") as f:
            elf = ELFFile(f)

            for n, s in enumerate(elf.iter_segments()):
                # print(s.header)
                # print(s.data())
                print(n)
                # print("")
                # memory = read_to_mem(memory, s.data(), s.header.p_paddr)

    return memory
