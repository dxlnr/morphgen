"""ELF Reader"""
from elftools.elf.elffile import ELFFile


def write_to_mem(memory, data, addr):
    """Reads opscode from elf segment & bumps it to memory.

    :param memory:
    :param data:
    :param addr:
    """
    if addr != 0:
        addr -= 0x80000000
    assert addr < len(memory)
    memory = memory[:addr] + data + memory[addr + len(data):]

    return memory


def elf_reader(memory, file: str):
    """Reads in an elf file format and returns opscode."""
    if not file.endswith(".dump"):
        with open(file, "rb") as f:
            elf = ELFFile(f)

            for s in elf.iter_segments(type="PT_LOAD"):
                memory = write_to_mem(memory, s.data(), s.header.p_paddr)
    return memory
