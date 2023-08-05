# Morphgen

## RISC-V

Implementing an Assembler & Processor using the [RISC-V](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) instruction set and [arm](https://en.wikipedia.org/wiki/ARM_architecture_family). 

### CPU

```
fetch -> decode -> execute -> memory access -> write back
```

For testing the **cpu**, clone and build the `riscv-tests`. The tests can be found in the modules/ folder. 
Please follow along the installation [guide](modules/README.md).

Run the tests via:
```bash
python riscv_cpu.py
```

**Verilog**

```bash
./run_arm32_cpu.sh test/subtract.hex
```

### Assembler 

**Disclaimer**: Unfinished

Run the Assembler via: 
```bash 
python riscv_asm.py testfs/riscv_minimal.s
``` 

## ARM

**Prequisits**: Cross-Compiler (if you are not on a ARM architecture natively)
```bash
sudo apt install gcc gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu make
```

### ARM Assembler


```bash
python arm_asm.py testfs/subtract.s
# Run automatic tests with
python -m unittest
```

Run the bash script to investigate the desired output of the assembler.
```bash
./run_arm32_tests.sh
```

### Additional Material

Source -> Preprocessor -> Compiler -> assembly (.asm) -> Assembler -> object (.o) -> (+ Libraries) Linker -> Executable

#### ARMv

- [ARM Docs A32](https://developer.arm.com/documentation/ddi0597/2023-06/A32-Instructions-by-Encoding)
- ARM Instructions Layout
```
MNEMONIC{S}{condition} {Rd}, Operand1, Operand2

MNEMONIC     - Short name (mnemonic) of the instruction
{S}          - An optional suffix. If S is specified, the condition flags are updated on the result of the operation
{condition}  - Condition that is needed to be met in order for the instruction to be executed
{Rd}         - Register (destination) for storing the result of the instruction
Operand1     - First operand. Either a register or an immediate value 
Operand2     - Second (flexible) operand. Can be an immediate value (number) or a register with an optional shift
```

#### RISC-V

- Course: [Computer Systems Organization](https://nyu-cso.github.io/index.html)
- [Unofficial RISC-V Manual](https://jemu.oscc.cc/): Additional manuscript about RISC-V along the official RISC-V Manual.
- [riscv-isadoc](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html): Instruction Set docs on Github.
- [riscv-dbg](https://github.com/pulp-platform/riscv-dbg/tree/master)
