@echo off
REM Generate Dart code from protobuf definitions

set PROTO_DIR=..\go-backend\api
set OUTPUT_DIR=lib\generated

echo Generating Dart protobuf code...

REM Check if protoc is available
where protoc >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: protoc not found in PATH
    echo Install Protocol Buffers compiler from https://grpc.io/docs/protoc-installation/
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Generate Dart code
protoc --dart_out=grpc:%OUTPUT_DIR% --proto_path=%PROTO_DIR% %PROTO_DIR%\cotune.proto

if %ERRORLEVEL% EQU 0 (
    echo Dart protobuf code generated in %OUTPUT_DIR%
) else (
    echo Error generating Dart protobuf code
    exit /b 1
)
