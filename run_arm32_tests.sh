#!/bin/bash

echo ".o : subtract.c"
echo ""
arm-linux-gnueabi-gcc -c -o subtract.o testfs/subtract.c
arm-linux-gnueabi-objcopy -S -O binary subtract.o subtract.bin
hexdump -e '"%08x " "\n"' subtract.bin
rm subtract.o subtract.bin

echo ""
echo ".o : prime.c"
echo ""
arm-linux-gnueabi-gcc -c -o prime.o testfs/prime.c
arm-linux-gnueabi-objcopy -S -O binary prime.o prime.bin
hexdump -e '"%08x " "\n"' prime.bin
rm prime.o prime.bin

# To get the final executable, run the following commands:
# You will find the instructions from above in it. The linker set its location.
# echo ""
# echo "subtract (elf) : subtract.c"
# echo ""
# arm-linux-gnueabi-gcc -o subtract testfs/subtract.c
# hexdump -e '"%08x " "\n"' subtract 
# rm subtract
