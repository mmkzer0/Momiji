#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cd rustcore

# Targets (Apple Silicon dev; add x86_64 sim if Intel Macs needed)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim >/dev/null || true

# Build initial ios and ios-sim targets
cargo build --lib --release --target aarch64-apple-ios
cargo build --lib --release --target aarch64-apple-ios-sim

# Generate Swift bindings (UniFFI) and XCFramework
# have to specify --features=uniffi/cli and call via cargo
cargo run --features=uniffi/cli --release --bin uniffi-bindgen generate src/momiji_core.udl --language swift --out-dir ./Generated

mkdir -p build/iphoneos build/iphonesim
cp -rf target/aarch64-apple-ios/release/libmomiji_core.a build/iphoneos/
cp -rf target/aarch64-apple-ios-sim/release/libmomiji_core.a build/iphonesim/

# package framework
rm -rf MomijiCore.xcframework
xcodebuild -create-xcframework \
	-library build/iphoneos/libmomiji_core.a \
	-library build/iphonesim/libmomiji_core.a \
	-output MomijiCore.xcframework

echo "✅ Built rustcore/MomijiCore.xcframework and Generated/momiji_core.swift"
