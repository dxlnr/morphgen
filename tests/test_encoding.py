"""Testing Suite"""
import sys

import pytest

sys.path.insert(0, "..")

from cpu import bitmask, dins, imm_b, imm_i, imm_j, imm_s, imm_u, sext


@pytest.fixture
def values():
    # JAL
    pytest.a_jal_ins = 0b10101110100000010001111101111
    pytest.a_jal_ins_imm_j = 0b10100101011100
    pytest.b_jal_ins = 0b10101110100000010000011101111
    pytest.b_jal_ins_imm_j = 0b10100101011100

    # AUIPC
    pytest.a_auipc_ins = 0b10000000000000000000000010110111
    pytest.a_auipc_ins_imm_u = 0b10000000000000000000000000000000
    pytest.b_auipc_ins = 0b10000000000000001000010010111
    pytest.b_auipc_ins_imm_u = 0b10000000000000001000000000000

    pytest.c_bne_ins = 0b1001100011101110001011001100011
    pytest.c_bne_ins_imm_b = 0b0


def test_imm_i():
    pass


def test_imm_s():
    pass


def test_imm_b():
    # assert imm_b(pytest.c_bne_ins) == pytest.c_bne_ins_imm_b
    pass


def test_imm_u(values):
    assert imm_u(pytest.a_auipc_ins) == pytest.a_auipc_ins_imm_u
    assert imm_u(pytest.b_auipc_ins) == pytest.b_auipc_ins_imm_u


def test_imm_j(values):
    assert imm_j(pytest.a_jal_ins) == pytest.a_jal_ins_imm_j
    assert imm_j(pytest.b_jal_ins) == pytest.b_jal_ins_imm_j
