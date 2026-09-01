# RTL Design & Verification — 14-Day Intensive Assignment

> **From Specification to Coverage Closure** — A complete RTL design and verification journey across 14 days

---

## 📋 Overview

This repository documents a comprehensive 14-day intensive assignment covering the complete RTL design and verification lifecycle. The project spans foundational concepts, RTL implementation, verification planning, coverage analysis, and final documentation. Three distinct digital designs were developed, specified, and verified:

| # | Design | Type | Key Feature |
|---|---|---|---|
| **1** | Overlapping 1011 Sequence Detector | Moore FSM | Detects overlapping pattern "1011" on serial input |
| **2** | Traffic Light Controller | Moore FSM with Timer | 4-state intersection controller with configurable durations |
| **3** | Synchronous FIFO | Parametrizable Buffer | `WIDTH=8`, `DEPTH=8` with count-based flags |

---

## 📁 Repository Structure

```text
├── rtl/                               # RTL Implementations
│   ├── and_gate.sv                    # Day 1: Basic AND gate
│   ├── seq_detect_1011.sv             # Day 4: Sequence detector
│   ├── traffic_light.sv               # Day 5: Traffic light controller
│   └── sync_fifo.sv                   # Day 6: Synchronous FIFO
│
├── docs/                              # Documentation
│   ├── Knowledge_Base.md              # Complete knowledge base (20+ entries)
│   ├── RTL_SV Essentials.pdf          # All 3 RTL specifications
│   ├── Experimental report.pdf        # Coverage model documentation
│
├── issues/
│   └── ISSUE_LOG.md                   # Complete issue tracking (10 bugs)
│
├── slides/
│   └── presentation.md                # Day 14: Final presentation
│
└── README.md                          # This file
```

---

## 🎯 The Three Designs

### 1. Overlapping 1011 Sequence Detector

**Module:** `seq_detect_1011`

A Moore finite state machine that detects the overlapping pattern "1011" on a serial data stream.

| Port | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst_n` | Input | Active-low asynchronous reset |
| `din` | Input | Serial data input |
| `detected` | Output | HIGH for one cycle when "1011" detected |

#### State Diagram

```text
┌────────────────────────────────────────────────────────┐
│                                                        │
│  ┌───────┐         0/0         ┌───────┐               │
│  │ IDLE  │────────────────────►│ IDLE  │               │
│  └───┬───┘                     └───────┘               │
│      │ 1/0                                             │
│      ▼                                                 │
│  ┌───────┐         0/0         ┌───────┐               │
│  │  S1   │────────────────────►│  S10  │               │
│  └───┬───┘         1/0         └───┬───┘               │
│      │                             │                   │
│      │ 1/0                         │ 1/0               │
│      │                             ▼                   │
│      └────────────────────────►┌───────┐               │
│                                │ S101  │               │
│                                └───┬───┘               │
│                                    │                   │
│                                    │ 1/1               │
│                                    ▼                   │
│                                ┌───────┐               │
│                                │  S4   │               │
│                                └───┬───┘               │
│                                    │                   │
│                                    │ 1/0               │
│                                    ▼                   │
│                                ┌───────┐               │
│                                │  S1   │               │
│                                └───────┘               │
└────────────────────────────────────────────────────────┘
```

#### Simulation Result

```text
Cycle: 50 | din=0 | State=S101 | detected=1    ← Detection 1
Cycle: 70 | din=1 | State=S101 | detected=1    ← Detection 2
```

---

### 2. Traffic Light Controller

**Module:** `traffic_light`

A 4-state traffic light controller for a four-way intersection with configurable durations.

| State | Duration (cycles) | Main Road Lights | Side Road Lights |
|---|---|---|---|
| `MAIN_GREEN` | 4 | 🟢 Green | 🔴 Red |
| `MAIN_YELLOW` | 2 | 🟡 Yellow | 🔴 Red |
| `SIDE_GREEN` | 6 | 🔴 Red | 🟢 Green |
| `SIDE_YELLOW` | 2 | 🔴 Red | 🟡 Yellow |

#### State Flow

```text
MAIN_GREEN ──(4 cycles)──► MAIN_YELLOW ──(2 cycles)──► SIDE_GREEN
     ▲                                                    │
     │                                                    │
     └────────────────────────────────────────────────────┘
                           (2 cycles)                     ▼
                 SIDE_YELLOW ◄────────────────────────────┘
