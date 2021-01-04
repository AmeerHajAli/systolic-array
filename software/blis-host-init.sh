#!/bin/bash

set -e

# This script will run on the host from the workload directory
# (e.g. workloads/example-fed) every time the workload is built.
# It is recommended to call into something like a makefile because
# this script may be called multiple times.

# clean up state
rm -rf ../overlay/root/blis/

cd blis
echo "Building RISCV Blis"
# configure to build for riscv64 (single thread, static library)
./configure CC=riscv64-unknown-linux-gnu-gcc --enable-shared --enable-cblas riscv64
make clean
make -j8

echo "Building Gemmini Blis"
# configure to build for gemmini (shared library)
./configure CC=riscv64-unknown-linux-gnu-gcc --enable-shared --enable-cblas gemmini
# configure to build for gemmini (explicity disable threading and pools, shared library)
#./configure CC=riscv64-unknown-linux-gnu-gcc --disable-threading --disable-pba-pools --disable-sba-pools --enable-shared --enable-cblas gemmini
# configure to build for gemmini (openmp multithread, independant testing since statically built)
#./configure CC=riscv64-unknown-linux-gnu-gcc LDFLAGS=-static -t openmp --enable-shared --enable-cblas gemmini
# configure to build for gemmini (pthreads multithread slightly slower than openmp, shared library)
#./configure CC=riscv64-unknown-linux-gnu-gcc -t pthreads --enable-shared --enable-cblas gemmini
# configure to build for gemmini (openmp multithread, shared library assuming fedora - not buildroot - because of libgomp.so req)
#./configure CC=riscv64-unknown-linux-gnu-gcc -t openmp --enable-shared --enable-cblas gemmini
# build library
make clean
make -j8
# build tests
echo "Building Blis Tests"
make testsuite-bin
make blastest-bin
# copy to linux overlay
echo "Copying Blis and tests to overlay"
mkdir -p ../overlay/root/blis
echo '#!/usr/bin/env bash' > ../overlay/root/blis/make-check.sh
echo `` >> ../overlay/root/blis/make-check.sh
make -n check >> ../overlay/root/blis/make-check.sh
chmod 775 ../overlay/root/blis/make-check.sh
cp test_libblis.x ../overlay/root/blis 
cp -r obj/ ../overlay/root/blis/obj
cp -r lib/ ../overlay/root/blis/lib
cp -r include/ ../overlay/root/blis/include
cp -r testsuite ../overlay/root/blis
cp -r blastest ../overlay/root/blis
