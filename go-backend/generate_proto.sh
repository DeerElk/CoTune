#!/bin/bash
# Generate Go code from protobuf definitions

set -e

PROTO_DIR="api"
OUTPUT_DIR="api/proto"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Generating protobuf code..."

# Check if protoc is available
if ! command -v protoc &> /dev/null; then
    echo "Warning: protoc not found in PATH"
    echo "Placeholder files will be used. To generate actual code:"
    echo "1. Install Protocol Buffers compiler: https://grpc.io/docs/protoc-installation/"
    echo "2. Add protoc to PATH"
    echo "3. Run this script again"
    echo ""
    echo "Continuing with placeholder files..."
    exit 0
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate Go code
protoc --go_out="$OUTPUT_DIR" \
       --go_opt=paths=source_relative \
       --go-grpc_out="$OUTPUT_DIR" \
       --go-grpc_opt=paths=source_relative \
       --proto_path="$PROTO_DIR" \
       "$PROTO_DIR/cotune.proto"

if [ $? -eq 0 ]; then
    echo "Protobuf code generated in $OUTPUT_DIR"
else
    echo "Error generating protobuf code. Using placeholder files."
fi
