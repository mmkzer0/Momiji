fn main() {
    // Rebuild if UDL changes
    println!("cargo:rerun-if-changed=src/momiji_core.udl");

    // scaff gen
    uniffi::generate_scaffolding("src/momiji_core.udl").unwrap();
}