```

---

### 3. Synchronous FIFO

**Module:** `sync_fifo`

A parametrizable first-in-first-out memory buffer with count-based flag generation.

#### Parameters

| Parameter | Default | Description |
|---|---|---|
| `WIDTH` | 8 | Data width in bits |
| `DEPTH` | 8 | Number of entries (must be power of 2) |

#### Ports

| Port | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst_n` | Input | Active-low asynchronous reset |
| `wr_en` | Input | Write enable |
| `rd_en` | Input | Read enable |
| `din` | Input | Data input |
| `dout` | Output | Data output |
| `full` | Output | Asserted when `count == DEPTH` |
| `empty` | Output | Asserted when `count == 0` |

#### Key Features

* Count-based full/empty flag generation (`full = (count == DEPTH)`)
* Simultaneous read and write support (`count` unchanged when both valid)
* Pointer wraparound for efficient memory utilization
* Blocking behavior: writes ignored when full, reads ignored when empty

#### Simulation Result

```text
Cycle: 95  | count=8 | full=1              ← FIFO Full
Cycle: 105 | wr=1    | count=8 | full=1    ← Write Blocked
Cycle: 185 | count=0 | empty=1             ← FIFO Empty
Cycle: 195 | rd=1    | count=0 | empty=1   ← Read Blocked
```

---

## 📊 Verification Planning

### Feature Refinement (12 FIFO Features)

| ID | Feature | Priority | Checker Type | Stimulus Type |
|---|---|---|---|---|
| **FIFO-01** | Valid Write | P0 | Scoreboard | Random |
| **FIFO-02** | Blocked Write When Full | P0 | Assertion + Directed | Directed |
| **FIFO-03** | Valid Read | P0 | Scoreboard | Random |
| **FIFO-04** | Blocked Read When Empty | P0 | Assertion + Directed | Directed |
| **FIFO-05** | Full Flag Assertion | P0 | Checker with Expected | Directed |
| **FIFO-06** | Full Flag De-assertion | P0 | Checker with Expected | Directed |
| **FIFO-07** | Empty Flag Assertion | P0 | Checker with Expected | Directed |
| **FIFO-08** | Empty Flag De-assertion | P0 | Checker with Expected | Directed |
| **FIFO-09** | Simultaneous Read & Write | P0 | Scoreboard | Constrained-Random |
| **FIFO-10** | Pointer Wraparound | P1 | Checker with Expected | Directed |
| **FIFO-11** | Data Order Preservation | P0 | Scoreboard | Random |
| **FIFO-12** | Reset Behavior | P0 | Checker with Expected | Directed |

### Corner Cases Identified

| Design | Corner Cases | Critical Ones |
|---|---|---|
| **Sequence Detector** | 7 | Continuous '1's, Overlapping patterns, Reset during sequence |
| **Traffic Light** | 7 | Reset in any state, Mutual exclusion, Counter overflow |
| **FIFO** | 10 | Simultaneous R&W when full/empty, Pointer wraparound, `DEPTH=1` |

---

## 🐛 Issue Log Summary

| Bug ID | Design | Issue | Status |
|---|---|---|---|
| **BUG-001** | Sequence Detector | Output delayed by one cycle | ✅ Fixed |
| **BUG-002** | Sequence Detector | Missing overlapping detection | ✅ Fixed |
| **BUG-003** | Traffic Light | Counter did not decrement | ✅ Fixed |
| **BUG-004** | Traffic Light | Lights not updating on transition | ✅ Fixed |
| **BUG-005** | FIFO | Full flag not asserting | ✅ Fixed |
| **BUG-006** | FIFO | Simultaneous R&W caused count decrement | ✅ Fixed |
| **INC-001** | Sequence Detector | Missing default output | ✅ Fixed |
| **INC-002** | Traffic Light | Debug function without synthesis guards | ✅ Fixed |
| **INC-003** | FIFO | Incomplete condition checks | ✅ Fixed |
| **INC-004** | FIFO | `dout` undefined for empty case | ✅ Fixed |
| **INC-005** | Traffic Light | Hardcoded counter width | ✅ Fixed |

---

## 📈 Coverage Model

### Sequence Detector Coverage

