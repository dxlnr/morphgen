#!/bin/bash -e
python3 makehex.py $1 > test.bin
iverilog -Wall -g2012 -o riscv riscv_testbench.sv cpu/riskv_cpu.v && vvp riscv +firmware=test.bin
rm -rf riscv 
rm -rf test.bin
