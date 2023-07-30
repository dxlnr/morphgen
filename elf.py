"""ELF Reader"""
import binascii
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
    memory = memory[:addr] + data + memory[addr + len(data) :]

    return memory


def dump_to_file(x, mem, dirs: str = "test-riscv/%s"):
    """Dumps instructions to file."""
    with open(dirs % x.split("/")[-1], "wb") as d:
        d.write(
            b"\n".join(
                [binascii.hexlify(mem[i : i + 4][::-1]) for i in range(0, len(mem), 4)]
            )
        )


def elf_reader(memory, file: str, to_file: bool = False):
    """Reads in an elf file format and returns opscode."""
    if not file.endswith(".dump"):
        with open(file, "rb") as f:
            elf = ELFFile(f)
            for s in elf.iter_segments(type="PT_LOAD"):
                memory = write_to_mem(memory, s.data(), s.header.p_paddr)

            if to_file:
                dump_to_file(file, memory)
    return memory
