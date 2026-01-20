@echo off
REM Build script for Android (Windows)

setlocal enabledelayedexpansion

REM Configuration
set APP_PACKAGE=ru.apps78.cotune
set ANDROID_NDK=%ANDROID_NDK%
if "%ANDROID_NDK%"=="" set ANDROID_NDK=%LOCALAPPDATA%\Android\Sdk\ndk\28.2.13676358
set GO_VERSION=1.24.6

REM Architectures to build
set ARCHS=arm64-v8a armeabi-v7a x86_64

echo Building CoTune Go daemon for Android
echo NDK: %ANDROID_NDK%

REM Check NDK
if not exist "%ANDROID_NDK%" (
    echo Error: Android NDK not found at %ANDROID_NDK%
    echo Please set ANDROID_NDK environment variable
    exit /b 1
)

REM Create output directory
set OUTPUT_DIR=build\android
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Build for each architecture
for %%a in (%ARCHS%) do (
    echo.
    echo Building for %%a...
    
    if "%%a"=="arm64-v8a" (
        set GOARCH=arm64
        set CC=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android21-clang.cmd
    ) else if "%%a"=="armeabi-v7a" (
        set GOARCH=arm
        set CC=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\armv7a-linux-androideabi21-clang.cmd
    ) else if "%%a"=="x86_64" (
        set GOARCH=amd64
        set CC=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\x86_64-linux-android21-clang.cmd
    )
    
    set OUTPUT=%OUTPUT_DIR%\%%a\cotune-daemon
    if not exist "%OUTPUT_DIR%\%%a" mkdir "%OUTPUT_DIR%\%%a"
    
    REM Build Go daemon binary (executable, not shared library)
    REM The daemon runs as a separate process, not as JNI library
    REM Using libp2p v0.45.0 (stable)
    set CGO_ENABLED=1
    set GOOS=android
    set GOARCH=!GOARCH!
    set CC=!CC!
    
    go build -o "!OUTPUT!" -ldflags="-s -w -checklinkname=0" ./cmd/daemon
    
    echo Built: !OUTPUT!
)

echo.
echo Build complete! Libraries are in %OUTPUT_DIR%
echo.
echo Copying binaries to Flutter project...

REM Copy to Flutter project
set FLUTTER_JNI_DIR=..\flutter-app\android\app\src\main\jniLibs
if not exist "%FLUTTER_JNI_DIR%" mkdir "%FLUTTER_JNI_DIR%"

for %%a in (%ARCHS%) do (
    set SRC=%OUTPUT_DIR%\%%a\cotune-daemon
    set DST=%FLUTTER_JNI_DIR%\%%a
    if exist "!SRC!" (
        if not exist "!DST!" mkdir "!DST!"
        copy /Y "!SRC!" "!DST!\cotune-daemon" >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo Copied %%a to !DST!
        ) else (
            echo Warning: Failed to copy %%a
        )
    ) else (
        echo Warning: Source file not found: !SRC!
        echo Expected location: %OUTPUT_DIR%\%%a\cotune-daemon
    )
)

echo.
echo Binaries copied to %FLUTTER_JNI_DIR%
