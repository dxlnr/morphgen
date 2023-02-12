"""RISC-V ISA Manual"""

OPCODE = {
    0b0110111: "LUI",
    0b0010111: "AUIPC",
    0b1101111: "JAL",
    0b1100111: "JALR",
    0b1100011: "BRANCH",
    0b0000011: "LOAD",
    0b0110011: "OP",
    0b0100011: "STORE",
    0b0010011: "ALU",
    0b0001111: "FENCE",
    0b1110011: "SYSTEM", 
}

INS = {}
