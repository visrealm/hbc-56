#!/bin/bash

emsdk/emsdk install 3.1.10

emsdk/emsdk activate 3.1.10

source emsdk/emsdk_env.sh

emcmake cmake -B $1 -S .