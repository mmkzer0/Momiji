#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cd rustcore

# targets (Apple Silicon dev; add x86_64 sim if Intel Macs needed)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim >/dev/null || true

# build initial ios and ios-sim targets
cargo build --lib --release --target aarch64-apple-ios
cargo build --lib --release --target aarch64-apple-ios-sim

# generate Swift bindings (UniFFI) and XCFramework
# have to specify --features=uniffi/cli and call via cargo
# cargo run --features=uniffi/cli --release --bin uniffi-bindgen generate src/momiji_core.udl --language swift --out-dir ./Generated
cargo run --features=uniffi/cli --release --bin uniffi-bindgen generate --library target/aarch64-apple-ios/release/libmomiji_core.a --language swift --out-dir ./Generated

# prepare a headers dir that contains the header + *module.modulemap*
GEN=./Generated
HEADERS_DIR=build/headers
rm -rf "$HEADERS_DIR"
mkdir -p "$HEADERS_DIR"

cp -rf "$GEN/momiji_coreFFI.h" "$HEADERS_DIR/"

cp -rf "$GEN/momiji_core.swift" "../app/Momiji/Momiji/momiji_core.swift"

# UniFFI writes "momiji_coreFFI.modulemap"; Xcode expects the file name "module.modulemap"
# Create/rename it accordingly:
cp -rf "$GEN/momiji_coreFFI.modulemap" "$HEADERS_DIR/module.modulemap"

# slice directories
mkdir -p build/iphoneos build/iphonesim
cp -rf target/aarch64-apple-ios/release/libmomiji_core.a build/iphoneos/
cp -rf target/aarch64-apple-ios-sim/release/libmomiji_core.a build/iphonesim/

# package framework
rm -rf MomijiCore.xcframework
xcodebuild -create-xcframework \
	-library build/iphoneos/libmomiji_core.a -headers "$HEADERS_DIR" \
	-library build/iphonesim/libmomiji_core.a -headers "$HEADERS_DIR" \
	-output MomijiCore.xcframework

echo "✅ Built rustcore/MomijiCore.xcframework and Generated/momiji_core.swift"
