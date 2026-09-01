# RUN: not llvm-mc -triple=riscv64 -mattr=+xidx %s 2>&1 | FileCheck %s

lbx a0, a1, a2, invalid, scaled
# CHECK: :[[@LINE-1]]:17: error: operand must be one of 'x', 'uxtw', or 'sxtw'

lhx a0, a1, a2, x, invalid
# CHECK: :[[@LINE-1]]:20: error: operand must be 'scaled' or 'unscaled'

lwx a0, a1, a2, 3, scaled
# CHECK: :[[@LINE-1]]:17: error: operand must be one of 'x', 'uxtw', or 'sxtw'

ldx a0, a1, a2, x, 1
# CHECK: :[[@LINE-1]]:20: error: operand must be 'scaled' or 'unscaled'

lbux a0, a1, a2, x
# CHECK: :[[@LINE-1]]:1: error: too few operands for instruction

sdx a0, a1, a2, x, scaled, x
# CHECK: :[[@LINE-1]]:28: error: invalid operand for instruction
