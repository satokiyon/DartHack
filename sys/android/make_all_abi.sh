#!/bin/bash

cd ../..

for abi in arm64-v8a armeabi-v7a armeabi x86_64 x86; do
    echo "=== Building for $abi ==="
    make clean
    make ABI=$abi -j4 install
    if [ $? -ne 0 ]; then
        echo "Build failed for $abi"
        exit 1
    fi
done