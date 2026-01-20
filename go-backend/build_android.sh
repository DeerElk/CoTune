#!/bin/bash
# Build script for Android

set -e

# Configuration
APP_PACKAGE="ru.apps78.cotune"
ANDROID_NDK="${ANDROID_NDK:-$HOME/Android/Sdk/ndk/25.2.9519653}"
GO_VERSION="1.24.6"

# Architectures to build
ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64")

echo "Building CoTune Go daemon for Android"
echo "NDK: $ANDROID_NDK"

# Check NDK
if [ ! -d "$ANDROID_NDK" ]; then
    echo "Error: Android NDK not found at $ANDROID_NDK"
    echo "Please set ANDROID_NDK environment variable"
    exit 1
fi

# Create output directory
OUTPUT_DIR="build/android"
mkdir -p "$OUTPUT_DIR"

# Build for each architecture
for arch in "${ARCHS[@]}"; do
    echo ""
    echo "Building for $arch..."
    
    case $arch in
        "arm64-v8a")
            GOARCH=arm64
            CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
            ;;
        "armeabi-v7a")
            GOARCH=arm
            CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"
            ;;
        "x86_64")
            GOARCH=amd64
            CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"
            ;;
    esac
    
    OUTPUT="$OUTPUT_DIR/$arch/cotune-daemon"
    mkdir -p "$(dirname "$OUTPUT")"
    
    # Build Go daemon binary (executable, not shared library)
    # The daemon runs as a separate process, not as JNI library
    # Using libp2p v0.45.0 (stable)
    CGO_ENABLED=1 \
    GOOS=android \
    GOARCH=$GOARCH \
    CC=$CC \
    go build \
        -o "$OUTPUT" \
        -ldflags="-s -w -checklinkname=0" \
        ./cmd/daemon
    
    echo "Built: $OUTPUT"
done

echo ""
echo "Build complete! Libraries are in $OUTPUT_DIR"
echo ""
echo "Copying binaries to Flutter project..."

# Copy to Flutter project
FLUTTER_JNI_DIR="../flutter-app/android/app/src/main/jniLibs"
mkdir -p "$FLUTTER_JNI_DIR"

for arch in "${ARCHS[@]}"; do
    SRC="$OUTPUT_DIR/$arch/cotune-daemon"
    DST="$FLUTTER_JNI_DIR/$arch"
    if [ -f "$SRC" ]; then
        mkdir -p "$DST"
        cp "$SRC" "$DST/cotune-daemon"
        chmod +x "$DST/cotune-daemon"
        echo "Copied $arch to $DST"
    fi
done

echo ""
echo "Binaries copied to $FLUTTER_JNI_DIR"
