def decode_ins(ins: int, e: int, s: int):
    """Decode single instruction by slices.

    :param ins: Instruction as binary str.
    :param s: Starting point of chunk.
    :param e: Ending point of chunk.
    """
    return ins >> s & ((1 << (e - s + 1)) - 1)


def test_shift():
    res = 0b10100101011100
    imm = 0b10101110100000010

    offset = (
        ((decode_ins(imm, 19, 19) << 12) - decode_ins(imm, 19, 19) << 18)
        | (decode_ins(imm, 7, 0) << 11)
        | (decode_ins(imm, 8, 8) << 10)
        | decode_ins(imm, 19, 9)
    ) << 1

    assert res == offset


if __name__ == "__main__":
    test_shift()
