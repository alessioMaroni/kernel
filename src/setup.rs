// Copyright (c) 2026 The Kernel Project
//
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// http://mozilla.org/MPL/2.0/.

//! # Hardware Bootstrap & Low-Level Entry Point Module
//!
//! Provides the raw `_setup` entry point invoked by the hardware bootloader
//! or vector table on RISC-V targets.
//!
//! ## Requirements Traced
//! TODO(DOC-01): Map to definitive DO-178C requirement ID once assigned.

use crate::console::Console;

#[cfg(not(any(feature = "rp2350", /* feature = "another_feature" */)))]
compile_error!("Unsupported target board. Please enable a valid feature flag for your target board in Cargo.toml.");

/// Low-level C-ABI entry point executed immediately upon CPU reset.
///
/// This function acts as the bridge between the hardware reset vector / linker
/// script environment and the safe kernel execution phase.
///
/// # Safety
///
/// - Must only be invoked directly by the processor reset handler or boot vector.
/// - The stack pointer (`sp`) and global pointer (`gp`) registers must be initialized
///   by the assembly bootstrap or bootloader before executing this symbol.
/// - Memory sections (`.bss` zeroing and `.data` copy from Flash) must be set up
///   prior to or within this setup sequence.
///
/// # Behavior
///
/// Completes essential early hardware setup and jumps directly into [`_main`],
/// transferring control to the kernel's main execution loop.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn _setup() -> ! {
    // SAFETY: `Console::init` is called strictly once during single-threaded early kernel boot.
    let console_status = unsafe { Console::init() }.is_ok();

    // Verification of initialization status.
    let console = match (console_status, Console::get()) {
        (true, Some(c)) => c,
        _ => {
            #[allow(clippy::panic)]
            {
                panic!("Fatal: Console hardware initialization failed during boot");
            }
        }
    };

    // Once all initializations are completed and verified,
    // transition directly into the safe kernel `main` loop.
    crate::_main(console)
}
