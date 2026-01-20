@echo off
REM Generate Go code from protobuf definitions

set PROTO_DIR=api
set OUTPUT_DIR=api\proto

echo Generating protobuf code...

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Check if protoc is available
where protoc >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Warning: protoc not found in PATH
    echo Placeholder files will be used. To generate actual code:
    echo 1. Install Protocol Buffers compiler from https://grpc.io/docs/protoc-installation/
    echo 2. Add protoc to PATH
    echo 3. Run this script again
    echo.
    echo Continuing with placeholder files...
    goto :end
)

REM Generate Go code (files will be in api/proto/api/ to match go_package option)
protoc --go_out=%OUTPUT_DIR% --go_opt=paths=source_relative --go-grpc_out=%OUTPUT_DIR% --go-grpc_opt=paths=source_relative --proto_path=%PROTO_DIR% %PROTO_DIR%\cotune.proto

if %ERRORLEVEL% EQU 0 (
    echo Protobuf code generated in %OUTPUT_DIR%
) else (
    echo Error generating protobuf code. Using placeholder files.
)

:end
