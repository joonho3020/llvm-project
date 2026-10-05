# RUN: llvm-mc -triple=riscv64 -filetype=obj %s \
# RUN:   | llvm-objdump -d --mattr=+xidx - \
# RUN:   | FileCheck %s

# Reserved index option (option=11).
.word 0x06c5850b
# CHECK: 06c5850b <unknown>

# Reserved unsigned doubleword load (opc=01, size=11).
.word 0x08c5b50b
# CHECK: 08c5b50b <unknown>

# Reserved opc=11 for every size.
.word 0x18c5850b
# CHECK: 18c5850b <unknown>
.word 0x18c5950b
# CHECK: 18c5950b <unknown>
.word 0x18c5a50b
# CHECK: 18c5a50b <unknown>
.word 0x18c5b50b
# CHECK: 18c5b50b <unknown>

# Reserved nonzero bits [31:29] (with both values of the store bit).
.word 0x20c5850b
# CHECK: 20c5850b <unknown>
.word 0x30c5850b
# CHECK: 30c5850b <unknown>
.word 0x40c5850b
# CHECK: 40c5850b <unknown>
.word 0x50c5850b
# CHECK: 50c5850b <unknown>
.word 0x60c5850b
# CHECK: 60c5850b <unknown>
.word 0x70c5850b
# CHECK: 70c5850b <unknown>
.word 0x80c5850b
# CHECK: 80c5850b <unknown>
.word 0x90c5850b
# CHECK: 90c5850b <unknown>
.word 0xa0c5850b
# CHECK: a0c5850b <unknown>
.word 0xb0c5850b
# CHECK: b0c5850b <unknown>
.word 0xc0c5850b
# CHECK: c0c5850b <unknown>
.word 0xd0c5850b
# CHECK: d0c5850b <unknown>
.word 0xe0c5850b
# CHECK: e0c5850b <unknown>
.word 0xf0c5850b
# CHECK: f0c5850b <unknown>
