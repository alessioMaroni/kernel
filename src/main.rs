// Copyright (c) 2026 The Kernel Project
//
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// http://mozilla.org/MPL/2.0/.

//! # Kernel Main Entry Module
//!
//! Provides the primary execution loop for the `rsc-v` real-time safety-critical kernel.
//!
//! ## Requirements Traced
//! TODO(DOC-03): Map to definitive DO-178C requirement IDs for kernel main execution and safe loop.

#![no_std]
#![no_main]
#![deny(unsafe_code)]
#![deny(missing_docs)]
#![deny(clippy::undocumented_unsafe_blocks)]
#![deny(clippy::missing_safety_doc)]
#![deny(clippy::missing_errors_doc)]
#![deny(clippy::missing_panics_doc)]
#![deny(arithmetic_overflow)]
#![deny(clippy::arithmetic_side_effects)]
#![deny(clippy::indexing_slicing)]
#![deny(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod panic;
mod setup;

/// Main execution loop function of the kernel.
///
/// This function is invoked by `_setup` once low-level hardware initialization
/// (memory layout, stack pointer setup, and MPU configuration) is complete.
///
/// # Architecture & Constraints
/// - **Indefinite Execution:** This is the top-level idle loop of the bare-metal system;
///   it never returns (`!`).
/// - **Safety:** `unsafe` code is strictly forbidden in this scope.
///
/// # Behavior
/// Keeps the processor in a safe idle state while waiting for hardware interrupts
/// or scheduler tick events.

#[inline(never)]
#[forbid(unsafe_code)]
pub extern "C" fn _main() -> ! {
    #[allow(clippy::empty_loop)]
    loop {}
}
