KEYSTONE_PATCHES = ../keystone.patch
OPENSBI_PATCHES = ../opensbi.patch
CROSS_COMPILE = riscv64-linux-gnu- 

.PHONY: all install musl iozone keystone opensbi

ifeq ($(shell uname -o), Darwin)
	CROSS_COMPILE = riscv64-elf-
	OPENSBI_PATCHES += ../opensbi_macos.patch
endif

all: install musl iozone keystone opensbi

# Install all necessary tools
install:
	sudo apt-get update
	sudo apt install autoconf automake autotools-dev bc bison build-essential curl expat libexpat1-dev flex gawk gcc git gperf libgmp-dev libmpc-dev libmpfr-dev libtool texinfo tmux patchutils zlib1g-dev wget bzip2 patch vim-common lbzip2 python3 pkg-config libglib2.0-dev libpixman-1-dev libssl-dev device-tree-compiler expect makeself unzip gcc-riscv64-linux-gnu

# Build the musl C standard library
musl:
	-git clone https://github.com/richfelker/musl-cross-make
	cd musl-cross-make \
	&& TARGET=riscv64-linux-musl make \
	&& TARGET=riscv64-linux-musl make install

# Compile iozone with musl
iozone:
	-git clone https://github.com/keystone-enclave/keystone-iozone.git
	cd keystone-iozone \
	&& git checkout 9c226f3 \
	&& CCRV=../musl-cross-make/output/bin/riscv64-linux-musl-gcc make riscv_musl

	cp keystone-iozone/iozone .

# Build a linux image with the keystone driver.
# Build a disk image with some examples and the iozone benchmark
keystone:
	-git clone https://github.com/keystone-enclave/keystone.git
	cd keystone \
	&& git fetch origin \
	&& git checkout 80ffb2f9d4e774965589ee7c67609b0af051dc8b \
	&& ./fast-setup.sh \
	&& git apply $(KEYSTONE_PATCHES) \
	&& cp ../iozone examples/iozone/eapp \
	&&  make

	cp ./keystone/build-generic64/buildroot.build/images/Image Image_keystone
	cp ./keystone/build-generic64/buildroot.build/images/rootfs.ext2 keystone.ext2

# Build OpenSBI with the linux+keystone payload
opensbi:
	-git clone --depth 1 --branch v1.4 https://github.com/riscv-software-src/opensbi.git
	cd opensbi && git apply $(OPENSBI_PATCHES)
	make -C opensbi PLATFORM=generic \
		O=build \
		FW_PAYLOAD=y \
		FW_PAYLOAD_PATH=../Image_keystone \
		FW_PAYLOAD_ALIGN=0x200000 \
		FW_TEXT_START=0x80200000 \
		FW_DYNAMIC=n \
		FW_JUMP=n \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		-j`nproc`

	cp opensbi/build/platform/generic/firmware/fw_payload.bin opensbi-linux-keystone.bin
	cp opensbi/build/platform/generic/firmware/fw_payload.elf opensbi-linux-keystone.elf
