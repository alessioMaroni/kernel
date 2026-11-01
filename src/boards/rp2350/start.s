/* 
 * Copyright (c) 2026 The Kernel Project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 * If a copy of the MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/* 
 * ======================================================================= 
 *  FILE:   start.s
 *  TARGET: RP2350 (Hazard3 RISC-V Core)
 *  DESCRIPTION: Sets the stack pointer (sp) to the top of the stack
 *               defined in the linker script and branches to _setup.
 * =======================================================================
 */

.include "image.s"

.section .text._start, "ax"
.global _start
.type _start, @function
.balign 4

/* 
 * _start: Entry point of the kernel.
 *         Sets the stack pointer (sp) to the top of the stack defined in the linker script.
 *         Then jumps to the _setup function of the kernel.
 *         If _setup returns, enters an infinite loop with WFI (Wait For Interrupt).
 */
_start:
    .option push    /* Save current option configuration */
    .option norelax /* Temporarily disable linker relaxation to ensure correct stack pointer setup */

    /* Set the stack pointer (sp) to the stack top defined in the linker script */
    la sp, _stack_top

    /* Restore the original option configuration */
    .option pop

    /* Jump to the _setup function of the kernel */
    jal _setup

/* 
 * Infinite loop with WFI (Wait For Interrupt)
 */
1:
    wfi /* Wait for interrupt to reduce power consumption while idle */
    j 1b

.size _start, . - _start /* Define the size of the _start function */