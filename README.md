# Joecoin

Joecoin is a simple fungible token implemented as a [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-lang) smart contract and managed with the [Clarinet](https://docs.hiro.so/clarinet/overview) development toolchain.

This repository contains a Clarinet project that defines the `joecoin` token contract and provides a local development and testing environment.

---

## Project structure

- `README.md` – this documentation file
- `LICENSE` – project license
- `joecoin-contract/` – Clarinet project root
  - `Clarinet.toml` – Clarinet configuration
  - `contracts/joecoin.clar` – Joecoin token smart contract
  - `tests/joecoin.test.ts` – placeholder for unit tests
  - `settings/` – network configuration files (Devnet/Testnet/Mainnet)

---

## Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet/how-to-guides/how-to-set-up-local-development-environment)
  - This project was initialized with `clarinet 3.10.0`.
- A recent version of Node.js (optional, for running TypeScript tests via `npm`).

To verify that Clarinet is installed:

```bash
clarinet --version
```

---

## Getting started

Clone this repository and change into the project directory (if you have not already):

```bash
cd /home/anthony/Documents/GitHub/joecoin
```

Change into the Clarinet project subdirectory:

```bash
cd joecoin-contract
```

### Check the contract

Run Clarinet's static checks for all contracts in the project:

```bash
clarinet check
```

### Open a Clarinet console (REPL)

You can interact with the contract in a local REPL:

```bash
clarinet console
```

From the console, you can call public and read-only functions, for example:

```bash
(contract-call? .joecoin init u1000000)
(contract-call? .joecoin transfer u100 tx-sender 'ST123...RECIPIENT)
(clarity-get-balance .joecoin 'ST123...ADDRESS)
```

---

## Joecoin contract overview

The `joecoin` contract lives at `joecoin-contract/contracts/joecoin.clar` and implements a basic fungible token with an owner-controlled mint function.

### State

- `total-supply (uint)` – total number of tokens in existence.
- `initialized (bool)` – whether the token has been initialized.
- `token-owner (principal)` – address allowed to mint new tokens after initialization.
- `balances (map principal -> uint)` – per-account token balances.

### Public functions

- `init (initial-supply uint) -> (response bool uint)`
  - Can be called exactly once.
  - Sets `tx-sender` as `token-owner`.
  - Mints `initial-supply` tokens to `tx-sender` and marks the token as initialized.

- `mint (amount uint, recipient principal) -> (response bool uint)`
  - Requires the contract to be initialized.
  - Only `token-owner` may call this function.
  - Increases `total-supply` by `amount` and credits `recipient`.

- `transfer (amount uint, sender principal, recipient principal) -> (response bool uint)`
  - Requires the contract to be initialized.
  - `tx-sender` must be equal to `sender`.
  - Moves `amount` tokens from `sender` to `recipient` if `sender` has sufficient balance.

### Read-only functions

- `get-name () -> (response (string-ascii 32) uint)`
- `get-symbol () -> (response (string-ascii 32) uint)`
- `get-decimals () -> (response uint uint)`
- `get-total-supply () -> (response uint uint)`
- `get-balance-of (who principal) -> (response uint uint)`

These functions expose standard metadata and balance information for clients and tools.

### Error codes

- `u100` – insufficient balance
- `u101` – amount is zero
- `u102` – token already initialized
- `u103` – token not initialized
- `u104` – unauthorized (caller is not allowed to perform the operation)

---

## Running tests (optional)

The Clarinet template includes a TypeScript test harness under `joecoin-contract/tests/`.

From the Clarinet project directory:

```bash
cd joecoin-contract
npm install
npm test
```

This will run the Vitest test suite against your contracts. You can extend `tests/joecoin.test.ts` with custom tests for the Joecoin token behavior.

---

## Next steps

- Extend the contract with additional functionality (e.g. allowances, burning, or administrative controls).
- Write comprehensive tests in `tests/joecoin.test.ts` to cover initialization, minting, transfers, and failure scenarios.
- Deploy the contract to a Stacks testnet or devnet using Clarinet's deployment tooling when you are ready.
