#!/bin/bash -e
python3 makehex.py $1 > /tmp/test.bin
iverilog -Wall -g2012 -o riskcpu cpu_testbench.v cpu/riskv_cpu.v && vvp riskv +firmware=tmp/test.bin
rm -rf acpu 
rm -rf tmp/test.bin