```systemverilog
// State Coverage
coverpoint current_state {
    bins idle  = {IDLE};
    bins s1    = {S1};
    bins s10   = {S10};
    bins s101  = {S101};
}

// Transition Coverage
coverpoint {current_state, din} {
    bins idle_to_idle  = {IDLE  -> IDLE};
    bins idle_to_s1    = {IDLE  -> S1};
    bins s1_to_s1      = {S1    -> S1};
    bins s1_to_s10     = {S1    -> S10};
    bins s10_to_idle   = {S10   -> IDLE};
    bins s10_to_s101   = {S10   -> S101};
    bins s101_to_s10   = {S101  -> S10};
    bins s101_to_idle  = {S101  -> IDLE};
}
```

### FIFO Count Coverage

```systemverilog
coverpoint count {
    bins empty         = {0};
    bins full          = {DEPTH};
    bins one            = {1};
    bins dep_minus_one = {DEPTH-1};
    bins mid           = {[1:DEPTH-1]};
}
```

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| **Modelsim** | For simulation and verification |
| **SystemVerilog** | RTL design and testbench development |
| **Git** | Version control and repository management |

---

## 📚 Key Learning Outcomes

### RTL Design
* ✅ Two-block FSM architecture (sequential + combinational separation)
* ✅ Synthesizable RTL coding practices
* ✅ Clock-domain awareness and reset handling
* ✅ Parameterization and configurable designs

### Verification
* ✅ Directed vs. random/constrained-random stimulus strategy
* ✅ Checker types: Assertions, Scoreboards, Checker with Expected
* ✅ Priority assignment (P0/P1/P2) for verification planning
* ✅ Coverage models: code coverage vs. functional coverage

### Documentation
* ✅ Complete RTL specifications (10 sections per design)
* ✅ Traceability matrix (Feature → Req-ID → Test → Coverage)
* ✅ Issue tracking and root cause analysis
* ✅ Knowledge base with 20+ entries

### Project Management
* ✅ 14-day structured assignment with clear daily objectives
* ✅ Cross-functional collaboration between RTL and DV teams
* ✅ Self-review and quality assurance processes

---

## 🚀 Getting Started

### Prerequisites

* EDA Playground account (or local simulator like Synopsys VCS, Mentor Questa)
* Basic understanding of SystemVerilog and digital design concepts

### Run Simulations

#### 1. Sequence Detector

```bash
# Compile
vlog rtl/seq_detect_1011.sv docs/experiments/seq_detect_smoke_log.sv

# Simulate
vsim work.seq_detect_1011_tb
run -all
```

#### 2. Traffic Light Controller

```bash
# Compile
vlog rtl/traffic_light.sv docs/experiments/traffic_light_smoke_log.sv

# Simulate
vsim work.traffic_light_tb
run -all
```

#### 3. Synchronous FIFO

```bash
# Compile
vlog rtl/sync_fifo.sv docs/experiments/sync_fifo_smoke_log.sv

# Simulate
vsim work.sync_fifo_tb
run -all
```

---

## 📊 Summary Statistics

| Metric | Value |
|---|---|
| **Total Days** | 14 |
| **RTL Modules Designed** | 3 |
| **Total RTL Lines** | ~350 |
| **Testbenches Written** | 3 |
| **Features Identified (FIFO)** | 12 |
| **Requirements (Req-IDs)** | 12 |
| **Corner Cases Identified** | 24 |
| **Bugs Found & Fixed** | 10 |
| **Coverage Items** | 18 |
| **Assertions Written** | 9 |
| **Knowledge Base Entries** | 20+ |
| **Documentation Pages** | 15+ |

---

## 🎓 Final Reflection

> *"The specification is not just documentation — it's a verification tool. Writing the spec after coding revealed inconsistencies I would never have found otherwise."*
> — **RTL Designer**

> *"Verification is not 'testing the code' — it's 'testing against the specification.' The specification is the source of truth, not the RTL implementation."*
> — **DV Engineer**

> *"Good documentation is not optional; it's the foundation of successful verification. Without a clear spec and traceability, you can't prove the design works."*
> — **Team Lead**

---

## 📝 License

This project is for educational purposes. All code and documentation are provided as reference material for RTL design and verification learning.

---

## 🙏 Acknowledgements

* **ASMICORE Semiconductor** for the assignment framework
* **EDA Playground** for providing accessible simulation environment
* **SystemVerilog and UVM communities** for extensive learning resources

---

📅 **Date:** October 2026  
👥 **Team:** DV & RTL Team  
🏢 **Organization:** ASMICORE Semiconductor
