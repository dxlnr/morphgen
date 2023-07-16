#!/bin/bash -e
python3 makehex.py $1 > /tmp/test.bin
iverilog -Wall -g2012 -o acpu cpu_testbench.v cpu/ram.v cpu/arm_cpu.v && vvp acpu +firmware=test/subtract.hex
rm -rf acpu 
rm -rf tmp/test.bin
