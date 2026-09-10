# Parameterized Pseudo-Noise (PN) Sequence Generator (LFSR) | Verilog

A Verilog implementation of a parameterized Pseudo-Noise (PN) sequence generator based on a Linear Feedback Shift Register (LFSR), designed, simulated, synthesized, and timing-analyzed in the Xilinx Vivado IDE. This document details the structural architecture, maximum-length polynomial tap feedback logic, timing constraint derivation, gate-level schematic netlist primitives, and hardware deployment on the Real Digital Boolean Board (`xc7s50csga324-1`).

---

## Table of Contents

* [What is a PN Sequence Generator?](#what-is-a-pn-sequence-generator)
* [LFSR Tap Configurations and Sequence Properties](#lfsr-tap-configurations-and-sequence-properties)
* [Detailed Architecture and Working Principle](#detailed-architecture-and-working-principle)
* [FPGA Synthesis and Primitive Netlist Analysis](#fpga-synthesis-and-primitive-netlist-analysis)
* [Timing Constraints and Slack Derivation](#timing-constraints-and-slack-derivation)
* [Testbench Output and Verification](#testbench-output-and-verification)
* [Running the Project in Vivado](#running-the-project-in-vivado)
* [Project Files](#project-files)

---

## What is a PN Sequence Generator?

A **Pseudo-Noise (PN) Sequence Generator** uses a Linear Feedback Shift Register (LFSR) to produce a deterministic, periodic sequence of binary digits that exhibits statistical randomness properties similar to white noise. LFSRs form essential building blocks in spread-spectrum communication systems (such as CDMA), stream ciphers, built-in self-test (BIST) logic, and digital channel estimation.

* **Inputs:**
* **`clk`** — System clock input (100 MHz target oscillator).
* **`rst`** — Active-high asynchronous reset signal.

* **Outputs:**
* **`pn_out`** — 1-bit serial Pseudo-Noise output taken from the final shift register stage ($N-1$).

* **Parameters:**
* **`N`** — Configurable shift register depth in bits (default: `N = 3`).

```text
               +---------------------------------------+
   clk =======>|                                       |
   rst =======>|          pn_generator #(N)            |===> pn_out
               |  (Linear Feedback Shift Register)     |
               +---------------------------------------+

```

---

## LFSR Tap Configurations and Sequence Properties

When configured with a feedback polynomial of degree $N$, a maximal-length LFSR generates an  $m$-sequence with a maximum repetition period of:

$$L = 2^N - 1\text{ clock cycles}$$

To prevent an all-zero lockup state, the shift register is initialized on reset to a non-zero seed value (`00...01`). The configurable feedback logic evaluates Galois/Fibonacci XOR taps based on stage depth $N$:

| Stage ($N$) | Primitive Polynomial | Selected Taps | Feedback Equation | Period ($L = 2^N - 1$) |
| --- | --- | --- | --- | --- |
| **`N = 3`** | $x^3 + x + 1$ | `[3, 1]` | `lfsr_reg[2] ^ lfsr_reg[0]` | $7\text{ cycles}$ |
| **`N = 4`** | $x^4 + x + 1$ | `[4, 1]` | `lfsr_reg[3] ^ lfsr_reg[0]` | $15\text{ cycles}$ |
| **`N = 5`** | $x^5 + x^2 + 1$ | `[5, 2]` | `lfsr_reg[4] ^ lfsr_reg[1]` | $31\text{ cycles}$ |
| **`N = 7`** | $x^7 + x + 1$ | `[7, 1]` | `lfsr_reg[6] ^ lfsr_reg[0]` | $127\text{ cycles}$ |

---

## Detailed Architecture and Working Principle

The `pn_generator` module is implemented as a synchronous right-shifting register driven by active-high asynchronous reset logic and combinational tap feedback computation.

```text
                  +-----------------------------------+
                  |      XOR Tap Logic (LUT2)         |
                  | feedback = lfsr[N-1] ^ lfsr[tap]  |
                  +-----------------+-----------------+
                                    |
                                 feedback
                                    |
                                    v
       +-------------------------------------------------------------+
       |                  Shift Register Datapath                    |
       |  lfsr_reg <= { lfsr_reg[N-2:0], feedback }  (Shift Right)   |
       +-------+--------------------+---------------------+----------+
               |                    |                     |
               v                    v                     v
         [lfsr_reg[0]]        [lfsr_reg[1]]  ...   [lfsr_reg[N-1]]
         (FDPE - Preset)     (FDCE - Clear)        (FDCE - Clear)
                                                          |
                                                          v
                                                       pn_out

```

### 1. Active-High Asynchronous Seed Reset

When `rst` is asserted high, the flip-flops bypass normal shift behavior and force the non-zero initial seed `{{(N-1){1'b0}}, 1'b1}` into `lfsr_reg`. This guarantees that least-significant bit `lfsr_reg[0]` is loaded with `1` while higher bits are cleared to `0`, avoiding zero-state lockup.

### 2. XOR Feedback Generation

Combinational logic continuously evaluates the XOR feedback value based on parameter `N`:

```verilog
assign feedback = 
    (N == 3) ? (lfsr_reg[2] ^ lfsr_reg[0]) :
    (N == 4) ? (lfsr_reg[3] ^ lfsr_reg[0]) :
    (N == 5) ? (lfsr_reg[4] ^ lfsr_reg[1]) :
    (N == 7) ? (lfsr_reg[6] ^ lfsr_reg[0]) :
               (lfsr_reg[N-1] ^ lfsr_reg[0]);

```

### 3. Sequential Shift Dynamics

On each rising clock edge (`posedge clk`), `feedback` is concatenated into bit position `0`, and the remaining register vector is shifted right:

```verilog
lfsr_reg <= {lfsr_reg[N-2:0], feedback};

```

---

## FPGA Synthesis and Primitive Netlist Analysis

Post-synthesis schematic generation in Vivado confirms low-level hardware mapping for $N=3$ target primitives:

* **Global Clock Buffering:** The incoming clock signal on port `clk` passes through input buffer `IBUF (clk_IBUF_inst)` and is routed onto the global low-skew clock network via `BUFG (clk_IBUF_BUFG_inst)`.
* **Combinational Tap Logic:** Feedback evaluation is synthesized into a single 2-input lookup table (`LUT2`), labeled `lfsr_reg[0]_i_1`, computing the XOR between `lfsr_reg[2]` and `lfsr_reg[0]`.
* **Flip-Flop Register Selection:**
* **`lfsr_reg_reg[0]` (FDPE):** Synthesized as a D Flip-Flop with Clock Enable and Asynchronous Preset (`FDPE`). On reset, `PRE` drives bit `0` high to enforce the non-zero seed.
* **`lfsr_reg_reg[1]` & `lfsr_reg_reg[2]` (FDCE):** Synthesized as D Flip-Flops with Clock Enable and Asynchronous Clear (`FDCE`). On reset, `CLR` forces upper bits low.

* **Output Buffering:** The final stage register output `lfsr_reg[2]` drives external pin `pn_out` through output buffer `OBUF (pn_out_OBUF_inst)`.

---

## Timing Constraints and Slack Derivation

The design is constrained using the Xilinx Design Constraints file (`dc_pbl_constraint_file.xdc`) targeting a 100 MHz oscillator period ($T_{\text{clk}} = 10.000\text{ ns}$) on pin `L16`:

```xdc
set_property PACKAGE_PIN L16 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

set_property PACKAGE_PIN R12 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

set_property PACKAGE_PIN P14 [get_ports pn_out]
set_property IOSTANDARD LVCMOS33 [get_ports pn_out]

```

### Implementation Timing Summary Results

Timing analysis run on the Spartan-7 (`xc7s50csga324-1`) FPGA demonstrates zero failing timing endpoints across all metrics:

* **Worst Negative Slack (WNS):** `+8.744 ns` (Passed)
* **Worst Hold Slack (WHS):** `+0.142 ns` (Passed)
* **Worst Pulse Width Slack (WPWS):** `+4.500 ns` (Passed)
* **Total Negative Slack (TNS):** `0.000 ns`
* **Failing Endpoints:** `0` out of `3` Setup/Hold endpoints and `4` Pulse Width endpoints.

### Maximum Operating Frequency Calculation

Using the positive setup slack ($WNS = 8.744\text{ ns}$) under a $10.000\text{ ns}$ target clock period, the maximum propagation delay across the critical path ($T_{\mathrm{prop,max}}$) is:

$$T_{\mathrm{prop,max}} = T_{\mathrm{clk}} - \mathrm{WNS} = 10.000\text{ ns} - 8.744\text{ ns} = 1.256\text{ ns}$$

$$F_{\mathrm{max}} = \frac{1}{T_{\mathrm{prop,max}}} = \frac{1}{1.256\text{ ns}} \approx 796.18\text{ MHz}$$

This high performance potential stems from the low logic depth between LFSR register stages (a single `LUT2` propagation delay).

---

## Testbench Output and Verification

The self-checking testbench (`pn_sequence_generator_tb.v`) verifies concurrently instantiated generator modules configured for $N = 3, 4, 5, 7$.

### Simulation Waveform Analysis

Behavioral simulation traces confirm expected sequence generation across all configuration parameters:

1. **Reset Phase ($0\text{ ns} \rightarrow 20\text{ ns}$):** Signal `rst` is asserted high. All LFSR outputs initialize immediately to `0` (driven by `lfsr_reg[N-1]`).
2. **Execution Phase ($t > 20\text{ ns}$):** `rst` drops low. On the subsequent rising clock edge, the LFSRs begin pseudo-random sequence iteration.
3. **Periodicity Verification ($N=3$):** Output `pn_out_3_stage` yields a repeating sequence of length $7$ clock cycles ($70\text{ ns}$ period):

$$\text{Pattern: } [0, 0, 1, 1, 1, 0, 1] \implies \text{Repeats every } 7\text{ clock cycles}$$

---

## Running the Project in Vivado

Follow these steps to set up, simulate, synthesize, and generate a bitstream in Xilinx Vivado:

### 1. Launch Vivado & Create Project

1. Open Vivado IDE and click **Create Project** $\rightarrow$ **RTL Project**.
2. Set target FPGA device to **Spartan-7 `xc7s50csga324-1**` (Real Digital Boolean Board).

### 2. Import Source Files

1. Add Design Source: `pn_sequence_generator.v`.
2. Add Simulation Source: `pn_sequence_generator_tb.v`.
3. Add Constraints File: `dc_pbl_constraint_file.xdc`.

### 3. Run Behavioral & Post-Synthesis Simulation

1. Navigate to **Flow Navigator** $\rightarrow$ **Simulation** $\rightarrow$ **Run Behavioral Simulation**.
2. Inspect `pn_out_3_stage`, `pn_out_4_stage`, `pn_out_5_stage`, and `pn_out_7_stage` waveforms to verify repetition periods.

### 4. Synthesize & Implement

1. Set `pn_generator` as top module for synthesis.
2. Click **Run Synthesis** $\rightarrow$ Open Synthesized Design to inspect netlist primitives (`FDPE`, `FDCE`, `LUT2`).
3. Click **Run Implementation** to verify timing slack ($WNS = +8.744\text{ ns}$).
4. Click **Generate Bitstream** to program hardware via micro-USB.

---

## Project Files

* **`pn_sequence_generator.v`** — Top RTL design file implementing the parameterized LFSR and XOR tap logic.
* **`pn_sequence_generator_tb.v`** — Multi-instance testbench validating $N=3, 4, 5, 7$ sequence lengths.
* **`dc_pbl_constraint_file.xdc`** — Xilinx Design Constraints mapping clock, reset, and output pins on the Real Digital Boolean Board.
