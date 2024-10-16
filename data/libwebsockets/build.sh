#!/bin/bash
set -ex
source ../common.sh

PROJECT_NAME=libwebsockets
STALIB_NAME=libwebsockets.a
DYNLIB_NAME=libwebsockets.so
DIR=$(pwd)

function download() {
    if [[ ! -z "${DOCKER_CONTAINER:-}" ]]; then
        apt-get update && apt-get install -y make autoconf automake libssl-dev
    fi
    cd $SRC

    git clone https://github.com/google/oss-fuzz.git
    git clone https://github.com/warmcat/libwebsockets.git
    tar -zvxf libwebsockets/v4.3.3.tar.gz && rm -rf libwebsockets
    # mv libwebsockets-4.3.3 libwebsockets
    cp oss-fuzz/projects/libwebsockets/lws_upng_inflate_fuzzer.cpp $SRC/libwebsockets/
    rm -rf oss-fuzz
    echo "download done"
}

function build_lib() {

    LIB_STORE_DIR=$SRC/libwebsockets/build/lib/

    DIR=$SRC/libwebsockets/

    cd $DIR
    mkdir build 
    cd build

    cmake -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="$CFLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$CFLAGS" ..
    make -j8
    echo "build libwebsockets done"

}
function build_oss_fuzz() {

    DIR=$SRC/libwebsockets/

    cd $DIR
    $CXX $CFLAGS $LIB_FUZZING_ENGINE -I$DIR/build/include -I$DIR/build/include/libwebsockets \
        -o $OUT/lws_upng_inflate_fuzzer $DIR/lws_upng_inflate_fuzzer.cpp \
        -L$DIR/build/lib -l:libwebsockets.a -lcap \
        -L/usr/lib/x86_64-linux-gnu/ -l:libssl.so -l:libcrypto.so
    
    echo "build oss-fuzz done"
}

function build_corpus() {
    pwd
}

function copy_include() {
    mkdir -p ${LIB_BUILD}/include
    cp -r $SRC/libwebsockets/build/include/* ${LIB_BUILD}/include
}

function build_dict() {
    pwd
}

build_all
