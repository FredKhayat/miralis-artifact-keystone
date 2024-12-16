all:
	sudo apt-get update
	sudo apt install autoconf automake autotools-dev bc bison build-essential curl expat libexpat1-dev flex gawk gcc git gperf libgmp-dev libmpc-dev libmpfr-dev libtool texinfo tmux patchutils zlib1g-dev wget bzip2 patch vim-common lbzip2 python3 pkg-config libglib2.0-dev libpixman-1-dev libssl-dev device-tree-compiler expect makeself unzip

	git clone git@github.com:keystone-enclave/keystone.git
	cd keystone \
	&& git fetch origin \
	&& git checkout 80ffb2f9d4e774965589ee7c67609b0af051dc8b \
	&& ./fast-setup.sh \
	&& git apply ../keystone.patch \
	&& make

	cp ./keystone/build-generic64/buildroot.build/images/Image keystone.img
	cp ./keystone/build-generic64/buildroot.build/images/rootfs.ext2 keystone.ext2

