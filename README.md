# 68K Disassembler

## Description

This project implements an inverse assembler for the 68000 assembly language.
The disassembler takes in a range of addresses to scan in memory and converts
the memory image of instruction and data into the corresponding 68000 assembly
language.

The disassembler is designed to run on the Sim68K I/O console provided with the
[**`EASy68K`**](http://www.easy68k.com/) Editor/Assembler. It supports a subset
of opcodes and effective addressing modes, as listed below.

| **Opcode**                  |
|-----------------------------|
| NOP                         |
| MOVE, MOVEQ, MOVEA          |
| ADD, ADDA, ADDQ             |
| SUB                         |
| LEA                         |
| AND, OR, NOT                |
| LSL, LSR, ASL, ASR          |
| ROL, ROR                    |
| Bcc (BGT, BLE, BEQ)         |
| JSR, RTS                    |
| BRA                         |

| **Effective Addressing Modes**                   | **Format** | **Mode** | **Xn** |
|--------------------------------------------------|------------|----------|--------|
| Data Register Direct                             | `Dn`       | `000`    | `reg`  |
| Address Register Direct                          | `An`       | `001`    | `reg`  |
| Address Register Indirect                        | `(An)`     | `010`    | `reg`  |
| Address Register Indirect with Post incrementing | `(An)+`    | `011`    | `reg`  |
| Address Register Indirect with Pre decrementing  | `-(An)`    | `100`    | `reg`  |
| Absolute Word Address                            | `(xxx).W`  | `111`    | `000`  |
| Absolute Long Address                            | `(xxx).L`  | `111`    | `001`  |
| Immediate Data                                   | `#imm`     | `111`    | `100`  |

Upon startup, it prompts users for the starting and ending memory addresses in
hexadecimal format and facilitates navigation through the disassembled code
using the `ENTER` key. After completing the disassembly, the program prompts
users to either disassemble another memory image or quit.

The program gracefully handles illegal instructions (data) by displaying them as
`DATA $WXYZ`, where `$WXYZ` represents the undecodable data. 

```assembly
1000          DATA      $WXYZ
```

Address displacements or offsets are appropriately displayed in the disassembled
code as the absolute address value of the branch, not the branch displacement
value.

```assembly
1000          BRA       993         * branch to address 993
```

The disassembler provides a clear line-by-line disassembly. It's formatted to
show the memory location, opcode, and operand of each word it disassembles.

```assembly
a - memory location            b - opcode            c - operand
```

## Design Philosophy

The implementation of the disassembler follows a modular design philosophy,
with three main components:

### I/O Library

The I/O library manages input and output operations, encompassing tasks like
input validation, number conversions, and buffer preparation. To handle error
detection, rather than relying on a global flag and the associated complexities
of resetting its state during each decoding iteration, a more elegant solution
is utilized where subroutines return `-1` (defined globally as **`ERROR`**) to
indicate failure.

In this configuration, it is up to the caller to check the
subroutine's return value for errors after calling it and deal with that error
by incorporating additional logic or ignoring it (if it's not fatal).

### Opcode Library

The central task of the opcode library is to decode the opcode name and size info
and relay the relevant bits to the EA library for decoding the operands. It works
by extracting the first four bits from the current word being processed and
utilizing a jump table to get to the appropriate subroutine to decode the opcode
based on that bit pattern.

### EA Library

The EA library handles addressing mode decoding. When invoked from the opcode
library, the EA library processes the first 3 bits representing the register and
the subsequent three bits representing the mode. It employs a similar jump table
as the opcode library, this time indexing based on the mode bits.

The EA library returns the decoded addressing mode to the caller, which checks
against the valid set of addressing modes the current opcode supports before
continuing execution.
