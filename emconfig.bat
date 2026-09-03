:: Setup WebAssembly build
:: Takes the build directory (default: build_wasm). Anything after it is passed
:: straight through to cmake.
::
:: Usage:
:: ./emconfig.bat <build_dir> [cmake args...]
::
:: Example:
:: ./emconfig.bat build_wasm
:: ./emconfig.bat build_wasm -DPython3_EXECUTABLE=C:\Python\python.exe


@echo off
setlocal
set "BUILD_DIR=build_wasm"
set "EXTRA_ARGS="

if "%~1" NEQ "" (
  set "BUILD_DIR=%~1"
)

:: Everything past the build directory goes to cmake verbatim. Taken off %* rather
:: than %2 onwards because cmd splits arguments on '=' as well as on spaces, which
:: would hand cmake "-DVAR" and "value" as two arguments instead of one.
set "ALL_ARGS=%*"
if defined ALL_ARGS (
  for /f "tokens=1,* delims= " %%a in ("%ALL_ARGS%") do set "EXTRA_ARGS=%%b"
)

pushd "%~dp0"

call tools\emsdk\emsdk.bat install 3.1.10
call tools\emsdk\emsdk.bat activate 3.1.10

emcmake cmake -B %BUILD_DIR% -S . -G Ninja %EXTRA_ARGS%

popd
endlocal
