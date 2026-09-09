; RUN: llc -mtriple=riscv64 -mattr=+xidx -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=XIDX
; RUN: llc -O0 -mtriple=riscv64 -mattr=+xidx -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=XIDX
; RUN: llc -mtriple=riscv64 -mattr=-xidx -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=NO-XIDX

; Natural element-size scaling should be folded into Xidx.

define signext i8 @load_i8_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_i8_scaled:
; XIDX:       lbx a0, a0, a1, x, unscaled
; NO-XIDX-LABEL: load_i8_scaled:
; NO-XIDX-NOT: lbx
  %addr = getelementptr i8, ptr %base, i64 %index
  %value = load i8, ptr %addr
  ret i8 %value
}

define zeroext i8 @load_u8_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_u8_scaled:
; XIDX:       lbux a0, a0, a1, x, unscaled
; NO-XIDX-LABEL: load_u8_scaled:
; NO-XIDX-NOT: lbux
  %addr = getelementptr i8, ptr %base, i64 %index
  %value = load i8, ptr %addr
  ret i8 %value
}

define signext i16 @load_i16_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_i16_scaled:
; XIDX:       lhx a0, a0, a1, x, scaled
; NO-XIDX-LABEL: load_i16_scaled:
; NO-XIDX-NOT: lhx
  %addr = getelementptr i16, ptr %base, i64 %index
  %value = load i16, ptr %addr
  ret i16 %value
}

define zeroext i16 @load_u16_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_u16_scaled:
; XIDX:       lhux a0, a0, a1, x, scaled
; NO-XIDX-LABEL: load_u16_scaled:
; NO-XIDX-NOT: lhux
  %addr = getelementptr i16, ptr %base, i64 %index
  %value = load i16, ptr %addr
  ret i16 %value
}

define signext i32 @load_i32_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_i32_scaled:
; XIDX:       lwx a0, a0, a1, x, scaled
; NO-XIDX-LABEL: load_i32_scaled:
; NO-XIDX-NOT: lwx
  %addr = getelementptr i32, ptr %base, i64 %index
  %value = load i32, ptr %addr
  ret i32 %value
}

define i64 @load_u32_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_u32_scaled:
; XIDX:       lwux a0, a0, a1, x, scaled
; NO-XIDX-LABEL: load_u32_scaled:
; NO-XIDX-NOT: lwux
  %addr = getelementptr i32, ptr %base, i64 %index
  %value = load i32, ptr %addr
  %extended = zext i32 %value to i64
  ret i64 %extended
}

define i64 @load_i64_scaled(ptr %base, i64 %index) {
; XIDX-LABEL: load_i64_scaled:
; XIDX:       ldx a0, a0, a1, x, scaled
; NO-XIDX-LABEL: load_i64_scaled:
; NO-XIDX-NOT: ldx
  %addr = getelementptr i64, ptr %base, i64 %index
  %value = load i64, ptr %addr
  ret i64 %value
}

define void @store_i8_scaled(ptr %base, i64 %index, i8 %value) {
; XIDX-LABEL: store_i8_scaled:
; XIDX:       sbx a2, a0, a1, x, unscaled
; NO-XIDX-LABEL: store_i8_scaled:
; NO-XIDX-NOT: sbx
  %addr = getelementptr i8, ptr %base, i64 %index
  store i8 %value, ptr %addr
  ret void
}

define void @store_i16_scaled(ptr %base, i64 %index, i16 %value) {
; XIDX-LABEL: store_i16_scaled:
; XIDX:       shx a2, a0, a1, x, scaled
; NO-XIDX-LABEL: store_i16_scaled:
; NO-XIDX-NOT: shx
  %addr = getelementptr i16, ptr %base, i64 %index
  store i16 %value, ptr %addr
  ret void
}

define void @store_i32_scaled(ptr %base, i64 %index, i32 %value) {
; XIDX-LABEL: store_i32_scaled:
; XIDX:       swx a2, a0, a1, x, scaled
; NO-XIDX-LABEL: store_i32_scaled:
; NO-XIDX-NOT: swx
  %addr = getelementptr i32, ptr %base, i64 %index
  store i32 %value, ptr %addr
  ret void
}

