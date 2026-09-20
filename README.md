# UART-16550A

A modular, synthesizable **UART 16550A-style controller** designed in **SystemVerilog**, with transmit/receive datapaths, FIFOs, baud-rate generation, programmable UART registers, interrupt handling, modem-control logic, simulation-based verification, and FPGA synthesis using Intel Quartus Prime.

## Overview

This project implements a UART controller at RTL level with a structure inspired by the classic 16550A programming model. The design is built as a collection of focused RTL blocks and then integrated into a single top-level module for simulation and synthesis.

The project was developed with an emphasis on:

- Modular RTL architecture
- Synthesizable SystemVerilog
- UART register/control behavior
- TX and RX serial datapaths
- FIFO buffering
- Line-status and modem-status reporting
- Interrupt generation and priority handling
- Self-checking simulation
- FPGA-oriented synthesis analysis

> **Project status:** RTL simulation and FPGA synthesis have been completed. The current RTL is functional for the scenarios covered by the testbench, while some synthesis warnings and a few areas of cleanup/refinement remain documented below.

## Key Features

### UART datapath

- 8-bit parallel data path
- Serial transmitter and receiver
- Programmable line-control configuration through the UART register interface
- Baud-rate generation using divisor registers
- RX error detection for parity and framing conditions
- Loopback control support

### FIFOs

- Dedicated transmit FIFO logic
- Dedicated receive FIFO logic
- FIFO control integrated with the UART datapath
- Receive-side error/status information handled as part of the UART data path

### UART register/control logic

The integrated design includes the main control/status registers used by the implemented 16550A-style interface:

- **DLL** — Divisor Latch Low
- **DLM** — Divisor Latch High
- **IER** — Interrupt Enable Register
- **IIR** — Interrupt Identification Register
- **FCR** — FIFO Control Register
- **LCR** — Line Control Register
- **MCR** — Modem Control Register
- **LSR** — Line Status Register
- **MSR** — Modem Status Register

The exact read/write behavior and reserved-bit handling are defined by the RTL implementation.

### Interrupt and modem control

- Line-status interrupt handling
- Modem-status change detection
- Interrupt priority encoding
- CTS-related modem event detection
- Modem control outputs including DTR/RTS and auxiliary outputs
- Loopback-related control paths

## RTL Architecture

The design is divided into dedicated RTL modules and then integrated by the top-level `all_mod` module.

```text
                         +----------------------+
                         |       all_mod        |
                         |    Top-Level UART    |
                         +----------+-----------+
                                    |
        +---------------------------+----------------------------+
        |             |             |             |              |
        v             v             v             v              v
   UART Registers   TX/FIFO      RX/FIFO      Modem Control   Interrupts
        |             |             |             |              |
        +-------------+-------------+-------------+--------------+
                                    |
                              Baud / Timing
                                    |
                             Serial TX / RX
```

### Main RTL blocks

| File | Role |
|---|---|
| `uart_types.sv` | Shared UART structure/type definitions and register-related types |
| `uart_top_rtl.sv` | Top-level UART integration (`all_mod`) |
| `uart_tx_rtl.sv` | UART transmitter datapath and TX control |
| `uart_rx_rtl.sv` | UART receiver datapath, timing, and RX error handling |
| `uart_reg_rtl.sv` | UART register interface and control/status registers |
| `fifo_rtl.sv` | FIFO implementation used by TX/RX paths |
| `uart_modem_rtl.sv` | Modem-control/status logic |
| `uart_interrupt.sv` | Interrupt generation and priority logic |

## Verification

The top-level SystemVerilog testbench exercises the integrated `all_mod` design and reports pass/fail status using test counters.

### Verified scenarios

| Test area | Verification coverage |
|---|---|
| Reset | Reset behavior and initial UART state |
| Divisor registers | DLL and DLM readback |
| Line control | LCR readback and configuration path |
| IER | Reserved-bit behavior and readback masking |
| MCR | Modem-control outputs and readback |
| MSR | Current modem status and delta-status behavior |
| RX data | Received data path with `0x55` test data |
| Parity | Odd-parity receive test and parity-error injection |
| Framing | Invalid stop-bit test and framing-error detection |
| RLS interrupt | Receive line-status interrupt path and IIR priority behavior |
| Modem status | CTS transition and modem-change detection |
| Interrupt priority | Priority handling between interrupt sources |

The verification environment is intended to check actual DUT behavior. Pass/fail results are generated by the testbench rather than being manually forced.

## Simulation

### Tools

- **SystemVerilog**
- **ModelSim**
- Intel/Altera-compatible RTL simulation flow

### Top-level testbench

