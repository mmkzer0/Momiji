#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cd rustcore

# Targets (Apple Silicon dev; add x86_64 sim if Intel Macs needed)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim >/dev/null || true

cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim

# Generate Swift bindings (UniFFI) and XCFramework
uniffi-bindgen generate src/momiji_core.udl --language swift --out-dir ./Generated

mkdir -p build/iphoneos build/iphonesim
cp target/aarch64-apple-ios/release/libdoujin_core.a build/iphoneos/
cp target/aarch64-apple-ios-sim/release/libdoujin_core.a build/iphonesim/

xcodebuild -create-xcframework \
	-library build/iphoneos/libdoujin_core.a \
	-library build/iphonesim/libdoujin_core.a \
	-output MomijiCore.xcframework

echo "✅ Built rustcore/MomijiCore.xcframework and Generated/momiji_core.swift"
