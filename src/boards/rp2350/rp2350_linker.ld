/* 
 * Copyright (c) 2026 The Kernel Project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 * If a copy of the MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*
 * ===================================================
 * FILE: rp2350_linker.ld
 * TARGET: RP2350 (Hazard3 RISC-V Core)
 * DESCRIPTION: RP2350 linker file, contain stack
 *              and memory section definition
 * ===================================================
 */

/* 
 * RP2350 Risc-v Entry section
 * defined in `start.s`
*/
ENTRY(_start)

/* RP2350 Memory sections */
/* .include "memory.x" */

SECTIONS
{
    /* 
     * Section: .picobin
     * Memory:  FLASH (0x10000000)
     * Description: Contains the mandatory 32-byte RP2350 Picobin Header Block.
     *              The BootROM expects this block at the start of Flash to 
     *              determine the CPU architecture (RISC-V Hazard3 vs ARM Cortex-M33),
     *              security domain, initial entry point (_start), and stack pointer.
     */
    .picobin ORIGIN(FLASH) : {
        KEEP(*(.picobin_block))
    } > FLASH

    /* 
     * Section: .text
     * Memory:  FLASH
     * Description: Contains executable machine code and read-only data.
     */
    .text : {
        /*
         * Force the boot entry point (_start) at the beginning of .text.
         * KEEP prevents garbage collection (--gc-sections) from stripping it.
         */
        KEEP(*(.text._start))

        /* All remaining executable code sections from Rust / Assembly */
        *(.text .text.*)

        /* Read-only data (constants, string literals, lookup tables) */
        *(.rodata .rodata.*)

        /* Ensure .text section size is 4-byte aligned */
        . = ALIGN(4);
    } > FLASH

    /* 
     * Symbol: _sidata (Start of Initialized Data in Flash)
     * Retrieves the physical load memory address (LMA) of the .data section.
     * Used by start.s to know WHERE to copy initialized global variables FROM.
     */
    _sidata = LOADADDR(.data);

    /* 
     * Section: .data
     * VMA (Virtual Memory Address): RAM
     * LMA (Load Memory Address):    FLASH
     * Description: Stores global/static variables initialized with non-zero values.
     *              Stored permanently in Flash, copied to RAM at boot.
     */
    .data : {
        . = ALIGN(4);
        _sdata = .;         /* Marker: Start of .data in RAM (VMA) */
        
        *(.data .data.*)   /* All initialized global/static variable sections */
        
        . = ALIGN(4);
        _edata = .;         /* Marker: End of .data in RAM (VMA) */
    } > RAM AT > FLASH

    /* 
     * Section: .bss
     * Memory:  RAM
     * Description: Stores uninitialized or zero-initialized global/static variables.
     *              Occupies 0 bytes in Flash; zeroed out in RAM at boot by start.s.
     */
    .bss : {
        . = ALIGN(4);
        _sbss = .;          /* Marker: Start of .bss in RAM */
        
        *(.bss .bss.*)     /* Explicit zero-initialized variables */
        *(COMMON)           /* Uninitialized unallocated C/Assembly common symbols */
        
        . = ALIGN(4);
        _ebss = .;          /* Marker: End of .bss in RAM */
    } > RAM

    /* 
     * Section: .stack
     * Memory:  RAM
     * Attribute: (NOLOAD) -> Prevents allocation/initialization in Flash.
     * Description: Reserves an 8 KiB (8192 bytes) stack area in RAM.
     * Alignment: ALIGN(16) -> Mandatory 128-bit stack alignment for RISC-V ABI.
     */
    .stack (NOLOAD) : ALIGN(16) {
        _stack_bottom = .;  /* Lowest address of the stack */
        . += 8192;          /* Reserve 8 KiB space */
        _stack_top = .;     /* Initial Stack Pointer address (Stack grows downwards) */
    } > RAM
}