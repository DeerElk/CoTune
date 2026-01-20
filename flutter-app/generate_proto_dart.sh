#!/bin/bash
# Generate Dart code from protobuf definitions

set -e

PROTO_DIR="../../go-backend/api"
OUTPUT_DIR="lib/generated"

echo "Generating Dart protobuf code..."

# Check if protoc is available
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc not found in PATH"
    echo "Install Protocol Buffers compiler: https://grpc.io/docs/protoc-installation/"
    exit 1
fi

# Check if protoc-gen-dart is available
if ! command -v protoc-gen-dart &> /dev/null; then
    echo "Installing protoc-gen-dart..."
    dart pub global activate protoc_plugin
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate Dart code
protoc --dart_out=grpc:"$OUTPUT_DIR" \
       --proto_path="$PROTO_DIR" \
       "$PROTO_DIR/cotune.proto"

if [ $? -eq 0 ]; then
    echo "Dart protobuf code generated in $OUTPUT_DIR"
else
    echo "Error generating Dart protobuf code"
    exit 1
fi
