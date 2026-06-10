# Asynchronous FIFO Design in Verilog

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![FPGA](https://img.shields.io/badge/FPGA-Artix--7%20xc7a35t-orange)
![Tool](https://img.shields.io/badge/Tool-Vivado%202019.2-green)
![Tests](https://img.shields.io/badge/Tests-95%2F95%20Passing-brightgreen)
![Status](https://img.shields.io/badge/Status-Complete-success)

A fully verified, parameterized **Asynchronous FIFO** (First-In First-Out) buffer designed in Verilog RTL, supporting safe **Clock Domain Crossing (CDC)** using Gray-code pointers and 2-FF synchronizers. Synthesized and implemented on a Xilinx Artix-7 FPGA.

---

## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Parameters](#parameters)
- [Port Description](#port-description)
- [Design Details](#design-details)
- [Simulation Results](#simulation-results)
- [FPGA Resource Utilization](#fpga-resource-utilization)
- [How to Run](#how-to-run)

---

## Features

| Feature | Description |
|---|---|
| **Parameterized** | Configurable data width and FIFO depth |
| **CDC Safe** | Gray-code pointers + 2-FF synchronizers |
| **FULL / EMPTY flags** | Standard boundary detection |
| **Almost-Full flag** | Programmable threshold (default: 2 free slots) |
| **Almost-Empty flag** | Programmable threshold (default: 2 entries) |
| **Fill-level counter** | Real-time occupancy in both clock domains |
| **Overflow protection** | Write blocked when FULL |
| **Underflow protection** | Read blocked when EMPTY |
| **Runtime monitors** | Continuous overflow/underflow detection |

---

## Architecture

```
                    WRITE DOMAIN (10 MHz)          READ DOMAIN (50 MHz)
                   ┌─────────────────────────────────────────────────┐
  wr_data ────────►│                                                 │────► rd_data
  wr_en   ────────►│          FIFO Memory (16 x 8 bit)              │◄──── rd_en
  wr_clk  ────────►│           Dual-port SRAM                        │◄──── rd_clk
                   │                                                 │
  wr_rst_n ───────►│  ┌─────────────┐         ┌─────────────┐       │◄──── rd_rst_n
                   │  │Write Counter│         │Read Counter │       │
                   │  │Binary+Gray  │         │Binary+Gray  │       │
                   │  └──────┬──────┘         └──────┬──────┘       │
                   │         │ wptr(Gray)             │ rptr(Gray)   │
                   │         │                        │              │
                   │  ┌──────▼──────┐         ┌──────▼──────┐       │
                   │  │  2-FF Sync  │◄────────│  2-FF Sync  │       │
                   │  │(wr_clk)     │         │(rd_clk)     │       │
                   │  └──────┬──────┘         └──────┬──────┘       │
                   │         │ sync_rptr              │ sync_wptr    │
                   │         │                        │              │
                   │  ┌──────▼──────┐         ┌──────▼──────┐       │
                   │  │ FULL Logic  │         │ EMPTY Logic │       │
                   │  │ Almost-Full │         │ Almost-Empty│       │
                   │  │ Fill Count  │         │ Fill Count  │       │
                   │  └─────────────┘         └─────────────┘       │
                   └─────────────────────────────────────────────────┘
         full ◄───────┘                                   └──────────► empty
   almost_full ◄──┘                               almost_empty ──────► 
  wr_fill_count ◄─┘                               rd_fill_count ─────►
```

---

## File Structure

```
Async-FIFO-Design-Verilog/
├── README.md
├── rtl/
│   ├── async_fifo_top.v      # Top-level wrapper
│   ├── fifo_mem.v             # Dual-port SRAM memory
│   ├── wptr_full.v            # Write pointer + FULL + ALMOST_FULL
│   ├── rptr_empty.v           # Read pointer + EMPTY + ALMOST_EMPTY
│   └── sync_ptr.v             # 2-FF CDC synchronizer
├── tb/
│   └── tb_async_fifo.v        # Self-checking testbench (95 assertions)
├── constraints/
│   └── async_fifo.xdc         # Vivado timing constraints
└── docs/
    └── architecture.md        # Detailed design notes
```

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `DATASIZE` | 8 | Data bus width in bits |
| `ADDRSIZE` | 4 | Address width → depth = 2^ADDRSIZE = 16 |
| `ALMOST_FULL_THRESH` | 2 | Assert almost_full when free slots ≤ this value |
| `ALMOST_EMPTY_THRESH` | 2 | Assert almost_empty when fill level ≤ this value |

**Example instantiation:**
```verilog
async_fifo_top #(
    .DATASIZE           (8),
    .ADDRSIZE           (4),    // 16-deep FIFO
    .ALMOST_FULL_THRESH (4),    // almost_full when 4 or fewer slots free
    .ALMOST_EMPTY_THRESH(4)     // almost_empty when 4 or fewer entries
) u_fifo (
    .wr_clk        (wr_clk),
    .wr_rst_n      (wr_rst_n),
    .wr_en         (wr_en),
    .wr_data       (wr_data),
    .full          (full),
    .almost_full   (almost_full),
    .wr_fill_count (wr_fill_count),
    .rd_clk        (rd_clk),
    .rd_rst_n      (rd_rst_n),
    .rd_en         (rd_en),
    .rd_data       (rd_data),
    .empty         (empty),
    .almost_empty  (almost_empty),
    .rd_fill_count (rd_fill_count)
);
```

---

## Port Description

### Write Domain
| Port | Width | Direction | Description |
|---|---|---|---|
| `wr_clk` | 1 | Input | Write clock |
| `wr_rst_n` | 1 | Input | Active-low async reset |
| `wr_en` | 1 | Input | Write enable |
| `wr_data` | DATASIZE | Input | Write data |
| `full` | 1 | Output | FIFO full flag |
| `almost_full` | 1 | Output | Almost full flag |
| `wr_fill_count` | ADDRSIZE+1 | Output | Current fill level (write domain) |

### Read Domain
| Port | Width | Direction | Description |
|---|---|---|---|
| `rd_clk` | 1 | Input | Read clock |
| `rd_rst_n` | 1 | Input | Active-low async reset |
| `rd_en` | 1 | Input | Read enable |
| `rd_data` | DATASIZE | Output | Read data |
| `empty` | 1 | Output | FIFO empty flag |
| `almost_empty` | 1 | Output | Almost empty flag |
| `rd_fill_count` | ADDRSIZE+1 | Output | Current fill level (read domain) |

---

## Design Details

### Why Gray Code?
Binary counters change multiple bits simultaneously at rollover (e.g. `0111→1000`).
Sampling this mid-transition in another clock domain can produce corrupt values.
Gray code guarantees **only 1 bit changes per count**, so a sampled value is always
either the old or new count — never a corrupt intermediate.

### Why 2-FF Synchronizer?
The first flip-flop absorbs metastability. The second samples a resolved,
stable value. This is the industry-standard pattern for single-bit CDC crossings.

### FULL Detection (Write Domain)
```
full = (wgray_next == {~sync_rptr[MSB:MSB-1], sync_rptr[MSB-2:0]})
```
The write pointer has lapped the read pointer when the **top 2 bits differ**
and all lower bits match — indicating a full wrap-around difference.

### EMPTY Detection (Read Domain)
```
empty = (rgray_next == sync_wptr)
```
All bits match — the read pointer has caught up with the write pointer.

### Almost-Full / Almost-Empty
```
fill_count  = write_binary_ptr - synchronized_read_binary_ptr
free_slots  = DEPTH - fill_count
almost_full = (free_slots <= ALMOST_FULL_THRESH) && !full
almost_empty = (fill_count <= ALMOST_EMPTY_THRESH)
```
Gray-to-binary conversion is implemented using a generate block XOR tree.

---

## Simulation Results

### Test Summary — 95/95 Assertions Passed

| Test | Description | Result |
|---|---|---|
| 1 | Reset verification (EMPTY=1, FULL=0, AF=0, AE=1) | ✅ PASS |
| 2 | Write 8 values with read disabled | ✅ PASS |
| 3 | Read back 8 values — verify FIFO order | ✅ PASS |
| 4 | Fill FIFO to FULL | ✅ PASS |
| 5 | FULL protection — write pointer must not advance | ✅ PASS |
| 6 | Almost-full flag at threshold boundaries | ✅ PASS |
| 7 | Almost-empty flag at threshold boundaries | ✅ PASS |
| 8 | Fill-level counter accuracy (±1 CDC latency) | ✅ PASS |
| 9 | Simultaneous read + write stress | ✅ PASS |
| 10 | Stress fill and drain (16 entries) | ✅ PASS |
| 11 | Randomized data pattern (16 transactions) | ✅ PASS |
| 12 | Reset during active operation | ✅ PASS |

---

## FPGA Resource Utilization

**Target Device:** Xilinx Artix-7 `xc7a35tcpg236-1`  
**Tool:** Vivado 2019.2

| Resource | Used | Available | Utilization |
|---|---|---|---|
| Slice LUTs | ~55 | 20800 | ~0.3% |
| Flip-Flops | ~50 | 41600 | ~0.1% |
| Block RAMs | 0 | 50 | 0% |
| DSPs | 0 | 90 | 0% |
| GCLKs | 2 | 32 | 6% |

**Timing:** WNS = +6.489 ns (timing met with margin)

---

## How to Run

### Simulation (Icarus Verilog)
```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/Async-FIFO-Design-Verilog.git
cd Async-FIFO-Design-Verilog

# Compile
iverilog -g2012 -o sim_fifo \
  rtl/fifo_mem.v \
  rtl/sync_ptr.v \
  rtl/wptr_full.v \
  rtl/rptr_empty.v \
  rtl/async_fifo_top.v \
  tb/tb_async_fifo.v

# Run
vvp sim_fifo
```

Expected output:
```
RESULTS:  PASS=95   FAIL=0   TOTAL=95
*** ALL TESTS PASSED ***
```

### Vivado Simulation
1. Create new RTL project targeting `xc7a35tcpg236-1`
2. Add all files from `rtl/` as design sources
3. Add `tb/tb_async_fifo.v` as simulation source
4. Add `constraints/async_fifo.xdc` as constraint
5. Run Behavioral Simulation → type `run all` in Tcl Console

### Synthesis & Implementation
1. Run Synthesis → Run Implementation
2. In Tcl Console:
```tcl
open_run impl_1
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_bitstream -force "async_fifo_top.bit"
```

---

## Author

**Your Name**  
B.Tech Electronics & Telecommunication  
[LinkedIn](https://linkedin.com/in/yourprofile) | [GitHub](https://github.com/yourusername)

---

*This project is part of a digital design portfolio demonstrating RTL design, CDC techniques, and FPGA implementation skills.*
