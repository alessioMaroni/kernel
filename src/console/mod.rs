// Copyright (c) 2026 The Kernel Project
//
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// http://mozilla.org/MPL/2.0/.

//! # Console output module

use core::fmt::{self, Write};
use core::sync::atomic::{AtomicBool, Ordering};

#[cfg(feature = "rp2350")]
use rp2350_hazard3_hal;

/// Errors that can occur during console operations.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConsoleErrors {
    /// Occur when the `Console` is alredy initialized.
    AlreadyInitialized,
    /// Occur when the `Console` is not initialized.
    NotInitialized,
    /// Occurs when hardware initialization (e.g. UART reset timeout) fails.
    HardwareInitFailed,
}

/// # Console Struct
#[repr(C)]
#[derive(Debug)]
pub struct Console {
    _private: (),
}

// Global atomic flag to track console initialization status,
// prevents re-initialization and ensures safe access to the console output.
static CONSOLE_INITIALIZED: AtomicBool = AtomicBool::new(false);

impl Console {
    /// Initializes the console output system for the target hardware.
    ///
    /// # Safety
    ///
    /// This function is unsafe because it performs low-level hardware initialization
    /// that may have side effects on the system state. It should only be called once
    /// during the early boot sequence, and the caller must ensure that the hardware
    /// is in a valid state for console initialization.
    ///
    /// # Returns
    /// - `Ok(())` if the console was successfully initialized.
    /// - `Err(())` if the console was already initialized or if initialization failed.
    ///
    /// This function have only one exit point `status`.
    /// Returns must be checked to ensure that the console is ready for use.
    ///
    /// # Errors
    /// Return Erorr (ConsoleErrors) if the initialization is alredy done.
    #[inline]
    #[allow(unsafe_code)]
    #[must_use = "Initialization status should be checked to ensure console is ready for use."]
    pub unsafe fn init() -> Result<(), ConsoleErrors> {
        // Default return setted to `Err(())` to indicate failure unless initialization succeeds.
        let mut status = Err(ConsoleErrors::AlreadyInitialized);
        // Check if the console has already been initialized to prevent re-initialization.
        //
        // if the console is not initialized, perform the necessary hardware setup,
        // mark `CONSOLE_INITIALIZED` as true, and return `Ok(())`.
        if !CONSOLE_INITIALIZED.swap(true, Ordering::SeqCst) {
            #[cfg(feature = "rp2350")]
            {
                // SAFETY:
                // Required to call the external C FFI function `uart_init` provided by `rp2350-hazard3-hal`.
                let hw_res = unsafe { rp2350_hazard3_hal::uart::uart_init() };
                if hw_res != 0 {
                    // Reset atomic flag to false on hardware initialization failure
                    CONSOLE_INITIALIZED.store(false, Ordering::SeqCst);
                    status = Err(ConsoleErrors::HardwareInitFailed);
                } else {
                    status = Ok(());
                }
            }

            #[cfg(not(feature = "rp2350"))]
            {
                status = Ok(());
            }
        }
        status
    }

    /// Returns an instance of the `Console` struct if the console has been initialized.
    #[inline]
    pub fn get() -> Option<Self> {
        let mut status = None;
        if CONSOLE_INITIALIZED.load(Ordering::SeqCst) {
            status = Some(Console { _private: () });
        }
        status
    }

    /// Writes a single byte to the console output.
    #[inline]
    #[allow(unsafe_code)]
    pub fn write_byte(&self, #[allow(unused_variables)] b: u8) {
        #[cfg(feature = "rp2350")]
        // Safety:
        // Required to call the external C FFI function `uart_write_byte` provided by `rp2350-hazard3-hal`.
        unsafe {
            rp2350_hazard3_hal::uart::uart_write_byte(b);
        }
    }

    /// a
    pub fn write_str(&self, str: &str) {
        for b in str.bytes() {
            self.write_byte(b);
        }
    }
}

/// a
impl fmt::Write for Console {
    #[inline]
    fn write_str(&mut self, s: &str) -> fmt::Result {
        Console::write_str(self, s);
        Ok(())
    }
}

/// a
#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    if let Some(mut console) = Console::get() {
        let _ = console.write_fmt(args);
    }
}

/// a
#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => {
        $crate::console::_print(core::format_args!($($arg)*));
    };
}

/// a
#[macro_export]
macro_rules! println {
    () => {
        $crate::print!("\r\n")
    };
    ($($arg:tt)*) => {
        $crate::print!("{}\r\n", core::format_args!($($arg)*))
    };
}

/// a
#[macro_export]
macro_rules! eprint {
    ($($arg:tt)*) => {
        $crate::console::_print(core::format_args!($($arg)*));
    };
}

/// a
#[macro_export]
macro_rules! eprintln {
    () => {
        $crate::eprint!("\r\n")
    };
    ($($arg:tt)*) => {
        $crate::eprint!("{}\r\n", core::format_args!($($arg)*))
    };
}
