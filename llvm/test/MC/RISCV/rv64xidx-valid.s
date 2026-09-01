# RUN: llvm-mc -triple=riscv64 -show-encoding -mattr=+xidx %s \
# RUN:   | FileCheck %s --check-prefixes=CHECK-INST,CHECK-ENCODING
# RUN: llvm-mc -triple=riscv64 -filetype=obj -mattr=+xidx %s \
# RUN:   | llvm-objdump -d --mattr=+xidx - \
# RUN:   | FileCheck %s --check-prefix=CHECK-INST
# RUN: llvm-mc -triple=riscv64 -filetype=obj -mattr=+xidx %s \
# RUN:   | llvm-objdump -d - \
# RUN:   | FileCheck %s --check-prefix=CHECK-UNKNOWN
# RUN: not llvm-mc -triple=riscv64 -show-encoding %s 2>&1 \
# RUN:   | FileCheck %s --check-prefix=CHECK-ERROR

lbx a0, a1, a2, x, unscaled
# CHECK-INST: lbx a0, a1, a2, x, unscaled
# CHECK-ENCODING: [0x0b,0x85,0xc5,0x00]
# CHECK-UNKNOWN: 00c5850b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

lhx a0, a1, a2, uxtw, scaled
# CHECK-INST: lhx a0, a1, a2, uxtw, scaled
# CHECK-ENCODING: [0x0b,0x95,0xc5,0x0a]
# CHECK-UNKNOWN: 0ac5950b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

lwx a0, a1, a2, sxtw, unscaled
# CHECK-INST: lwx a0, a1, a2, sxtw, unscaled
# CHECK-ENCODING: [0x0b,0xa5,0xc5,0x04]
# CHECK-UNKNOWN: 04c5a50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

# The four-operand spelling defaults the index format to x. Disassembly uses
# the canonical five-operand spelling checked below.
ldx a0, a1, a2, scaled
# CHECK-INST: ldx a0, a1, a2, x, scaled
# CHECK-ENCODING: [0x0b,0xb5,0xc5,0x08]
# CHECK-UNKNOWN: 08c5b50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

lbux a0, a1, a2, uxtw, unscaled
# CHECK-INST: lbux a0, a1, a2, uxtw, unscaled
# CHECK-ENCODING: [0x0b,0xc5,0xc5,0x02]
# CHECK-UNKNOWN: 02c5c50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

lhux a0, a1, a2, sxtw, scaled
# CHECK-INST: lhux a0, a1, a2, sxtw, scaled
# CHECK-ENCODING: [0x0b,0xd5,0xc5,0x0c]
# CHECK-UNKNOWN: 0cc5d50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

lwux a0, a1, a2, x, unscaled
# CHECK-INST: lwux a0, a1, a2, x, unscaled
# CHECK-ENCODING: [0x0b,0xe5,0xc5,0x00]
# CHECK-UNKNOWN: 00c5e50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

sbx a0, a1, a2, x, scaled
# CHECK-INST: sbx a0, a1, a2, x, scaled
# CHECK-ENCODING: [0x0b,0x85,0xc5,0x18]
# CHECK-UNKNOWN: 18c5850b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

shx a0, a1, a2, uxtw, unscaled
# CHECK-INST: shx a0, a1, a2, uxtw, unscaled
# CHECK-ENCODING: [0x0b,0x95,0xc5,0x12]
# CHECK-UNKNOWN: 12c5950b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

swx a0, a1, a2, sxtw, scaled
# CHECK-INST: swx a0, a1, a2, sxtw, scaled
# CHECK-ENCODING: [0x0b,0xa5,0xc5,0x1c]
# CHECK-UNKNOWN: 1cc5a50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}

sdx a0, a1, a2, unscaled
# CHECK-INST: sdx a0, a1, a2, x, unscaled
# CHECK-ENCODING: [0x0b,0xb5,0xc5,0x10]
# CHECK-UNKNOWN: 10c5b50b <unknown>
# CHECK-ERROR: instruction requires the following: 'XIdx' (Indexed scalar memory operations){{$}}
