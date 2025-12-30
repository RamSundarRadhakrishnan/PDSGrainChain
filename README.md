# PDS GrainChain — Solidity Smart Contract Design for Improving Efficiency of Indian Public Distribution System

A Foundry-based Solidity project that models an end-to-end grain batch lifecycle for the Public Distribution System (PDS) using an auditable on-chain state machine. The system tracks **who handled a batch, when it moved, and under what approvals**, from procurement to retail/FPS delivery.

> **Goal:** Improve traceability, accountability, and tamper-resistance in PDS-style supply chains using smart contracts.

---

## What this project does

- Represents each grain lot as a **Batch** with a deterministic **lifecycle state** (`BatchState`).
- Enforces **role-based access control (RBAC)** so only authorized entities can perform actions.
- Persists process artifacts (procurement, inbound, release approvals, shipments) in **indexed mappings** keyed by `batchId`.
- Emits state transitions in a predictable sequence to enable **off-chain indexing and analytics**.

---

## Lifecycle (high-level)

The “happy-path” lifecycle implemented is:

`create --> procurement validate --> purchase --> dispatch to warehouse --> warehouse receive --> audit --> store --> release approvals --> ship --> downstream receipt/verify --> close`

Each transition:
- checks the caller’s role,
- validates the current batch state,
- writes the relevant record(s) to storage,
- updates `batches[batchId].state`.

---

## Architecture

This repo uses a **pseudo-modular mixin-style architecture**: responsibilities are split across multiple feature-focused contracts (separate files), and composed via inheritance into a single deployable top-level contract.

**Inheritance stack (composition order):**
`PDSState → PDSRoles → PDSBatches → PDSProcurement → PDSWarehouse → PDSAudit → PDSLogistics → PDSGrainChain`

---

## Contracts

- **`PDSState.sol`**  
  Defines enums, structs, and storage mappings (the on-chain data model).

- **`PDSRoles.sol`**  
  Implements RBAC: entity registry + modifiers (`onlyOwner`, `onlyRole`, etc.).

- **`PDSBatches.sol`**  
  Batch creation and initialization (`createBatch`).

- **`PDSProcurement.sol`**  
  Procurement validation + purchase commit for a batch.

- **`PDSWarehouse.sol`**  
  Dispatch to warehouse, warehouse receipt, and storage marking.

- **`PDSAudit.sol`**  
  Quality check and pass/fail branching.

- **`PDSLogistics.sol`**  
  Release request/approval flows + shipment dispatch/receipt/verification for downstream movement.

- **`PDSGrainChain.sol`**  
  Final deployable façade contract (composes everything).

---

## Repository layout

Typical Foundry structure:

- `src/` — Solidity contracts
- `test/` — Forge tests
- `script/` — Deployment / interaction scripts (if added)
- `foundry.toml` — Foundry configuration

---

## Getting started (Foundry)

### Prerequisites
- Foundry installed: `forge`, `cast`, `anvil`

If you don’t have it yet:
- Install using Foundry’s official installer (recommended by the Foundry team)

### Install dependencies (if applicable)
If you use `lib/` dependencies:
```bash
forge install
```

## Build
``` bash
forge build
```

## Run tests
``` bash
forge test -vvv
```

## Local Chain - Optional
``` bash
anvil
```

## Usage outline
- Owner registers entities (procurement, warehouse, auditor, distributor, FPS).
- Farmer creates a batch.
- Procurement validates and purchases the batch.
- Warehouse receives the inbound consignment.
- Auditor performs quality check (pass/fail).
- Release + Logistics move the batch downstream via request/approval/shipment steps.
- Batch is verified and closed.

## Prototype Notes
This is a research/academic prototype and may omit production-grade features such as:
- full economic incentives,
- dispute resolution / rollback mechanisms,
- formal verification,
- upgradeability patterns,
- privacy-preserving designs.

Please audit before any real-world deployment.

## License
This project is licensed under the MIT License (see LICENSE).

## Author
Ram Sundar Radhakrishnan