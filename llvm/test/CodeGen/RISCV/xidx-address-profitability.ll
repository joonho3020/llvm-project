; RUN: llc -mtriple=riscv64 -mattr=+xidx -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=riscv64 -mattr=+zba,+xidx -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,ZBA

; Do not replace a shared base+index with a separate base+displacement for
; each load. Ordinary loads can share the address and encode the offsets.
define i64 @shared_displaced_loads(ptr %base, i64 %index) {
; CHECK-LABEL: shared_displaced_loads:
; CHECK:       ld {{[a-z0-9]+}}, 160([[ADDR:[a-z0-9]+]])
; CHECK:       ld {{[a-z0-9]+}}, 320([[ADDR]])
; CHECK:       ret
  %addr = getelementptr i8, ptr %base, i64 %index
  %p1 = getelementptr i8, ptr %addr, i64 160
  %p2 = getelementptr i8, ptr %addr, i64 320
  %a = load volatile i64, ptr %addr, align 8
  %b = load volatile i64, ptr %p1, align 8
  %c = load volatile i64, ptr %p2, align 8
  %ab = add i64 %a, %b
  %abc = add i64 %ab, %c
  ret i64 %abc
}

; The shared computation may include scaling. Zba can materialize it with
; SH3ADD; an Xidx-only target still benefits from sharing the shift and add.
define void @shared_displaced_stores(ptr %base, i64 %index, i64 %value) {
; CHECK-LABEL: shared_displaced_stores:
; ZBA:         sh3add
; CHECK:       sd a2, 160([[ADDR:[a-z0-9]+]])
; CHECK:       sd a2, 320([[ADDR]])
; CHECK:       ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %p1 = getelementptr i8, ptr %addr, i64 160
  %p2 = getelementptr i8, ptr %addr, i64 320
  store volatile i64 %value, ptr %addr, align 8
  store volatile i64 %value, ptr %p1, align 8
  store volatile i64 %value, ptr %p2, align 8
  ret void
}

; Also preserve a displaced address when the address itself escapes.
define ptr @escaping_displaced_address(ptr %base, i64 %index, i64 %value) {
; CHECK-LABEL: escaping_displaced_address:
; CHECK-NOT:   sdx
; CHECK:       sd a2,
; CHECK-NOT:   sdx
; CHECK:       ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %biased = getelementptr i8, ptr %addr, i64 24
  store volatile i64 %value, ptr %biased, align 8
  ret ptr %biased
}

; A single-use scaled address with a displacement can still benefit: the
; ADDI plus LDX eliminates a separate shift on targets without Zba.
define i64 @single_displaced_load(ptr %base, i64 %index) {
; CHECK-LABEL: single_displaced_load:
; CHECK:       addi a0, a0, 24
; CHECK-NEXT:  ldx a0, a0, a1, x, scaled
; CHECK-NEXT:  ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %biased = getelementptr i8, ptr %addr, i64 24
  %value = load i64, ptr %biased, align 8
  ret i64 %value
}

; Multiple uses alone must not disable indexed accesses without a
; displacement: both consumers can fold the same address at no extra cost.
define i64 @shared_no_displacement(ptr %base, i64 %index, i64 %value) {
; CHECK-LABEL: shared_no_displacement:
; CHECK:       ldx {{[a-z0-9]+}}, a0, a1, x, scaled
; CHECK-NEXT:  sdx a2, a0, a1, x, scaled
; CHECK:       ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %old = load volatile i64, ptr %addr, align 8
  store volatile i64 %value, ptr %addr, align 8
  ret i64 %old
}

