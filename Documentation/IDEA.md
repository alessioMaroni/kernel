# RSC-V Kernel Architecture & Safety Manifesto
> **Design Specification and Coding Guidelines for High-Reliability, Safety-Critical Bare-Metal Systems**  
> *Target Architecture: RISC-V* 
> *Standards Target:* DO-178C DAL A / NASA JPL Safety Critical Rules / SIL4

---

## 1. Project Overview

- **Project Name: Kernel**
- **Concept:** A ultra-deterministic, multi-language, safety-critical Real-Time Operating System (RTOS) kernel built for high-reliability aerospace and embedded application environments.
- **Primary Languages:**
  - **Rust (`no_std`)**: Core Kernel, Task Scheduler, IPC, Type-Safe Hardware Abstractions (~85%).
  - **Ada / SPARK 2012**: Formal Mathematical Verification & Mission-Critical Computations (~10%).
  - **C (MISRA C:2012/2025)**: Low-Level MMIO Hardware Drivers & HAL Interoperability (~4%).
  - **RISC-V Assembly (`rv32imac`)**: Chip Bootstrapping & Trap/Context-Switching Routines (~1%).

---

## 2. Core Architectural & Safety Principles

1. **Deterministic Safety over Simplicity:** Code correctness, predictability, and formal verification take absolute precedence over implementation speed or ease.
2. **Zero Runtime Dynamic Allocation:**
   - Dynamic memory allocation (`heap`) is strictly prohibited at runtime.
   - All buffers, stacks, and control blocks are statically allocated at compile-time or initialized via a single-pass bump allocator during boot setup before freezing.
3. **Compile-Time Computation:** Maximally leverage compile-time evaluations (`const fn`, generics, generics constraints) to eliminate runtime overhead and conditional branches.
4. **Bounded Execution:**
   - Every `loop`, `while`, or iterative construct MUST have a mathematically provable maximum iteration count (bounded execution time).
5. **Fault Detection, Isolation, and Recovery (FDIR):**
   - Every fault must be isolated to its local domain and recovered gracefully.
   - If a fault cannot be isolated or safely recovered, the kernel must execute a controlled panic, logging diagnostic state before entering a safe hardware state.
6. **SRAM Memory Scrubbing:** A background task continuously scans SRAM memory spaces to detect and correct single-bit flips (SEU mitigation).
7. **Traceability:** 100% bidirectional requirement traceability from architectural specification down to source code lines and tests.

---

## 3. Hardware Protection & Radiation Mitigation

### 3.1 Software Control Flow Integrity (CFI)
- **Flow Signature Tracking:** Critical multi-step functions update a tracking state variable (`FLOW_STATE`). Execution of critical hardware actions is allowed only if `FLOW_STATE` matches the expected sequence.
- **Redundant Guard Checks:** Critical hardware decisions must not rely on a single `if (condition)` check. Use redundant condition checks decoupled with compiler barriers (`core::sync::atomic::compiler_fence`).

### 3.2 Triple Modular Redundancy (TMR)
- Critical kernel state variables (e.g., system mode, panic flags) must be stored across three distinct memory addresses using a `TmrValue<T>` wrapper.
- Reads evaluate a majority-voting algorithm ($2/3$ agreement).

### 3.3 Stack Protection & High-Water Mark Diagnostics
- **MPU Protection & Canaries:** Stack bounds are enforced via MPU regions and stack canary patterns.
- **Stack Watermarking:** During kernel startup, stack regions are pattern-filled with `0xDEADBEEF`.
- **High-Water Mark Tracking:** Hardware-In-The-Loop (HIL) testing measures maximum stack consumption to mathematically validate assigned stack bounds.

### 3.4 Defense-in-Depth Boot Chain
- **Stage 1 (Assembly Bootloader):** Validates checksums/hashes of Ada and Rust image sections.
- **Stage 2 (SPARK Initialization):** Formally verifies initial memory states and safety invariants.
- **Stage 3 (Rust Core Takeover):** Configures MPU regions (setting code/config to Read-Only) before enabling global CPU interrupts.

---

## 4. Language-Specific Roles & Guidelines

### 4.1 Rust (`no_std`)
- **Formal Verification:** All core algorithms verified using **Kani Bounded Model Checker**.
- **Unsafe Code Isolation:**
  - `#![forbid(unsafe_code)]` declared in the primary kernel-core crate.
  - All `unsafe` blocks isolated inside dedicated micro-crates with explicit safety documentation (`// SAFETY:` comment required).
- **Type-State Pattern:** Peripheral lifecycle states (e.g., `Disabled` $\rightarrow$ `Configured` $\rightarrow$ `Enabled`) are enforced at compile-time via Rust types, making invalid hardware states unrepresentable.
- **Inline Assembly:** Restricted strictly to architectural registers (CSRs) and context switches.

