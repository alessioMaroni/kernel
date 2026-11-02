# Copyright (c) 2026 The Kernel Project
#
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at
# http://mozilla.org/MPL/2.0/.

TARGET := riscv32imac-unknown-none-elf
ELF    := target/$(TARGET)/debug/kernel

.PHONY: setup
setup:
	@echo "Setting up the project..."

# RP2350 Workflow
# TERMINAL 1:
# 	make rp2350-build rp2350-flash rp2350-openocd
# TERMINAL: 2
# 	make rp2350-gdb
.PHONY: rp2350-build
rp2350-build:
	@echo "Building for RP2350 board..."
	cargo build --target riscv32imac-unknown-none-elf --no-default-features --features rp2350

.PHONY:  rp2350-flash
rp2350-flash:
	@echo "Flashing to RP2350 board..."
	sudo picotool load -t elf $(ELF) -x

.PHONY: rp2350-openocd
rp2350-openocd:
	@echo "Starting OpenOCD for RP2350 board..."
	sudo openocd -f interface/cmsis-dap.cfg -c "adapter speed 5000" -f target/rp2350-riscv.cfg

.PHONY: rp2350-gdb
rp2350-gdb:
	@echo "Starting GDB for RP2350 board..."
	riscv64-elf-gdb $(ELF) \
		-ex "set pagination off" \
		-ex "target extended-remote :3333" \
		-ex "monitor reset halt" \
		-ex "load" \
		-ex "break _start" \
		-ex "continue"

.PHONY: rp2350-t1
rp2350-t1:
	@echo "Running RP2350 workflow: build, flash, openocd..."
	make rp2350-build
	make rp2350-flash
	sleep 2
	make rp2350-openocd

.PHONY: rp2350-t2
rp2350-t2:
	@echo "Running RP2350 workflow: gdb..."
	make rp2350-gdb

.PHONY: serial
serial:
	@echo "Starting serial monitor..."
	sudo picocom -b 9600 /dev/ttyACM0 --nolock