; LSR sees naturally scaled i64 accesses here, but legalization splits the
; unaligned loads/stores into byte accesses. Those bytes must share addresses
; rather than each retaining a different invariant base+displacement.
; The caller supplies a nonzero count, as in Rust's byte-swap helper.
define void @split_unaligned_accesses(ptr noalias %x, ptr noalias %y, i64 %count) {
; CHECK-LABEL: split_unaligned_accesses:
; CHECK-DAG:   lbu {{[a-z0-9]+}}, 1([[ADDR:[a-z0-9]+]])
; CHECK-DAG:   lbu {{[a-z0-9]+}}, 7([[ADDR]])
; CHECK-DAG:   sb {{[a-z0-9]+}}, 1([[ADDR]])
; CHECK-DAG:   sb {{[a-z0-9]+}}, 7([[ADDR]])
; CHECK:       ret
entry:
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %px = getelementptr i64, ptr %x, i64 %i
  %py = getelementptr i64, ptr %y, i64 %i
  %a = load i64, ptr %px, align 1
  %b = load i64, ptr %py, align 1
  store i64 %b, ptr %px, align 1
  store i64 %a, ptr %py, align 1
  %next = add nuw i64 %i, 1
  %done = icmp eq i64 %next, %count
  br i1 %done, label %exit, label %loop
exit:
  ret void
}

; A shared address is still foldable when all its users are memory accesses
; and there is only one nonzero displacement. Reuse one displaced base.
define i64 @single_shared_displacement(ptr %base, i64 %index, i64 %value) {
; CHECK-LABEL: single_shared_displacement:
; CHECK:       addi [[BASE:[a-z0-9]+]], a0, 8
; CHECK:       ldx {{[a-z0-9]+}}, [[BASE]], a1, x, scaled
; CHECK:       sdx a2, [[BASE]], a1, x, scaled
; CHECK:       ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %biased = getelementptr i8, ptr %addr, i64 8
  %a = load volatile i64, ptr %addr, align 8
  %b = load volatile i64, ptr %biased, align 8
  store volatile i64 %value, ptr %biased, align 8
  %sum = add i64 %a, %b
  ret i64 %sum
}

; Indirect indices prevent pointer-IV strength reduction. The base+8 ADDI
; should move outside the loop, leaving two indexed loads in the loop.
; As above, the caller supplies a nonzero count.
define i64 @single_shared_displacement_loop(ptr %base, ptr %indices, i64 %count) {
; CHECK-LABEL: single_shared_displacement_loop:
; CHECK:       mv [[ORIGINAL:[a-z0-9]+]], a0
; CHECK:       addi [[BASE:[a-z0-9]+]], [[ORIGINAL]], 8
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       ldx {{[a-z0-9]+}}, [[ORIGINAL]], [[INDEX:[a-z0-9]+]], x, scaled
; CHECK:       ldx {{[a-z0-9]+}}, [[BASE]], [[INDEX]], x, scaled
; CHECK:       ret
entry:
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %acc = phi i64 [ 0, %entry ], [ %sum, %loop ]
  %ip = getelementptr i64, ptr %indices, i64 %i
  %index = load i64, ptr %ip, align 8
  %addr = getelementptr i64, ptr %base, i64 %index
  %biased = getelementptr i8, ptr %addr, i64 8
  %a = load volatile i64, ptr %addr, align 8
  %b = load volatile i64, ptr %biased, align 8
  %ab = add i64 %a, %b
  %sum = add i64 %acc, %ab
  %next = add nuw i64 %i, 1
  %done = icmp eq i64 %next, %count
  br i1 %done, label %exit, label %loop
exit:
  ret i64 %sum
}

; A single displacement must not override the guard if the inner pointer
; escapes, including when it is itself stored as data.
define ptr @escaping_inner_address(ptr %base, i64 %index) {
; CHECK-LABEL: escaping_inner_address:
; CHECK-NOT:   sdx
; CHECK:       sd {{[a-z0-9]+}}, 8(
; CHECK-NOT:   sdx
; CHECK:       ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %biased = getelementptr i8, ptr %addr, i64 8
  store volatile ptr %addr, ptr %biased, align 8
  ret ptr %addr
}

define void @address_stored_as_data(ptr %base, i64 %index) {
; CHECK-LABEL: address_stored_as_data:
; CHECK-NOT:   sdx
; CHECK:       addi [[ADDR:[a-z0-9]+]], [[BASE:[a-z0-9]+]], 8
; CHECK-NOT:   sdx
; CHECK:       sd [[ADDR]], 8([[BASE]])
; CHECK-NOT:   sdx
; CHECK:       ret
  %addr = getelementptr i64, ptr %base, i64 %index
  %biased = getelementptr i8, ptr %addr, i64 8
  store volatile ptr %biased, ptr %biased, align 8
  ret void
}
