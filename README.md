# APB UVM RAL Verification Environment

A professional, industry-grade **SystemVerilog UVM** functional verification environment for an **APB (Advanced Peripheral Bus) Register Bank**, featuring a fully integrated **Register Abstraction Layer (RAL)** model with frontdoor and backdoor access, functional coverage, and a self-checking scoreboard.

---

## Overview

This project implements a complete UVM-based verification environment targeting an APB peripheral register bank DUT. The environment is built around the **UVM Register Abstraction Layer (RAL)** — providing a structured, reusable approach to register-level verification that mirrors industry practice in SoC and IP verification teams.

Key verification goals:
- Verify correct **APB write and read transfers** across all registers
- Validate **reset values** for all registers via frontdoor access
- Exercise **backdoor (poke/peek)** access and mirror synchronization
- Confirm **RAL mirror consistency** using `mirror(UVM_CHECK)`
- Achieve **functional coverage** of register addresses, access types, and control field values

---

## Features

- **APB Protocol Compliance** — Driver and monitor implement the full APB SETUP → ACCESS phase handshake with clocking block discipline
- **UVM RAL Integration** — Full `uvm_reg_block` model with `uvm_reg_adapter` and `uvm_reg_predictor` for automatic mirror updates
- **Frontdoor & Backdoor Access** — All registers exercised via both `UVM_FRONTDOOR` and `UVM_BACKDOOR` paths
- **Self-Checking Scoreboard** — Reference model continuously compared against DUT read data; pass/fail summary at end of simulation
- **Functional Coverage** — Covergroups for register address × access-type cross-coverage and CNTRL field value bins
- **Modular Architecture** — Each verification component is independently encapsulated and reusable
- **Clean Compilation Order** — Package-based include structure ensures zero dependency issues
- **QuestaSim Automation** — Makefile and `.do` script for one-command compile-and-run workflows

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        apb_reg_test                         │
│  (Instantiates apb_env, creates and starts all sequences)   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                         apb_env                             │
│                                                             │
│  ┌──────────────────┐   ┌────────────┐   ┌───────────────┐ │
│  │    apb_agent     │   │apb_reg_block│  │apb_scoreboard │ │
│  │                  │   │  (RAL Model)│  │(ref model +   │ │
│  │  ┌────────────┐  │   │             │  │ checker)      │ │
│  │  │ apb_driver │  │   │ cntrl_reg   │  └───────────────┘ │
│  │  └────────────┘  │   │ reg1_reg    │                     │
│  │  ┌────────────┐  │   │ reg2_reg    │  ┌───────────────┐ │
│  │  │apb_monitor ├──┼───► reg3_reg    │  │ uvm_reg_      │ │
│  │  └────────────┘  │   │ reg4_reg    │  │ predictor     │ │
│  │  ┌────────────┐  │   └──────┬──────┘  └───────────────┘ │
│  │  │ sequencer  │  │          │                            │
│  │  └────────────┘  │   ┌──────▼──────┐                    │
│  └──────────────────┘   │apb_reg_     │                    │
│                          │adapter      │                    │
│                          └─────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   apb_if (APB Interface)                    │
│         driver_cb (active)  |  monitor_cb (passive)         │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│              apb_register_bank  (DUT)                       │
│   cntrl[3:0]  |  reg1[31:0]  |  reg2[31:0]                 │
│   reg3[31:0]  |  reg4[31:0]                                 │
└─────────────────────────────────────────────────────────────┘
```

### Component Descriptions

| Component | Role |
|---|---|
| `apb_register_bank` | RTL DUT — 5-register APB peripheral (cntrl + reg1–reg4) |
| `apb_if` | SystemVerilog interface with `driver_cb` and `monitor_cb` clocking blocks |
| `apb_transaction` | UVM sequence item carrying paddr, pwdata, prdata, pwrite |
| `apb_driver` | Active UVM driver; implements APB SETUP + ACCESS phase protocol |
| `apb_monitor` | Passive observer; captures completed APB transactions |
| `apb_agent` | Encapsulates driver, monitor, and sequencer |
| `apb_scoreboard` | Reference model comparison; reports PASS/FAIL per read |
| `apb_reg_block` | UVM RAL model; maps all 5 registers with addresses |
| `apb_reg_adapter` | Translates RAL `uvm_reg_bus_op` ↔ `apb_transaction` |
| `apb_env` | Top-level UVM environment; wires all components together |
| `apb_seq_lib` | Per-register sequences with frontdoor, backdoor, and mirror operations |
| `apb_reg_test` | Top-level UVM test; launches all register sequences |

---

## Directory Structure

```
apb-uvm-ral-verification-environment/
│
├── README.md
│
├── rtl/
│   └── apb_register_bank.sv        # DUT — APB 5-register peripheral
│
├── sim/
│   ├── run.do                      # QuestaSim .do simulation script
│   └── Makefile                    # Build automation (questa/vcs/xcelium)
│
└── tb/
    ├── agents/
    │   ├── apb_agent.sv            # UVM Agent
    │   ├── apb_driver.sv           # APB Protocol Driver
    │   ├── apb_monitor.sv          # APB Passive Monitor
    │   └── apb_transaction.sv      # Sequence Item
    │
    ├── env/
    │   └── apb_env.sv              # UVM Environment
    │
    ├── interfaces/
    │   └── apb_if.sv               # APB SystemVerilog Interface
    │
    ├── pkg/
    │   └── apb_pkg.sv              # UVM Package (compilation order)
    │
    ├── reg_model/
    │   ├── apb_reg_block.sv        # RAL Register Block + Covergroups
    │   └── apb_reg_adapter.sv      # RAL ↔ APB Bus Adapter
    │
    ├── scoreboard/
    │   └── apb_scoreboard.sv       # Self-checking reference model
    │
    ├── sequences/
    │   └── apb_seq_lib.sv          # Per-register RAL sequence library
    │
    ├── tests/
    │   └── apb_test.sv             # Top-level UVM test
    │
    └── tb_top.sv                   # Testbench top module
