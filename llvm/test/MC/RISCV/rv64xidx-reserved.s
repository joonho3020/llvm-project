# RUN: llvm-mc -triple=riscv64 -filetype=obj %s \
# RUN:   | llvm-objdump -d --mattr=+xidx - \
# RUN:   | FileCheck %s

# Reserved index format (idxFmt=11).
.word 0x06c5850b
# CHECK: 06c5850b <unknown>

# Reserved load width 111.
.word 0x00c5f50b
# CHECK: 00c5f50b <unknown>

# Reserved store widths 100 through 111.
.word 0x10c5c50b
# CHECK: 10c5c50b <unknown>
.word 0x10c5d50b
# CHECK: 10c5d50b <unknown>
.word 0x10c5e50b
# CHECK: 10c5e50b <unknown>
.word 0x10c5f50b
# CHECK: 10c5f50b <unknown>

# Reserved funct4 values 0010 through 1111.
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
