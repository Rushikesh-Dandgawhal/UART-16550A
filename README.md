# UART-16550A

This is a **UART 16550A-style controller written in SystemVerilog**.

I built this project to understand how a UART works internally instead of treating it as a black box. The design started as individual RTL blocks and was gradually integrated into one top-level module, `all_mod`.

The project currently includes:

- UART TX and RX
- TX and RX FIFOs
- Baud-rate generation
- UART register interface
- Line-control configuration
- Interrupt generation
- Modem-control and modem-status logic
- Parity and framing-error detection
- SystemVerilog simulation
- Intel Quartus FPGA synthesis

> **Current status:** The major RTL functions covered by the verification suite are working in simulation, and the integrated design has completed Quartus Analysis & Synthesis. There are still some synthesis warnings and RTL cleanup items that I have documented instead of hiding.

---

## Why I Built This

I wanted to work on a project that was closer to a real RTL design than a small Verilog practice module.

The UART 16550A was a good fit because it combines several things that are important in RTL design:

- register-based control
- serial data transfer
- FIFOs
- state machines
- status/error detection
- interrupt logic
- modem-control signals

While building it, I also wanted to understand how the different blocks interact when they are integrated into one design.

---

## Design Overview

The top-level module is:

```text
all_mod
```

The design is split into separate RTL blocks.

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

### Main RTL Files

| File | What it does |
|---|---|
| `uart_types.sv` | Shared UART structures and register-related types |
| `uart_top_rtl.sv` | Top-level integration (`all_mod`) |
| `uart_tx_rtl.sv` | UART transmitter |
| `uart_rx_rtl.sv` | UART receiver and RX error detection |
| `uart_reg_rtl.sv` | UART register/control logic |
| `fifo_rtl.sv` | FIFO logic used by TX and RX |
| `uart_modem_rtl.sv` | Modem-control and modem-status logic |
| `uart_interrupt.sv` | Interrupt generation and priority logic |

---

## UART Registers

The current implementation includes the following registers:

| Register | Purpose |
|---|---|
| DLL | Divisor Latch Low |
| DLM | Divisor Latch High |
| IER | Interrupt Enable Register |
| IIR | Interrupt Identification Register |
| FCR | FIFO Control Register |
| LCR | Line Control Register |
| MCR | Modem Control Register |
| LSR | Line Status Register |
| MSR | Modem Status Register |

I also tested the register interface directly through the `wr`, `rd`, `addr`, `din`, and `dout` signals.

---

## Verification

I did not rely on one large testbench only.

After getting the integrated design working, I created separate testbenches for the important functions so that each part could be checked independently in ModelSim.

### Current Testbenches

```text
tb/
├── all_mod_tb.sv
├── reset_tb.sv
├── register_tb.sv
├── rx_parity_tb.sv
├── parity_error_tb.sv
├── framing_error_tb.sv
├── modem_status_tb.sv
└── interrupt_priority_tb.sv
```

### Tests Completed

| Testbench | What I checked | Result |
|---|---|---:|
| `reset_tb.sv` | Reset behavior and initial outputs | **9/9 PASS** |
| `register_tb.sv` | DLL, DLM, LCR, IER and MCR | **10/10 PASS** |
| `rx_parity_tb.sv` | Receive `0x55` with odd parity | **4/4 PASS** |
| `parity_error_tb.sv` | Wrong parity, RLS interrupt | **5/5 PASS** |
| `framing_error_tb.sv` | Bad stop bit / framing error | **Testbench created** |
| `modem_status_tb.sv` | MCR, MSR and CTS delta behavior | **9/9 PASS** |
| `interrupt_priority_tb.sv` | RLS interrupt priority | **4/4 PASS** |

The checks are generated from the actual DUT outputs. I am using the testbenches to drive the design and compare the resulting behavior rather than forcing internal signals just to obtain a passing result.

---

## Some of the Things I Tested

### RX with odd parity

I send `0x55` through the RX input with the expected odd-parity bit.

The receiver correctly produces:

```text
RX DATA = 0x55
```

and no parity or framing error is reported.

### Parity error

For the error test, I deliberately send the wrong parity bit.

The expected response is:

```text
r_pe = 1
IIR  = 06
IRQ  = 1
```

The simulation passes these checks.

