# 16-Bit RISC ALU with Memory-Mapped Architecture (FPGA)

## Overview

This project implements a 16-bit RISC-style Arithmetic Logic Unit (ALU) with a memory-mapped register file on a Xilinx Spartan-7 FPGA.  
The system supports arithmetic and logical operations using a 3-operand instruction format and communicates through a UART-based serial interface.

The design demonstrates structured RTL development, FSM-based control logic, synchronous memory handling, clock-domain synchronization, deterministic reset behavior, and real hardware validation.

---

## Hardware Platform

- FPGA: Xilinx Spartan-7  
- Clock Frequency: 100 MHz  
- UART Baud Rate: 9600  
- Memory: 1024 × 16-bit Register File (Block RAM inferred)  
- Display: Multiplexed 7-Segment Display  

---

## System Architecture

The design is modular and consists of:

### 1. ALU (Combinational Logic)
- 16-bit arithmetic and logical operations  
- Single-cycle execution  
- Generates status flags (Z, S, C, V)  

### 2. Control Unit (Finite State Machine)
- Parses UART commands  
- Manages register reads and writes  
- Handles ALU execution  
- Inserts wait states for synchronous BRAM latency  
- Controls UART transmission of results  
- Includes synchronous reset for deterministic startup  

### 3. Memory-Mapped Register File
- 1024 addressable 16-bit registers  
- Indexed using 10-bit address  
- Write-back architecture for 3-operand instructions  

### 4. UART Interface
- Custom UART RX and TX modules  
- Two-flip-flop synchronizer for asynchronous RX input (metastability mitigation)  
- Busy-controlled transmission handshake  

---

## Instruction Set

| Command | Operation | Format |
|----------|------------|--------|
| W | Write Register | `W <addr> <data>` |
| R | Read Register | `R <addr>` |
| S | Add | `S <addr1> <addr2> <dest>` |
| U | Subtract | `U <addr1> <addr2> <dest>` |
| N | AND | `N <addr1> <addr2> <dest>` |
| O | OR | `O <addr1> <addr2> <dest>` |
| X | XOR | `X <addr1> <addr2> <dest>` |
| T | NOT | `T <addr> <dest>` |

All arithmetic operations follow a 3-operand RISC format with explicit destination register.

---

## Status Flags

The ALU generates four flags:

- Z (Zero) – Result equals zero  
- S (Sign) – Most significant bit of result (two’s complement sign bit)  
- C (Carry) – Unsigned carry-out from MSB (two’s complement adder convention for subtraction)  
- V (Overflow) – Signed arithmetic overflow  

### Signed Overflow Detection

Addition overflow condition:

```verilog
(A[15] == B[15]) && (Result[15] != A[15])
```

Subtraction overflow condition:

```verilog
(A[15] != B[15]) && (Result[15] != A[15])
```

---

## Timing Considerations

FPGA Block RAM is synchronous:

- Address registered at clock cycle N  
- Data available at clock cycle N+1  

The FSM includes intermediate read states to prevent race conditions and ensure stable data before ALU execution.

---

## Example Hardware Validation

Test Input (via UART):

```text
W 0001 7FFF
W 0002 0001
S 0001 0002 0003
```

Output:

```text
d 8000 Z0 S1 C0 V1
```

This demonstrates correct signed overflow detection in two’s complement arithmetic.

---

## Repository Structure

```
/rtl
    alu.v
    top.v
    uart_rx.v
    uart_tx.v
    seven_seg.v

/constraints
    constraints.xdc

/docs
    block_diagram.png

README.md
```
## Hardware Output Screenshot

See docs/hardware_output.png
---

## Future Improvements

- Add Program Counter (PC)  
- Add Instruction RAM  
- Implement Branch instructions  
- Extend into full 16-bit microprocessor  
- Introduce pipeline stages  

---

## Skills Demonstrated

- RTL Design (Verilog HDL)  
- FSM Architecture  
- FPGA Block RAM Integration  
- Signed and Unsigned Arithmetic Logic  
- Clock Domain Synchronization  
- UART Protocol Implementation  
- Hardware Debugging and Validation  

---

## Conclusion

This project demonstrates a structured implementation of a RISC-style ALU architecture on FPGA with proper reset handling, metastability mitigation, and real hardware validation.
