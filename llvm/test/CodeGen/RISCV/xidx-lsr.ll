; RUN: llc -mtriple=riscv64 -mattr=+xidx -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=XIDX
; RUN: llc -mtriple=riscv64 -mattr=-xidx -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=NO-XIDX

; Check that Loop Strength Reduction knows an Xidx load can fold
; base + sizeof(element) * index. Without Xidx, LSR should turn the address
; into a pointer induction variable instead.

define i64 @sum_i32(ptr %base, i64 %count) {
; XIDX-LABEL: sum_i32:
; XIDX:       lwx {{[a-z0-9]+}}, a0, {{[a-z0-9]+}}, x, scaled
; XIDX-NOT:   addi a0, a0, 4
; NO-XIDX-LABEL: sum_i32:
; NO-XIDX-NOT: lwx
entry:
  %empty = icmp eq i64 %count, 0
  br i1 %empty, label %exit, label %loop

loop:
  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i64 [ 0, %entry ], [ %new.sum, %loop ]
  %address = getelementptr i32, ptr %base, i64 %index
  %value = load i32, ptr %address, align 4
  %extended = sext i32 %value to i64
  %value.with.index = xor i64 %extended, %index
  %new.sum = add i64 %sum, %value.with.index
  %next = add nuw i64 %index, 1
  %done = icmp eq i64 %next, %count
  br i1 %done, label %exit, label %loop

exit:
  %result = phi i64 [ 0, %entry ], [ %new.sum, %loop ]
  ret i64 %result
}

; The same legality result must be available for 64-bit accesses.

define i64 @sum_i64(ptr %base, i64 %count) {
; XIDX-LABEL: sum_i64:
; XIDX:       ldx {{[a-z0-9]+}}, a0, {{[a-z0-9]+}}, x, scaled
; XIDX-NOT:   addi a0, a0, 8
; NO-XIDX-LABEL: sum_i64:
; NO-XIDX-NOT: ldx
entry:
  %empty = icmp eq i64 %count, 0
  br i1 %empty, label %exit, label %loop

loop:
  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i64 [ 0, %entry ], [ %new.sum, %loop ]
  %address = getelementptr i64, ptr %base, i64 %index
  %value = load i64, ptr %address, align 8
  %value.with.index = xor i64 %value, %index
  %new.sum = add i64 %sum, %value.with.index
  %next = add nuw i64 %index, 1
  %done = icmp eq i64 %next, %count
  br i1 %done, label %exit, label %loop

exit:
  %result = phi i64 [ 0, %entry ], [ %new.sum, %loop ]
  ret i64 %result
}

; Byte accesses exercise Xidx's unscaled form.

define i64 @sum_i8(ptr %base, i64 %count) {
; XIDX-LABEL: sum_i8:
; XIDX:       lbx {{[a-z0-9]+}}, a0, {{[a-z0-9]+}}, x, unscaled
; NO-XIDX-LABEL: sum_i8:
; NO-XIDX-NOT: lbx
entry:
  %empty = icmp eq i64 %count, 0
  br i1 %empty, label %exit, label %loop

loop:
  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i64 [ 0, %entry ], [ %new.sum, %loop ]
  %address = getelementptr i8, ptr %base, i64 %index
  %value = load i8, ptr %address, align 1
  %extended = sext i8 %value to i64
  %value.with.index = xor i64 %extended, %index
  %new.sum = add i64 %sum, %value.with.index
  %next = add nuw i64 %index, 1
  %done = icmp eq i64 %next, %count
  br i1 %done, label %exit, label %loop

exit:
  %result = phi i64 [ 0, %entry ], [ %new.sum, %loop ]
  ret i64 %result
}

; Stores use the same Xidx-aware LSR legality information.

define void @fill_i64(ptr %base, i64 %count) {
; XIDX-LABEL: fill_i64:
; XIDX:       sdx {{[a-z0-9]+}}, a0, {{[a-z0-9]+}}, x, scaled
; XIDX-NOT:   addi a0, a0, 8
; NO-XIDX-LABEL: fill_i64:
; NO-XIDX-NOT: sdx
entry:
  %empty = icmp eq i64 %count, 0
  br i1 %empty, label %exit, label %loop

loop:
  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
  %address = getelementptr i64, ptr %base, i64 %index
  store i64 %index, ptr %address, align 8
  %next = add nuw i64 %index, 1
  %done = icmp eq i64 %next, %count
  br i1 %done, label %exit, label %loop

exit:
  ret void
}
