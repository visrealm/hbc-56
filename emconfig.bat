:: Setup WebAssembly build
:: Takes a single argument bing the build directory (default: build_wasm)
::
:: Usage: 
:: ./emconfig.bat <build_dir>
::
:: Example:
:: ./emconfig.bat build_wasm


@echo off
setlocal
set BUILD_DIR=build_wasm

if "%~1" NEQ "" (
  set "BUILD_DIR=%~1"
)

pushd "%~dp0"

call tools\emsdk\emsdk.bat install 3.1.10
call tools\emsdk\emsdk.bat activate 3.1.10

emcmake cmake -B %BUILD_DIR% -S .

popd
endlocal