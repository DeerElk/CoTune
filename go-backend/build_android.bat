@echo off
setlocal EnableDelayedExpansion

REM === CONFIG ===
if "%ANDROID_NDK%"=="" (
    set ANDROID_NDK=%LOCALAPPDATA%\Android\Sdk\ndk\28.2.13676358
)

REM Flutter Android jniLibs directory
set JNI_LIBS_DIR=..\flutter-app\android\app\src\main\jniLibs

set ARCHS=arm64-v8a armeabi-v7a x86_64

echo === Building CoTune Go daemon for Android (CGO ENABLED) ===
echo NDK: %ANDROID_NDK%
echo.

for %%A in (%ARCHS%) do (
    echo Building for %%A

    if "%%A"=="arm64-v8a" (
        set GOARCH=arm64
        set CC=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android21-clang.cmd
        set GOARM=
    ) else if "%%A"=="armeabi-v7a" (
        set GOARCH=arm
        set GOARM=7
        set CC=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\armv7a-linux-androideabi21-clang.cmd
    ) else if "%%A"=="x86_64" (
        set GOARCH=amd64
        set GOARM=
        set CC=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\x86_64-linux-android21-clang.cmd
    )

    set OUT_DIR=%JNI_LIBS_DIR%\%%A
    set OUT_BIN=!OUT_DIR!\cotune-daemon.so

    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"

    set CGO_ENABLED=1
    set GOOS=android
    set GOARCH=!GOARCH!
    if not "!GOARM!"=="" set GOARM=!GOARM!
    set CC=!CC!

    go build ^
        -buildmode=pie ^
        -ldflags="-s -w -checklinkname=0" ^
        -o "!OUT_BIN!" ^
        ./cmd/daemon

    if errorlevel 1 (
        echo X Build failed for %%A
        exit /b 1
    )

    echo OK %%A done
    echo.
)

echo === Build complete ===
echo Binaries placed in %JNI_LIBS_DIR%