### 4.2 Ada / SPARK 2012
- **Zero-Footprint Runtime (ZFR):** Custom bare-metal runtime targeting RISC-V (`rv32imac`).
- **Mathematical Proofs:** Every Ada procedure and function verified via `GNATprove` (SPARK Mode `On`) to prove Absence of Run-Time Errors (AORE).

### 4.3 C (MISRA C:2012)
- Restricted exclusively to hardware MMIO access and legacy driver bridging.
- Validated via static code analysis matching 100% MISRA C:2012 compliance.

### 4.4 Assembly (RISC-V)
- Limited strictly to `crt0.S` initial boot code and trap vector entry handlers.
- Succeeded by C or Rust implementations wherever feasible; every single instruction must be thoroughly commented.

### 4.5 Foreign Function Interface (FFI) Boundaries
- **No Raw Pointers:** Never pass raw pointers (`*mut`, `*const`) across language boundaries. Only scalar values (`u32`, `u64`), bounded types, or C-compatible structs (`#[repr(C)]`) are allowed.
- **Zero Panic Propagation:** Functions called over FFI must never raise an unhandled exception or trigger a Rust panic.

---

## 5. Real-Time Scheduler & Concurrency Architecture

- **Scheduling Policy:** Time-Triggered (Cyclic Executive) or Fixed-Priority Preemptive Scheduling (Rate Monotonic Scheduling).
- **Priority Inversion Protection:** All shared mutexes/semaphores MUST enforce the **Priority Ceiling Protocol (PCP)**.
- **Worst-Case Execution Time (WCET):**
  - Each task is assigned a strict WCET budget verified through compile-time analysis and HIL benchmarking.
  - Tasks exceeding their WCET trigger immediate FDIR intervention.
- **Interrupt Service Routines (ISRs):**
  - ISRs must be non-blocking and minimal.
  - ISRs clear hardware interrupt flags and delegate processing to worker tasks via IPC.

---

## 6. Inter-Process Communication (IPC)

- **Static Queues:** Message passing relies exclusively on statically allocated, lock-free SPSC/MPSC circular buffers.
- **Zero-Copy Architecture:** Data transfer occurs by ownership transfer or MPU-protected shared buffers.
- **Mandatory Deadlines:** All IPC blocking operations must include an explicit, non-infinite timeout parameter.

---

## 7. Timekeeping & Diagnostic Logging

- **Monotonic Hardware Timer:** Driven by the 64-bit RISC-V timer (`mtime` / `mtimecmp`).
- **Clock Fault Detection:** Continuous hardware validation of the primary crystal oscillator. Immediate fallback to the internal Ring Oscillator (ROSC) upon loss of signal.
- **Post-Mortem Crash Dump:**
  - Upon system panic, register states (`PC`, `SP`, `RA`), stack backtrace, and fault codes are committed to a non-volatile Retention SRAM / Flash Crash Sector.
  - Incident telemetry is broadcast upon system reboot.

---

## 8. Coding Standards & Code Quality Directives

### 8.1 Function Construction Rules
1. **Precondition Enforcement:** Every function must validate input preconditions before execution.
2. **Function Call Limit:** A function should directly delegate to no more than **3 sub-functions**.
3. **Single Responsibility Principle:** Functions performing multiple distinct operations must be decomposed into smaller atomic functions.

### 8.2 Formatting & Style
- **Line Length:** Maximum 100 characters per line.
- **Indentation:** Tabulations for indentations wider than 3 spaces.
- **Issue Tracking Tags:** All known bugs, technical debt, or safety-critical warnings must be registered in the central project issue log and tagged in code with unique IDs:
  - `@bug(ID)`
  - `@todo(ID)`
  - `@fixme(ID)`
  - `@secureme(ID)`

---

## 9. Verification, Testing & CI/CD Pipeline

- **Software-In-The-Loop (SIL):** Automated host test suite execution on x86_64 targets via QEMU simulation.
- **Hardware-In-The-Loop (HIL):** Automated hardware testing flashing onto physical RP2350 target chips upon every Pull Request (`probe-rs`).
- **Structural MC/DC Coverage:** 100% Modified Condition/Decision Coverage required for all critical codepaths.
- **Hermetic Toolchain:** Fully reproducible, pinned toolchain builds managed via Docker containerization and Nix flakes.
```

An official, fully formatted specification document (`kernel_safety_manifesto.md`) has been generated.

It consolidates all architectural criteria into standard software engineering sections, translated to English, including:
- Multi-language FFI boundary isolation.
- Embedded safety practices (TMR, CFI, Stack Watermarking).
- Real-time scheduling rules (PCP, WCET, bounded execution).
- Verification pipeline requirements (Kani, GNATprove, SIL/HIL testing).