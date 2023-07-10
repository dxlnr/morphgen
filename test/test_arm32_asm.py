import sys
import os
import glob
from pathlib import Path

sys.path.insert(0, os.path.abspath(Path(__file__).parent.parent))

from arm_asm import asm32, parser

TESTFS = ['testfs/arm32_subtract.s', 'testfs/arm32_prime.s']

def test_arm_asm():
    ts, asmfs = [], []
    for x in TESTFS:
        with open(x, "r") as f:
            asmfs.append(asm32(parser(f.read())))

    for x in glob.glob('test/*.hex'):
        with open(x, 'rb') as f:
            ts.append(list(filter(None, f.read().replace(b' ', b'').split(b'\n'))))

    for i, t in enumerate(ts):
        for j, y in enumerate(t):
            ts[i][j] = int(y, base=16)

    for i, (t, asm) in enumerate(zip(ts, asmfs)):
        for j, (y, x) in enumerate(zip(t, asm)):
            assert y == x, f"Test {i} of {TESTFS[i]} failed for instruction {j}: target: {hex(t[j])} != actual: {hex(asm[j])}."
