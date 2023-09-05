pushd "%~dp0"

call tools\emsdk\emsdk.bat install 3.1.10
call tools\emsdk\emsdk.bat activate 3.1.10

popd