define void @store_i64_scaled(ptr %base, i64 %index, i64 %value) {
; XIDX-LABEL: store_i64_scaled:
; XIDX:       sdx a2, a0, a1, x, scaled
; NO-XIDX-LABEL: store_i64_scaled:
; NO-XIDX-NOT: sdx
  %addr = getelementptr i64, ptr %base, i64 %index
  store i64 %value, ptr %addr
  ret void
}

; A byte GEP before a wider access requests unscaled addressing.

define i64 @load_i64_unscaled(ptr %base, i64 %byte_index) {
; XIDX-LABEL: load_i64_unscaled:
; XIDX:       ldx a0, a0, a1, x, unscaled
  %addr = getelementptr i8, ptr %base, i64 %byte_index
  %value = load i64, ptr %addr
  ret i64 %value
}

; Index extensions should be absorbed into index_format.

define i64 @load_i64_uxtw_scaled(ptr %base, i64 %raw_index) {
; XIDX-LABEL: load_i64_uxtw_scaled:
; XIDX:       ldx a0, a0, a1, uxtw, scaled
  %index = trunc i64 %raw_index to i32
  %extended = zext i32 %index to i64
  %addr = getelementptr i64, ptr %base, i64 %extended
  %value = load i64, ptr %addr
  ret i64 %value
}

define i64 @load_i64_sxtw_scaled(ptr %base, i64 %raw_index) {
; XIDX-LABEL: load_i64_sxtw_scaled:
; XIDX:       ldx a0, a0, a1, sxtw, scaled
  %index = trunc i64 %raw_index to i32
  %extended = sext i32 %index to i64
  %addr = getelementptr i64, ptr %base, i64 %extended
  %value = load i64, ptr %addr
  ret i64 %value
}

define void @store_i32_uxtw_unscaled(ptr %base, i64 %raw_index, i32 %value) {
; XIDX-LABEL: store_i32_uxtw_unscaled:
; XIDX:       swx a2, a0, a1, uxtw, unscaled
  %index = trunc i64 %raw_index to i32
  %extended = zext i32 %index to i64
  %addr = getelementptr i8, ptr %base, i64 %extended
  store i32 %value, ptr %addr
  ret void
}

define void @store_i32_sxtw_unscaled(ptr %base, i64 %raw_index, i32 %value) {
; XIDX-LABEL: store_i32_sxtw_unscaled:
; XIDX:       swx a2, a0, a1, sxtw, unscaled
  %index = trunc i64 %raw_index to i32
  %extended = sext i32 %index to i64
  %addr = getelementptr i8, ptr %base, i64 %extended
  store i32 %value, ptr %addr
  ret void
}

; A constant displacement is folded into the base with ADDI.

define i64 @load_i64_scaled_displacement(ptr %base, i64 %index) {
; XIDX-LABEL: load_i64_scaled_displacement:
; XIDX:       addi a0, a0, 24
; XIDX-NEXT:  ldx a0, a0, a1, x, scaled
  %biased = getelementptr i8, ptr %base, i64 24
  %addr = getelementptr i64, ptr %biased, i64 %index
  %value = load i64, ptr %addr
  ret i64 %value
}

define i64 @load_i64_uxtw_scaled_displacement(ptr %base, i64 %raw_index) {
; XIDX-LABEL: load_i64_uxtw_scaled_displacement:
; XIDX:       addi a0, a0, 24
; XIDX-NEXT:  ldx a0, a0, a1, uxtw, scaled
  %index32 = trunc i64 %raw_index to i32
  %index = zext i32 %index32 to i64
  %biased = getelementptr i8, ptr %base, i64 24
  %addr = getelementptr i64, ptr %biased, i64 %index
  %value = load i64, ptr %addr
  ret i64 %value
}

; Xidx is RV64-only and must not affect an ordinary base-plus-immediate access.

define i64 @load_i64_immediate(ptr %base) {
; XIDX-LABEL: load_i64_immediate:
; XIDX:       ld a0, 24(a0)
; XIDX-NOT:   ldx
  %addr = getelementptr i64, ptr %base, i64 3
  %value = load i64, ptr %addr
  ret i64 %value
}
