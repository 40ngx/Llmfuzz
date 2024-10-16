#!/bin/bash
set -ex
source ../common.sh

PROJECT_NAME=libexif
STALIB_NAME=libexif.a
DYNLIB_NAME=libexif.so
DIR=$(pwd)

function download() {
    if [[ ! -z "${DOCKER_CONTAINER:-}" ]]; then  
        apt-get update && apt-get install -y make autoconf automake libtool gettext autopoint
    fi
    cd $SRC
    # if [ -x "$(command -v coscli)" ]; then
    #     coscli cp cos://sbd-testing-1251316161/bench_archive/LLM_FUZZ/archives/aom.tar.gz aom.tar.gz
    #     tar -xvf aom.tar.gz && rm aom.tar.gz
    # else
    #     git clone --depth 1 https://aomedia.googlesource.com/aom
    # fi
    git clone https://github.com/google/oss-fuzz.git
    cp oss-fuzz/projects/libexif/exif_from_data_fuzzer.cc .
    cp oss-fuzz/projects/libexif/exif_loader_fuzzer.cc .
    rm -rf oss-fuzz
    git clone https://gitee.com/src-openeuler/libexif.git
    tar -zvxf libexif/libexif-0_6_24-release.tar.gz && rm -rf libexif
    mv libexif-libexif-0_6_24-release libexif
    git clone --depth 1 https://github.com/ianare/exif-samples
    echo "download done"
}

function build_lib() {
    LIB_STORE_DIR=$SRC/libexif/libexif/.libs
    cd $SRC/libexif
    autoreconf -fiv
    ./configure --disable-docs --enable-shared --prefix="$WORK"
    make -j$(nproc)
    make install
    echo "build libexif done"
}
function build_oss_fuzz() {
    for fuzzer in $(find $SRC/ -name '*_fuzzer.cc'); do
    fuzzer_basename=$(basename -s .cc $fuzzer)
    echo $CXX
    echo $CXXFLAGS
    $CXX -g0 $CXXFLAGS -fsanitize=fuzzer,address \
        -std=c++11 \
        -I"$WORK/include" \
        $fuzzer \
        -o $OUT/$fuzzer_basename \
        $LIB_FUZZING_ENGINE \
        "$WORK/lib/libexif.a"
    done
    echo "build oss-fuzz done"
}

function build_corpus() {

    mkdir -p ${LIB_BUILD}/corpus
    pushd $SRC
    find exif-samples -type f -name '*.jpg' -exec mv -n {} ${LIB_BUILD}/corpus/ \; -o -name '*.tiff' -exec mv -n {} ${LIB_BUILD}/corpus/ \;
    cp libexif/test/testdata/*.jpg ${LIB_BUILD}/corpus
    #zip -r "$WORK/exif_seed_corpus.zip" exif_corpus/
    popd
}

function copy_include() {
    mkdir -p ${LIB_BUILD}/include
    cp -r $SRC/libexif/libexif/*.h ${LIB_BUILD}/include
}

function build_dict() {
    pwd
}

build_all
