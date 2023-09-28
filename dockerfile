FROM ubuntu:20.04

ENV RISCV=/opt/riscv32im
ENV PATH=$RISCV/bin:$PATH
# To skip input for tzdata (git dependency)
# https://qiita.com/yagince/items/deba267f789604643bab
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR $RISCV

RUN apt-get update && \
    apt-get install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev pkg-config git libusb-1.0-0-dev device-tree-compiler default-jdk gnupg vim 

RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
RUN git clone -b master --single-branch https://github.com/riscv/riscv-tests 
RUN git clone -b master --single-branch https://github.com/YosysHQ/picorv32

WORKDIR $RISCV/riscv-gnu-toolchain
RUN	git submodule update --init --recursive 
RUN mkdir build && cd build && ../configure --prefix=${RISCV} --with-arch=rv32im --with-abi=ilp32 && make

WORKDIR $RISCV/riscv-tests
RUN git submodule update --init --recursive 
# make tests program start from 0x00000
RUN sed -i 's/\. = 0x80000000;/\. = 0x00000000;/' env/p/link.ld
RUN autoconf 
RUN ./configure --prefix=$RISCV/target --with-xlen=32
RUN make isa
# FIXME installation failed 32-bit only build
# RUN make install

# RUN riscv32-unknown-elf-objcopy -O binary dhry.elf dhry.bin
RUN apt-get install bsdmainutils
RUN cd isa && find . -type f \( -name "rv32ui*" -o -name "rv32um*" \) ! -name "*.*" -exec sh -c 'file "{}" | grep -q ELF && riscv32-unknown-elf-objcopy -O binary "{}" "/tmp/{}.bin"' \;
# tmp/rv32u[i|m]-p-.*.[bin|hex]

WORKDIR $RISCV/picorv32/dhrystone
# make tests program start from 0x00000
RUN sed -i 's/\. = 0x10000;/\. = 0x00000;/' sections.lds
RUN make dhry.elf
RUN riscv32-unknown-elf-objcopy -O binary dhry.elf /tmp/dhry.bin
WORKDIR /tmp
RUN find . -maxdepth 1 -type f -name "*.bin" -exec sh -c 'base_name=$(basename "$0" .bin) && hexdump -v -e "/4 \"%08X\" \"\n\"" "$0" > "${base_name}.hex"' {} \;


WORKDIR $RISCV
