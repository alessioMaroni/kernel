/* 
 * Copyright (c) 2026 The Kernel Project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 * If a copy of the MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/* 
 * ======================================================================= 
 *  FILE:        start.s
 *  TARGET:      RP2350 (Hazard3 RISC-V Core)
 *  DESCRIPTION: Early bootstrap entry point. Disables interrupts, initializes
 *               the stack pointer, clears the .bss segment, relocates the
 *               .data segment from Flash to RAM, and branches to _setup.
 * =======================================================================
 */

.include "image.s"

.section .text._start, "ax"
.global _start
.type _start, @function
.balign 4

/* 
 * _start: Hard entry point executed immediately after boot ROM execution.
 */
_start:
    .option arch, +zicsr    /* Enable Zicsr extension for CSR instructions */
    /* Disable Machine-level Interrupts (MIE bit 3 in mstatus) during bootstrap */
    csrc mstatus, 0x8

    .option push    /* Preserve existing assembler option state */
    .option norelax /* Disable linker relaxation to enforce exact absolute addressing for SP */

    /* Initialize the Stack Pointer (sp) to the top of the allocated RAM stack */
    la sp, _stack_top

    .option pop     /* Restore original assembler option state */

    /* 
     * ================================
     * 1: BSS Zero-Initialization Loop
     * ================================
     * Clears all uninitialized global and static variables in RAM.
     * Prevents undefined memory states and ensures atomic flags (e.g.,
     * CONSOLE_INITIALIZED) start deterministically at zero.
     */
    la t0, _sbss /* Load BSS section start address in RAM */
    la t1, _ebss /* Load BSS section end address in RAM */

1:
    /* Exit condition: If current pointer (t0) >= end pointer (t1), jump to label 2 */
    bgeu t0, t1, 2f
    /* Write 32-bit zero word to the current BSS address */
    sw zero, 0(t0)
    /* Advance pointer by 4 bytes (1 word) */
    addi t0, t0, 4
    /* Loop back to label 1 */
    j 1b

/* 
 * ====================================================
 * 2: Initialized Data Relocation (.data section copy)
 * ====================================================
 * Copies initialized global/static variables from non-volatile Flash (XIP)
 * source address (_sidata) to their target runtime destination in RAM (_sdata).
 */
2:
    la t0, _sidata /* Source address in Flash (Read-Only initialization image) */
    la t1, _sdata  /* Destination start address in RAM */
    la t2, _edata  /* Destination end address in RAM */

/* 
 * =========================================================
 * 3: Initialized Data Relocation Loop (.data section copy)
 * =========================================================
 * Iteratively copies 32-bit words of pre-initialized static/global variables
 * from non-volatile Flash storage into SRAM execution memory.
 */
3:
    /* Exit condition: If RAM destination pointer (t1) >= RAM end (t2), jump to label 4 */
    bgeu t1, t2, 4f
    /* Load a 32-bit word from Flash source (_sidata) */
    lw t3, 0(t0)
    /* Store the 32-bit word into RAM destination (_sdata) */
    sw t3, 0(t1)
    /* Advance Flash source pointer by 4 bytes */
    addi t0, t0, 4
    /* Advance RAM destination pointer by 4 bytes */
    addi t1, t1, 4
    /* Loop back to label 3 */
    j 3b

/* 
 * =======================================
 * 4: High-Level Kernel Setup Transition
 * ======================================
 * Jumps to the `_setup` function in Rust.
 */
4:
    jal _setup

/* 
 * ===========================
 * 5: Safe Fallback Park Loop
 * ===========================
 * Catches execution if `_setup` unexpectedly returns or diverges.
 * Places the processor into Wait For Interrupt (WFI) low-power state.
 */
5:
    wfi
    j 5b

.size _start, . - _start /* Compute and register symbol size for ELF symbol table */
