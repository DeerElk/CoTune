#!/usr/bin/env bash
set -euo pipefail

ANDROID_NDK="${ANDROID_NDK:-$HOME/Android/Sdk/ndk/28.2.13676358}"

JNI_LIBS_DIR="../flutter-app/android/app/src/main/jniLibs"

ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64")

echo "=== Building CoTune Go daemon for Android (CGO ENABLED) ==="
echo "NDK: $ANDROID_NDK"
echo ""

for arch in "${ARCHS[@]}"; do
    echo "Building for $arch"

    unset GOARM

    case "$arch" in
        arm64-v8a)
            GOARCH=arm64
            CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
            ;;
        armeabi-v7a)
            GOARCH=arm
            GOARM=7
            CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"
            ;;
        x86_64)
            GOARCH=amd64
            CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"
            ;;
    esac

    OUT_DIR="$JNI_LIBS_DIR/$arch"
    OUT_BIN="$OUT_DIR/cotune-daemon.so"

    mkdir -p "$OUT_DIR"

    CGO_ENABLED=1 \
    GOOS=android \
    GOARCH="$GOARCH" \
    GOARM="${GOARM:-}" \
    CC="$CC" \
    go build \
        -buildmode=pie \
        -ldflags="-s -w -checklinkname=0" \
        -o "$OUT_BIN" \
        ./cmd/daemon

    chmod 755 "$OUT_BIN"

    echo "✓ $arch done"
    echo ""
done

echo "=== Build complete ==="
echo "Binaries placed in $JNI_LIBS_DIR"
