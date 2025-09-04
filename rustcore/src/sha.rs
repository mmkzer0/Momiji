use sha2::{Digest, Sha256};
use std::{
    fs::File,
    io::{BufReader, Read},
};

pub fn sha256_file(path: String) -> String {
    let file = File::open(&path).expect("file open failed");
    let mut reader = BufReader::new(file);
    let mut hasher = Sha256::new();
    let mut buf = [0u8; 1024 * 1024];
    loop {
        let n = reader.read(&mut buf).expect("read failed");
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }
    hex::encode(hasher.finalize())
}
