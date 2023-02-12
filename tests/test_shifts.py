"""Testing Suite"""

def dins(ins: int, e: int, s: int):
    """Decode single instruction by slices.

    :param ins: Instruction as binary str.
    :param s: Starting point of chunk.
    :param e: Ending point of chunk.
    """
    return ins >> s & ((1 << (e - s + 1)) - 1)


def test_dins():
    pass


def test_sext():
    def sext(val: int, bits: int):
        sb = 1 << (bits - 1)
        return (val & (sb - 1)) - (val & sb)

    imm = 0b10101110100000010
    imm_i = sext(imm, 12)
    print(bin(imm_i), imm_i)


def test_jal():
    res = 0b10100101011100
    imm = 0b10101110100000010

    offset = (
        ((dins(imm, 19, 19) << 12) - decode_ins(imm, 19, 19) << 18)
        | (dins(imm, 7, 0) << 11)
        | (dins(imm, 8, 8) << 10)
        | dins(imm, 19, 9)
    ) << 1

    assert res == offset

def test_branch():
    ins = 0b1001110101000101000

    offset = dins(ins, 31, 31) << 20 
    print("off: ", bin(offset))



if __name__ == "__main__":
    # test_branch()
    test_sext()
