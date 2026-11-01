/* 
 * Copyright (c) 2026 The Kernel Project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 * If a copy of the MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 *
 * NOTE:
 * The Picobin header structure below consists of hardware metadata 
 * specified by Raspberry Pi Ltd and is released into the Public Domain / CC0.
 */

/* 
 * ======================================================================
 * File: image.s
 * Target: RP2350 (Hazard3 RISC-V Core)
 * Description: RP2350 BootROM Picobin Header Block.
 *              Configures the BootROM to boot the Hazard3 RISC-V core in 
 *              Secure Machine Mode (M-Mode) at power-on.
 * ======================================================================
 */

.section .picobin_block, "a"
.global _picobin_block
.balign 32

.equ PICOBIN_BLOCK_MARKER_START, 0xffffded3
.equ PICOBIN_BLOCK_MARKER_END,   0xab123579

/* 
 * _picobin_block: Defines the Picobin header block for the RP2350 BootROM.
 *                 Contains metadata about the image, including type, flags,
 *                 entry point, and stack pointer.
 */
_picobin_block:
    .word PICOBIN_BLOCK_MARKER_START

    /* Item 1: IMAGE_TYPE (0x42) */
    .byte  0x42                          /* Type: Image definition */
    .byte  0x01                          /* Size: 1 word */
    .hword 0x1101                        /* Flags: RP2350 (0x1000) | RISC-V (0x0100) | EXE (0x0001) */

    /* Item 2: ENTRY_POINT (0x44) */
    .byte  0x44                          /* Type: Entry Point definition */
    .byte  0x03                          /* Size: 3 words */
    .hword 0x00                          /* 16-bit padding */
    .word  _start                        /* Initial PC address */
    .word  _stack_top                    /* Initial SP address (RAM) */

    /* Item 3: BLOCK_ITEM_LAST (0xff) */
    .byte  0xff                                             /* Type: LAST */
    .hword (_picobin_block_end - _picobin_block - 16) / 4   /* Dynamic size calculation */
    .byte  0x00                                             /* 8-bit padding */

    /* Link to next block */
    .word  0                             /* 0 = No next block (loop to self) */

    .word  PICOBIN_BLOCK_MARKER_END
_picobin_block_end:
.size _picobin_block, . - _picobin_block /* Define the size of the _picobin_block */