# Simple Processor – Checkpoint 4
Name:Devon Sun
NetID: ys507

Design Summary
Implemented a 32-bit single-cycle processor supporting:
add, addi, sub, and, or, sll, sra, sw, lw

 Module Overview
- processor.v – main datapath and control
- regfile.v – 32×32 register file, $r0 fixed to 0
- alu.v – arithmetic/logic operations and overflow detection
- dmem.v – 4 K×32 single-port RAM
- imem.v – 4 K×32 ROM initialized from `imem.mif`
- skeleton.v – connects all modules and provides clocks
- dffe.v – edge-triggered flip-flop

Notes
- PC increments each cycle from 0  
- Overflow sets `$r30` to 1 (add), 2 (addi), or 3 (sub)  
- Tested using `basic_cp4_test.s` assembled to `imem.mif`
