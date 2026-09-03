#!/bin/bash

emsdk/emsdk install 3.1.10

emsdk/emsdk activate 3.1.10

source emsdk/emsdk_env.sh

# Anything past the build directory is passed straight through to cmake.
emcmake cmake -B $1 -S . "${@:2}"