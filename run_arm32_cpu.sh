#!/bin/bash -e

iverilog -Wall -o acpu cpu/ram.v cpu/arm_cpu.v && vvp acpu 

rm -rf acpu