### Framing error

For the framing test, the stop bit is intentionally driven low instead of high.

This is used to check the receiver's framing-error path and the corresponding RLS interrupt.

### Modem status

The modem-status test drives:

```text
CTS
DSR
RI
DCD
```

and checks the resulting MSR status and delta bits.

For the current implementation, the tested transition produces:

```text
MSR = FB
```

and after reading the MSR, the delta bits clear:

```text
MSR = F0
```

### Interrupt priority

The interrupt test enables multiple interrupt sources and verifies that the receiver line-status condition is identified with:

```text
IIR = 06
IRQ = 1
```

---

## Simulation

I use **ModelSim** for RTL simulation and waveform inspection.

A typical simulation looks like:

```tcl
vsim work.register_tb
run -all
```

The individual testbenches can be run separately depending on which part of the UART I want to verify.

The repository also contains waveform screenshots from the simulations in:

```text
waveform/
```

These are included mainly to make the verification easier to inspect instead of relying only on console output.

---

## FPGA Synthesis

After simulation, I synthesized the integrated design using:

**Intel Quartus Prime Lite 25.1**

Target device:

```text
Cyclone V
5CGXFC7C7F23C8
```

Latest recorded synthesis result:

| Item | Result |
|---|---:|
| Analysis & Synthesis | Successful |
| ALMs | **385 / 56,480** |
| Utilization | **< 1%** |
| Clock constraint | **10 ns** |
| Errors | **0** |
| Warnings | **29** |

The design synthesizes successfully, but I am not treating that as the end of the project.

---

## Synthesis Warnings

There are still some warnings that I want to clean up in future RTL revisions.

The current report includes warnings related to:

- unused signals such as `rx_data` and `lcr_temp`
- inferred latches in parts of `uart_reg_rtl`
- counter-width/truncation issues
- unused upper IIR bits being optimized
- missing exact FPGA pin assignments

I have left these documented because the purpose of the repository is to show the actual development state of the design, including things that still need improvement.

---

## Timing

The Quartus project uses:

```tcl
create_clock -name clk -period 10.000 [get_ports clk]
```

This sets a 10 ns clock period, corresponding to a 100 MHz target clock.

I have not described this as final timing closure because the complete post-fit timing results still need to be considered separately.

---

## Project Structure

```text
UART-16550A/
│
├── implementation/
│   └── Synthesis and implementation files
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
│   ├── all_mod_tb.sv
│   ├── reset_tb.sv
│   ├── register_tb.sv
│   ├── rx_parity_tb.sv
│   ├── parity_error_tb.sv
│   ├── framing_error_tb.sv
│   ├── modem_status_tb.sv
│   └── interrupt_priority_tb.sv
│
├── waveform/
│   └── ModelSim waveform screenshots
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## Development Flow

The way I approached the project was roughly:

```text
Understand UART / 16550A behavior
          ↓
Build individual RTL blocks
          ↓
Integrate the blocks
          ↓
Run ModelSim simulation
          ↓
Debug waveform behavior
          ↓
Create focused testbenches
          ↓
Verify the important paths
          ↓
Run Quartus synthesis
          ↓
Review resource usage and warnings
```

---

## What Is Still Left

There are still some things I want to improve rather than calling the project completely finished:

- clean up the remaining synthesis warnings
- review the inferred-latch cases
- clean up counter-width warnings
- expand TX/RX and FIFO boundary-condition testing
- complete FPGA pin assignments
- perform hardware testing when suitable FPGA hardware is available
- continue exploring an ASIC-compatible physical-design flow separately

---

## Tools

- SystemVerilog
- ModelSim
- Intel Quartus Prime Lite 25.1
- Git
- GitHub

---

## License

This project is licensed under the **MIT License**.

See [`LICENSE`](LICENSE) for details.

---

## Author

**Rushikesh Dandgawhal**

Electronics & Telecommunication Engineering

Interested in **RTL Design, Verilog/SystemVerilog, FPGA and VLSI Design**.

GitHub: [Rushikesh-Dandgawhal](https://github.com/Rushikesh-Dandgawhal)

---

> I built this project as a hands-on RTL exercise to understand UART architecture, verification and synthesis more deeply. The repository reflects the actual state of the design, including both the working parts and the areas I still plan to improve.
