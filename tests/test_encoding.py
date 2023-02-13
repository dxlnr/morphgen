"""Testing Suite"""
import sys

import pytest

sys.path.insert(0, '..')

from cpu import bitmask, dins, imm_b, imm_i, imm_j, imm_s, imm_u, sext


@pytest.fixture
def values():
    pytest.a_jal_ins = 0b10101110100000010001111101111
    pytest.a_jal_ins_imm_j = 0b10100101011100


# def test_sext():
#     def sext(val: int, bits: int):
#         sb = 1 << (bits - 1)
#         return (val & (sb - 1)) - (val & sb)

#     imm = 0b10101110100000010
#     imm_i = sext(imm, 12)
#     print(bin(imm_i), imm_i)


# def test_jal():
#     res = 0b10100101011100
#     imm = 0b10101110100000010

#     offset = (
#         ((dins(imm, 19, 19) << 12) - decode_ins(imm, 19, 19) << 18)
#         | (dins(imm, 7, 0) << 11)
#         | (dins(imm, 8, 8) << 10)
#         | dins(imm, 19, 9)
#     ) << 1

#     assert res == offset

# def test_branch():
#     ins = 0b1001110101000101000

#     offset = dins(ins, 31, 31) << 20
#     print("off: ", bin(offset))


def test_imm_i():
    pass

def test_imm_s():
    pass


def test_imm_b():
    pass


def test_imm_u():
    pass


def test_imm_j(values):
    assert imm_j(pytest.a_jal_ins) == pytest.a_jal_ins_imm_j
