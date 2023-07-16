#!/bin/bash -e
python3 makehex.py $1 > /tmp/test.bin
iverilog -Wall -o acpu cpu_testbench.sv cpu/ram.v cpu/arm_cpu.v && vvp acpu +firmware=/test/subtract.bin
rm -rf acpu 
rm -rf tmp/test.bin
