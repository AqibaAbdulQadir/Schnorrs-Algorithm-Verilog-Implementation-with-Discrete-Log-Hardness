# Schnorr's Algorithm Verilog Implementation with Discrete Log Hardness
A Verilog implementation of Schnorr's digital signature scheme with discrete log hardness.

## Overview

This project implements the Schnorr's digital signature scheme with Key Generation, Signature Generation, and Signature Verification modules. It also includes testbenches to verify signatures. 

Currently, the project is in progress and focuses on functional correctness and architectural clarity,
serving as a reference hardware implementation rather than a fully optimized production design.

## Design Choices
The design emphasizes modularity and readability, with separate modules for
finite field arithmetic, scalar multiplication, hashing, and control logic.
The design is parameterised for different key lengths.
To simplify verification and debugging, resource sharing and aggressive pipelining
were not fully explored in this version. As a result, some arithmetic units are instantiated
independently rather than being time-multiplexed.

## Directory Structure
.
├── src/                      # Verilog source files
│   ├── schnorr.v             # Top-level Schnorr signature module
│   ├── key_gen.v             # Key generation logic
│   ├── sign_gen.v            # Schnorr signature generation
│   ├── sign_ver.v            # Schnorr signature verification
│   ├── prng.v                # Pseudo-random number generator
│   ├── lfsr.v                # LFSR-based entropy source
│   ├── mod_add.v             # Modular addition
│   ├── mod_mul.v             # Modular multiplication
│   ├── mod_exp.v             # Modular exponentiation
│   └── parameters.vh         # Global cryptographic parameters
│
├── sim/                      # Simulation and verification
│   ├── tb_mod_arith.v        # Testbench for modular arithmetic units
│   ├── tb_prng.v             # Testbench for PRNG
│   └── tb_schnorr.v          # End-to-end Schnorr testbench

## Module Overview

### schnorr.v
Top-level module coordinating key generation, signature generation,
and verification according to the Schnorr digital signature scheme.

### key_gen.v
Implements Schnorr private and public key generation using modular
exponentiation over predefined parameters.

### sign_gen.v
Generates Schnorr signatures by computing the commitment, challenge,
and response values.

### sign_ver.v
Verifies Schnorr signatures by recomputing and validating the challenge
against the received signature.

### prng.v
Pseudo-random number generator used for nonce generation during signing.

### lfsr.v
LFSR-based entropy source used within the PRNG module.

### mod_add.v
Performs modular addition over the defined finite field.

### mod_mul.v
Implements modular multiplication. This module is functionally correct
but not aggressively optimized for area or latency.

### mod_exp.v
Implements modular exponentiation, forming the computational core of
key generation and signature operations.

### parameters.vh
Defines global parameters such as key length, p, q and g.

## Cryptographic Parameters

The implementation defines global cryptographic constants in `parameters.vh`
that are used across all modules.

| Parameter | Description |
|---------|-------------|
| LEN     | Bit-width of arithmetic operations |
| p       | Prime modulus |
| g       | Generator of the multiplicative group modulo p |
| q       | Group order |

## Limitations and Future Work
- The current implementation is not optimized for minimal resource utilization.
- The design does not currently exploit pipelining or resource sharing techniques.

Future work includes:
- Pipelining critical paths to improve throughput
- Optimizing modular arithmetic using Montgomery multiplication
- Reducing control overhead using FSM minimization

