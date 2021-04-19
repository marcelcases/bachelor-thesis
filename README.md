# Implementation and verification of a hardware-based controller for a three-phase induction motor on an FPGA

## Abstract

The aim of this thesis is to study the main techniques of motor control in order to implement and design a hardware-based controller for a three-phase induction motor, developed in VHDL language and running on an Artix-7 FPGA (Xilinx). This controller is based on variable-frequency drive techniques. The modules that define this controller's hardware description run concurrently to each other, and they allow the motor to have a better time response and they also improve its performance compared to a microcontroller. This thesis is related to digital systems, power electronics and control systems.

## Contents

```
1 Introduction . . . . . . . . . . . . . . . . . . 2
2 Motivation . . . . . . . . . . . . . . . . . . . 4
3 Variable-frequency Drive . . . . . . . . . . . . 6
4 Field Oriented Control . . . . . . . . . . . . . 9
5 Direct Torque Control. . . . . . . . . . . . .  16
6 Field Programmable Gate Arrays . . . . . . . .  19
7 Inverter and motor . . . . . . . . . . . . . .  24
8 Implementation and Verifcation of a
        scalar VFD on an FPGA with VHDL. . . . .  28
9 Simulation and Verifcation of a
        vector FOC on an FPGA with VHDL. . . . .  37
10 Conclusion. . . . . . . . . . . . . . . . . .  40
11 Future work . . . . . . . . . . . . . . . . .  41
```

**Publication to UPC's institutional repository**  
[upcommons.upc.edu/handle/2117/134233](http://hdl.handle.net/2117/134233)

**Check out the document**  
[Open PDF](https://upcommons.upc.edu/bitstream/handle/2117/134233/master.pdf)

**Check the source code**  
On [GitHub](https://github.com/marcelcases/bachelor-thesis)

## Code

In this repo you can check out the code that was described for the thesis.

Structure:
* codi/FOC -> Field Oriented Control method source files (independent project)
  * Constraints (for Basys3 board)
  * Simulation (TestBench)
  * Sources/new (modules for each process of the control flow)
* codi/VFD -> Variable Frequency Drive method source files (independent project)
  * Constraints
  * Simulation
  * Sources/new
* Other (ROMs, guides, ...)

The project is written in VHDL using Xilinx Vivado® Design Suite and runs on an Artix7-Basys3 FPGA.

*Tallinn - Barcelona - Manresa*  
*March 2019*
