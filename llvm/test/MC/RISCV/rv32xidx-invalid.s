# RUN: not llvm-mc -triple=riscv32 -mattr=+xidx %s 2>&1 | FileCheck %s

lbx a0, a1, a2, x, unscaled
# CHECK: :[[@LINE-1]]:1: error: instruction requires the following: RV64I Base Instruction Set{{$}}

sdx a0, a1, a2, sxtw, scaled
# CHECK: :[[@LINE-1]]:1: error: instruction requires the following: RV64I Base Instruction Set{{$}}
