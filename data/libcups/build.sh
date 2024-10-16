#!/bin/bash
set -ex
source ../common.sh

PROJECT_NAME=libcups
STALIB_NAME=libcups3.a
DYNLIB_NAME=libcups3.so
DIR=$(pwd)

function download() {


    apt-get install -y make autoconf automake libtool build-essential libavahi-client-dev libgnutls28-dev libnss-mdns zlib1g-dev libsystemd-dev

    cd $SRC

    git clone https://github.com/OpenPrinting/libcups.git libcups
    git clone https://github.com/OpenPrinting/fuzzing.git fuzzing

    cd $SRC/libcups
    git submodule update --init --recursive

    git clone https://github.com/google/oss-fuzz.git

    cp -r $SRC/fuzzing/projects/libcups/fuzzer $SRC/libcups/
    rm -rf oss-fuzz
    echo "download done"
}

function build_lib() {

    LIB_STORE_DIR=$SRC/libcups/cups/

    DIR=$SRC/libcups/

    cd $DIR

    ./configure

    make

    echo "build libcups done"
}

function build_oss_fuzz() {

    DIR=$SRC/libcups/fuzzer

    echo "build oss-fuzz done"
}

function build_corpus() {
    pwd
}

function copy_include() {
    mkdir -p ${LIB_BUILD}/include
    cp -r $SRC/libcups/cups/cups.h ${LIB_BUILD}/include
}

function build_dict() {
    pwd
}

build_all
