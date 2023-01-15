## Installing and Building Toolchain

```bash
git submodule update --init --recursive
```

#### RISC-V GNU Compiler Toolchain

Please be aware that this can take a couple of hourse depending on your system.
```bash
# Prerequisites
sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build

# Installation (Newlib)
./configure --prefix=/opt/riscv
make

# Installation (Linux)
./configure --prefix=/opt/riscv
make linux

# Adding to Path
# bash
export RISCV=/opt/riscv
export PATH=$PATH:$RISCV/bin
# fish
set RISCV /opt/riscv $RISCV
set PATH $RISCV/bin $PATH
```

#### RISCV-Tests
RISCV environment variable has to be set to the RISC-V tools install path, and the riscv-gnu-toolchain package must be installed.
```bash
autoconf
./configure --prefix=$RISCV/target
make
make install
```