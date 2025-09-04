use sha2::{Digest, Sha256};
use std::{
    fs::File,
    io::{self, BufReader, Read},
};

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum MomijiError {
    #[error("I/O error")]
    Io,
    #[error("Not found")]
    NotFound,
    #[error("Permission denied")]
    PermissionDenied,
    #[error("Unknown error")]
    Unknown,
}

// Non-throwing result wrapper
#[derive(uniffi::Record)]
pub struct ShaResult {
    pub ok: bool,
    pub hash: String,  // empty when ok == false
    pub error: String, // empty when ok == true
}

#[uniffi::export]
pub fn sha256_file(path: String) -> ShaResult {
    use io::ErrorKind;

    let file = match File::open(&path) {
        Err(e) => {
            return ShaResult {
                ok: false,
                hash: String::new(),
                error: e.to_string(),
            }
        }
        Ok(f) => f,
    };

    let mut reader = BufReader::new(file);
    let mut hasher = Sha256::new();
    let mut buf = [0u8; 1024 * 1024];

    loop {
        match reader.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => hasher.update(&buf[..n]),
            Err(e) => {
                return ShaResult {
                    ok: false,
                    hash: String::new(),
                    error: e.to_string(),
                }
            }
        }
    }

    ShaResult {
        ok: true,
        hash: hex::encode(hasher.finalize()),
        error: String::new(),
    }
}

#[uniffi::export]
pub fn ping() -> String {
    "pong".into()
}
