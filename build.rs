// Copyright (c) 2026 The Kernel Project
//
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// http://mozilla.org/MPL/2.0/.

//! # Build Script for Kernel Bootstrap and Linker Configurations
//!
//! This script manages the compilation of low-level assembly bootstrap files
//! and configures Cargo to pass board-specific linker scripts to `rustc` when 
//! targeting the Raspberry Pi RP2350 (Hazard3 RISC-V core).

use std::env;

fn main() {
    // Re-run this build script only if assembly source files or linker configurations change.
    println!("cargo:rerun-if-changed=src/boards/rp2350/image.s");
    println!("cargo:rerun-if-changed=src/boards/rp2350/start.s");
    println!("cargo:rerun-if-changed=src/boards/rp2350/rp2350_linker.ld");
    println!("cargo:rerun-if-changed=src/boards/rp2350/memory.x");

    // Board-specific compilation pipeline for RP2350
    if env::var("CARGO_FEATURE_RP2350").is_ok() {
        // Compile the RISC-V assembly bootstrap code into a static library.
        //
        // NOTE: 
        // `start.s` includes `image.s` via `.include`, so only `start.s` 
        // is directly passed to avoid duplicate symbol definitions.
        cc::Build::new()
            .file("src/boards/rp2350/start.s")
            .include("src/boards/rp2350")
            .no_default_flags(true)
            .flag("-Wno-unused-command-line-argument")
            .compile("rp2350_boot");

        // Instruct rustc where to look for linker scripts and pass the custom script.
        println!("cargo:rustc-link-search=native=src/boards/rp2350");
        println!("cargo:rustc-link-arg=-Trp2350_linker.ld");
    }
}