# Morphgen

Implementing a Processor using the [RISC-V](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) instruction set. 

### CPU

For testing the **cpu**, clone and build the `riscv-tests`. The tests can be found in the modules/ folder. Please follow along the installation [guide](modules/README.md).

Run the tests via:
```bash
python cpu.py
```

### Assembler 

Run the Assembler via:
```bash 
python asm.py example/minimal.s
``` 
Currently under development. 
Todo:
- Linking
- Implementing all the instructions.


The *desired output* should be somewhat similiar to the following, although this is 
64-bit based. Obtain it by running:
```bash 
xxd -a modules/riscv-tests/isa/rv32ui-p-add 
```

```
00000000: 7f45 4c46 0101 0100 0000 0000 0000 0000  .ELF............
00000010: 0200 f300 0100 0000 0000 0080 3400 0000  ............4...
00000020: f025 0000 0000 0000 3400 2000 0300 2800  .%......4. ...(.
00000030: 0700 0600 0300 0070 4820 0000 0000 0000  .......pH ......
00000040: 0000 0000 3200 0000 0000 0000 0400 0000  ....2...........
00000050: 0100 0000 0100 0000 0010 0000 0000 0080  ................
00000060: 0000 0080 bc06 0000 bc06 0000 0500 0000  ................
00000070: 0010 0000 0100 0000 0020 0000 0010 0080  ......... ......
00000080: 0010 0080 4800 0000 4800 0000 0600 0000  ....H...H.......
00000090: 0010 0000 0000 0000 0000 0000 0000 0000  ................
000000a0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
*
00001000: 6f00 8004 732f 2034 930f 8000 6308 ff03  o...s/ 4....c...
00001010: 930f 9000 6304 ff03 930f b000 6300 ff03  ....c.......c...
```


#### Additional Material

- Course: [Computer Systems Organization](https://nyu-cso.github.io/index.html)
- [Unofficial RISC-V Manual](https://jemu.oscc.cc/): Additional manuscript about RISC-V along the official RISC-V Manual.
- [rvcodec.js]: An online encoder/decoder for RISCV-V instructions.
- [riscv-isadoc](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html): Instruction Set docs on Github.
