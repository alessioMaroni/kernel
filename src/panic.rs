// Copyright (c) 2026 The Kernel Project
//
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// http://mozilla.org/MPL/2.0/.

//! # Panic Handler & Fault Containment Module
//!
//! Provides the bare-metal panic handler required for `#![no_std]` runtime environment.
//!
//! ## Requirements Traced
//! - TODO(DOC-02): Map panic handler diagnostic logging to retention RAM requirement ID.

#[allow(unused_imports)]
use core::panic::PanicInfo;

/// Primary panic handler invoked by `core` when an unrecoverable fault occurs.
///
/// # Architecture & Constraints
/// - **Diverging Function:** This handler never returns (`!`).
/// - **Fault Isolation:** Prevents undefined execution when a kernel invariant or assertion fails.
/// - **Zero Allocation:** Operates strictly without dynamic memory allocation or heap dependencies.
///
/// # Behavior
/// In a production FDIR pipeline, this function will capture processor state into
/// Retention SRAM before forcing a system reset via Hardware Watchdog. Currently, it
/// places the CPU into a deterministic spin-loop to isolate the fault.
#[cfg(not(test))]
#[panic_handler]
pub fn panic_handler(#[allow(unused_variables)] info: &PanicInfo) -> ! {
    loop {}
}
