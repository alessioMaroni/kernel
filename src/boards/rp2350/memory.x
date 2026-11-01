/* 
 * Copyright (c) 2026 The Kernel Project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 * If a copy of the MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/* 
 * ======================================================================
 * File: memory.x / rp2350_linker.ld
 * Target: RP2350 (Hazard3 RISC-V Core)
 * Description: Memory layout specification for the Raspberry Pi RP2350.
 *              Defines physical base addresses and region sizes for QSPI Flash,
 *              main SRAM, and Scratchpad RAM.
 * ======================================================================
 */

MEMORY
{
    /* 
     * External QSPI Flash Memory (XIP - eXecute In Place)
     * Permissions: (rx) -> Read-only for code execution and constants.
     * Address: 0x10000000 (Base address mapped by XIP controller)
     * Length:  2MB (Default allocation; adjustable up to 16MB based on flash chip)
     */
    FLASH   (rx)  : ORIGIN = 0x10000000, LENGTH = 2M

    /* 
     * Main System SRAM (SRAM0 to SRAM9 contiguous blocks)
     * Permissions: (rwx) -> Read, Write, Execute (Data, BSS, Heap, Stack)
     * Address: 0x20000000 (SRAM Base Address)
     * Length:  512KB (520KB total minus 8KB reserved Scratchpad)
     */
    RAM     (rwx) : ORIGIN = 0x20000000, LENGTH = 512K

    /* 
     * Scratchpad SRAM (SRAM Bank 8 & 9 top region)
     * Permissions: (rwx) -> High-speed core-local memory
     * Address: 0x2007E000 (Top 8KB of the 520KB total SRAM space)
     * Length:  8KB (Ideal for time-critical ISRs, DMA descriptors, or core-specific stacks)
     */
    SCRATCH (rwx) : ORIGIN = 0x2007E000, LENGTH = 8K
}