The integrated testbench uses `all_mod` as the DUT and drives the UART through its register-style interface (`wr`, `rd`, `addr`, `din`, `dout`) together with the serial and modem signals.

The testbench also observes internal timing/control signals where needed for protocol-oriented verification.

### Typical ModelSim flow

Compile the SystemVerilog sources in dependency order, launch the top-level testbench, and run the complete test sequence:

```tcl
vlib work
vlog rtl/uart_types.sv \
     rtl/fifo_rtl.sv \
     rtl/uart_tx_rtl.sv \
     rtl/uart_rx_rtl.sv \
     rtl/uart_reg_rtl.sv \
     rtl/uart_modem_rtl.sv \
     rtl/uart_interrupt.sv \
     rtl/uart_top_rtl.sv \
     tb/all_mod_tb.sv

vsim work.all_mod_tb
run -all
```

> File ordering can be adjusted to match the exact compile setup used in your ModelSim project. The shared type/package file must be compiled before the modules that depend on it.

## FPGA Synthesis

The design has also been synthesized using **Intel Quartus Prime Lite 25.1** for a **Cyclone V 5CGXFC7C7F23C8** target.

### Latest recorded synthesis results

| Metric | Result |
|---|---:|
| Analysis & Synthesis | Successful |
| ALMs required | **385 / 56,480 (<1%)** |
| Clock constraint | **10.000 ns** |
| Synthesis errors | **0** |
| Synthesis warnings | **29** |

The current synthesis result demonstrates that the integrated RTL can be accepted by the FPGA synthesis flow. The warnings are documented below and are intentionally not hidden from the project status.

## Synthesis Notes / Known Limitations

The latest synthesis run reported several warnings that are still candidates for RTL cleanup:

- Some assigned signals such as `rx_data` and `lcr_temp` are not subsequently read.
- Quartus reports inferred latches for selected fields in `uart_reg_rtl`.
- Some TX/RX counter expressions generate truncation warnings.
- Unused upper bits of the IIR are optimized to constant values.
- Exact FPGA pin assignments have not been completed for the current top-level design.

These items do not prevent the current synthesis run from completing, but they should be addressed before calling the RTL production-clean.

## Timing Constraint

The synthesis project includes `all_mod.sdc` with a **10 ns clock period** constraint (100 MHz target clock period).

```tcl
create_clock -name clk -period 10.000 [get_ports clk]
```

The constraint establishes the intended timing target for analysis. A separate statement of final timing closure should only be made after reviewing the complete post-fit timing report.

## Project Structure

```text
UART-16550A/
├── implementation/
│   └── Synthesis reports, implementation evidence and related outputs
│
├── rtl/
│   ├── uart_types.sv
│   ├── uart_tx_rtl.sv
│   ├── uart_top_rtl.sv
│   ├── uart_rx_rtl.sv
│   ├── uart_reg_rtl.sv
│   ├── fifo_rtl.sv
│   ├── uart_modem_rtl.sv
│   └── uart_interrupt.sv
│
├── tb/
│   └── Top-level and supporting SystemVerilog testbench files
│
├── .gitignore
├── LICENSE
└── README.md
```

## Development Flow

The project follows this general RTL-to-implementation workflow:

```text
RTL Design
    ↓
Module-Level Development
    ↓
Top-Level Integration
    ↓
SystemVerilog Simulation
    ↓
Self-Checking Verification
    ↓
Quartus Analysis & Synthesis
    ↓
Resource / Timing Review
    ↓
Implementation Analysis
```

## Future Work

Planned refinement areas include:

- Remove remaining inferred-latch warnings
- Clean up unused RTL signals
- Resolve counter-width/truncation warnings
- Review and refine interrupt/modem behavior where required
- Complete FPGA pin assignments for hardware deployment
- Expand the verification suite with additional TX, RX, FIFO, and boundary-condition scenarios
- Continue physical-design exploration using an ASIC-compatible flow where appropriate

## What This Project Demonstrates

This project demonstrates practical experience with:

- SystemVerilog RTL design
- Finite-state-machine based control
- UART serial communication concepts
- FIFO design and integration
- Programmable register interfaces
- Interrupt architecture
- Error/status handling
- Modem-control signaling
- Self-checking simulation
- Quartus synthesis and resource analysis
- Reading and interpreting synthesis warnings and timing constraints

## License

This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

## Author

**Rushikesh Dandgawhal**

Electronics & Telecommunication Engineering  
RTL Design | Verilog/SystemVerilog | FPGA | Digital Design

GitHub: [Rushikesh-Dandgawhal](https://github.com/Rushikesh-Dandgawhal)

---

> This repository is an engineering project under active refinement. Verification and synthesis results are documented from the current development state so that the implementation status remains transparent.
