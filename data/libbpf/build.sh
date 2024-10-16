#!/bin/bash
set -ex
source ../common.sh

PROJECT_NAME=libwebsockets
STALIB_NAME=libwebsockets.a
DYNLIB_NAME=libwebsockets.so
DIR=$(pwd)

function download() {

    apt-get install -y libelf-dev pkg-config zlib1g-dev

    cd $SRC

    git clone https://github.com/google/oss-fuzz.git
    RUN git clone https://github.com/libbpf/libbpf

    cp oss-fuzz/projects/libbpf/bpf-object-fuzzer.c $SRC/libbpf/
    rm -rf oss-fuzz
    echo "download done"
}

function build_lib() {

    LIB_STORE_DIR=$SRC/libbpf/build/lib/

    DIR=$SRC/libbpf/

    rm -rf elfutils
    git clone https://sourceware.org/git/elfutils.git
    (
        cd elfutils
        git checkout 67a187d4c1790058fc7fd218317851cb68bb087c
        git log --oneline -1

        # ASan isn't compatible with -Wl,--no-undefined: https://github.com/google/sanitizers/issues/380
        sed -i 's/^\(NO_UNDEFINED=\).*/\1/' configure.ac

        # ASan isn't compatible with -Wl,-z,defs either:
        # https://clang.llvm.org/docs/AddressSanitizer.html#usage
        sed -i 's/^\(ZDEFS_LDFLAGS=\).*/\1/' configure.ac

        if [[ "$SANITIZER" == undefined ]]; then
            # That's basicaly what --enable-sanitize-undefined does to turn off unaligned access
            # elfutils heavily relies on on i386/x86_64 but without changing compiler flags along the way
            sed -i 's/\(check_undefined_val\)=[0-9]/\1=1/' configure.ac
        fi

        autoreconf -i -f
        if ! ./configure --enable-maintainer-mode --disable-debuginfod --disable-libdebuginfod \
            --disable-demangler --without-bzlib --without-lzma --without-zstd \
            CC="$CC" CFLAGS="-Wno-error $CFLAGS" CXX="$CXX" CXXFLAGS="-Wno-error $CXXFLAGS" LDFLAGS="$CFLAGS"; then
            cat config.log
            exit 1
        fi

        make -C config -j$(nproc) V=1
        make -C lib -j$(nproc) V=1
        make -C libelf -j$(nproc) V=1
    )

    make -C src BUILD_STATIC_ONLY=y V=1 clean
    make -C src -j$(nproc) CFLAGS="-I$(pwd)/elfutils/libelf $CFLAGS" BUILD_STATIC_ONLY=y V=1

    echo "build libwebsockets done"

}
function build_oss_fuzz() {

    DIR=$SRC/libwebsockets/

    cd $DIR
    $CC $CFLAGS -Isrc -Iinclude -Iinclude/uapi -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -c fuzz/bpf-object-fuzzer.c -o bpf-object-fuzzer.o
    $CXX $CXXFLAGS $LIB_FUZZING_ENGINE bpf-object-fuzzer.o src/libbpf.a "$(pwd)/elfutils/libelf/libelf.a" -l:libz.a -o "$OUT/bpf-object-fuzzer"

    echo "build oss-fuzz done"
}

function build_corpus() {
    pwd
}

function copy_include() {
    mkdir -p ${LIB_BUILD}/include
    cp -r $SRC/libbpf/build/include/* ${LIB_BUILD}/include
}

function build_dict() {
    pwd
}

build_all
