#!/bin/bash
set -ex
source ../common.sh

PROJECT_NAME=libdwarf
STALIB_NAME=libdwarf.a
DYNLIB_NAME=libdwarf.so
DIR=$(pwd)

function download() {


    apt-get install -qq -y cmake make zlib1g-dev

    cd $SRC

    git clone --depth=1 https://github.com/davea42/libdwarf-code $SRC/libdwarf
    git clone --depth=1 https://github.com/davea42/libdwarf-binary-samples $SRC/libdwarf-binary-samples

    cd $SRC/libdwarf

    rm -rf oss-fuzz
    echo "download done"
}

function build_lib() {

    LIB_STORE_DIR=$SRC/libdwarf/build/src/lib/libdwarf/
    
    mkdir build

    DIR=$SRC/libdwarf/build

    cd $DIR
    cmake ../
    make

    echo "build libdwarf done"

}
function build_oss_fuzz() {
    pass
}

function build_corpus() {
    pwd
}

function copy_include() {
    mkdir -p ${LIB_BUILD}/include
    cp -r $SRC/libdwarf/src/lib/libdwarf/libdwarf.h ${LIB_BUILD}/include
}

function build_dict() {
    pwd
}

build_all