```

---

## Simulation Instructions

### Using the Makefile

All commands are run from the `sim/` directory.

```bash
cd sim/
```

| Command | Description |
|---|---|
| `make` | Compile all sources and run the default test |
| `make compile` | Compile only (no simulation) |
| `make run` | Run simulation (uses previous compile) |
| `make clean` | Remove all generated artifacts |
| `make help` | Print usage information |


### Using the .do Script Directly

```bash
cd sim/
vsim -do run.do
```

---

## Register Map

| Register | Address | Width | Access | Description |
|---|---|---|---|---|
| `cntrl` | `0x00` | 4-bit | RW | Control register (bits [3:0]) |
| `reg1` | `0x04` | 32-bit | RW | Data register 1 |
| `reg2` | `0x08` | 32-bit | RW | Data register 2 |
| `reg3` | `0x0C` | 32-bit | RW | Data register 3 |
| `reg4` | `0x10` | 32-bit | RW | Data register 4 |

All registers reset to `0x00000000`.

---

## Verification Plan

| Test Scenario | Method | Covered By |
|---|---|---|
| Reset value check | Frontdoor read after reset | `check_reset_value()` task |
| Write → Read back | Frontdoor write + frontdoor read | All `*_reg_seq` sequences |
| Backdoor write (poke) | `UVM_BACKDOOR` write + frontdoor verify | All `*_reg_seq` sequences |
| Backdoor read (peek) | `UVM_BACKDOOR` read | All `*_reg_seq` sequences |
| Mirror synchronization | `mirror(UVM_CHECK, UVM_FRONTDOOR)` | `reg1_reg_seq`, `reg4_reg_seq` |
| Randomized writes | `reg.randomize()` + `update()` | `reg2_reg_seq` |
| Walking 1s pattern | Loop write + read | `reg3_reg_seq` |
| Coverage sampling | `sample_reg_access()`, `sample_cntrl_value()` | All sequences |

---

## Tools Used

| Tool / Technology | Version / Standard |
|---|---|
| SystemVerilog | IEEE 1800-2017 |
| UVM | Universal Verification Methodology 1.2 |
| QuestaSim | 10.7+ |
| APB Protocol | AMBA APB Protocol Specification |

---

## Author

**Kareem S. Elhafi**

Digital IC Design & Verification Enthusiast
---
