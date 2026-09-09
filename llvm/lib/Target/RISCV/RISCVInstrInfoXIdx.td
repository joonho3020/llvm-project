//===-- RISCVInstrInfoXIdx.td -----------------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the non-standard XIdx indexed scalar memory extension.
//
//===----------------------------------------------------------------------===//

def XIdxIndexFormatAsmOperand : AsmOperandClass {
  let Name = "XIdxIndexFormat";
  let RenderMethod = "addImmOperands";
  let ParserMethod = "parseXIdxIndexFormat";
  let DiagnosticType = "InvalidXIdxIndexFormat";
  let DiagnosticString = "operand must be one of 'x', 'uxtw', or 'sxtw'";
}

def xidx_index_format : RISCVOp {
  let ParserMatchClass = XIdxIndexFormatAsmOperand;
  let PrintMethod = "printXIdxIndexFormat";
  let DecoderMethod = "decodeXIdxIndexFormat";
  let OperandType = "OPERAND_UIMM2";
}

def XIdxScaleAsmOperand : AsmOperandClass {
  let Name = "XIdxScale";
  let RenderMethod = "addImmOperands";
  let ParserMethod = "parseXIdxScale";
  let DiagnosticType = "InvalidXIdxScale";
  let DiagnosticString = "operand must be 'scaled' or 'unscaled'";
}

def xidx_scale : RISCVOp {
  let ParserMatchClass = XIdxScaleAsmOperand;
  let PrintMethod = "printXIdxScale";
  let DecoderMethod = "decodeUImmOperand<1>";
  let OperandType = "OPERAND_UIMM1";
}

class XIdxAddr<int NaturalShift>
    : ComplexPattern<i64, 4, "SelectXIdxAddr<"#NaturalShift#">",
                     [], [], 10>;

def XIdxAddrByte : XIdxAddr<0>;
def XIdxAddrHalf : XIdxAddr<1>;
def XIdxAddrWord : XIdxAddr<2>;
def XIdxAddrDouble : XIdxAddr<3>;

class XIdxInst<bits<4> funct4, bits<3> width, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<1> scale;
  bits<2> index_format;
  bits<5> rs2;
  bits<5> rs1;

  let Inst{31-28} = funct4;
  let Inst{27} = scale;
  let Inst{26-25} = index_format;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{6-0} = OPC_CUSTOM_0.Value;
  let DecoderNamespace = "XIdx";
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class XIdxLoad<bits<3> width, string opcodestr>
    : XIdxInst<0b0000, width, (outs GPR:$rd),
               (ins GPR:$rs1, GPR:$rs2,
                    xidx_index_format:$index_format, xidx_scale:$scale),
               opcodestr, "$rd, $rs1, $rs2, $index_format, $scale"> {
  bits<5> rd;
  let Inst{11-7} = rd;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class XIdxStore<bits<3> width, string opcodestr>
    : XIdxInst<0b0001, width, (outs),
               (ins GPR:$rs3, GPR:$rs1, GPR:$rs2,
                    xidx_index_format:$index_format, xidx_scale:$scale),
               opcodestr, "$rs3, $rs1, $rs2, $index_format, $scale"> {
  bits<5> rs3;
  let Inst{11-7} = rs3;
}

let Predicates = [HasVendorXIdx, IsRV64] in {
def XIDX_LB  : XIdxLoad<0b000, "lbx">,
               Sched<[WriteLDB, ReadMemBase]>;
def XIDX_LH  : XIdxLoad<0b001, "lhx">,
               Sched<[WriteLDH, ReadMemBase]>;
def XIDX_LW  : XIdxLoad<0b010, "lwx">,
               Sched<[WriteLDW, ReadMemBase]>;
def XIDX_LD  : XIdxLoad<0b011, "ldx">,
               Sched<[WriteLDD, ReadMemBase]>;
def XIDX_LBU : XIdxLoad<0b100, "lbux">,
               Sched<[WriteLDB, ReadMemBase]>;
def XIDX_LHU : XIdxLoad<0b101, "lhux">,
               Sched<[WriteLDH, ReadMemBase]>;
def XIDX_LWU : XIdxLoad<0b110, "lwux">,
               Sched<[WriteLDW, ReadMemBase]>;

def XIDX_SB : XIdxStore<0b000, "sbx">,
              Sched<[WriteSTB, ReadStoreData, ReadMemBase]>;
def XIDX_SH : XIdxStore<0b001, "shx">,
              Sched<[WriteSTH, ReadStoreData, ReadMemBase]>;
def XIDX_SW : XIdxStore<0b010, "swx">,
              Sched<[WriteSTW, ReadStoreData, ReadMemBase]>;
def XIDX_SD : XIdxStore<0b011, "sdx">,
              Sched<[WriteSTD, ReadStoreData, ReadMemBase]>;
} // Predicates = [HasVendorXIdx, IsRV64]

multiclass XIdxLoadPat<PatFrag LoadOp, RVInst Inst, ComplexPattern Addr> {
  def : Pat<(i64 (LoadOp (Addr (i64 GPR:$rs1), (i64 GPR:$rs2),
                                uimm2:$index_format, uimm1:$scale))),
            (Inst GPR:$rs1, GPR:$rs2, uimm2:$index_format, uimm1:$scale)>;
}

multiclass XIdxStorePat<PatFrag StoreOp, RVInst Inst, ComplexPattern Addr> {
  def : Pat<(StoreOp (i64 GPR:$rs3),
                     (Addr (i64 GPR:$rs1), (i64 GPR:$rs2),
                           uimm2:$index_format, uimm1:$scale)),
            (Inst GPR:$rs3, GPR:$rs1, GPR:$rs2,
                  uimm2:$index_format, uimm1:$scale)>;
}

let Predicates = [HasVendorXIdx, IsRV64], AddedComplexity = 10 in {
  defm : XIdxLoadPat<sextloadi8, XIDX_LB, XIdxAddrByte>;
  defm : XIdxLoadPat<zextloadi8, XIDX_LBU, XIdxAddrByte>;
  defm : XIdxLoadPat<extloadi8, XIDX_LBU, XIdxAddrByte>;
  defm : XIdxLoadPat<sextloadi16, XIDX_LH, XIdxAddrHalf>;
  defm : XIdxLoadPat<zextloadi16, XIDX_LHU, XIdxAddrHalf>;
  defm : XIdxLoadPat<extloadi16, XIDX_LHU, XIdxAddrHalf>;
  defm : XIdxLoadPat<sextloadi32, XIDX_LW, XIdxAddrWord>;
  defm : XIdxLoadPat<zextloadi32, XIDX_LWU, XIdxAddrWord>;
  defm : XIdxLoadPat<extloadi32, XIDX_LWU, XIdxAddrWord>;
  defm : XIdxLoadPat<load, XIDX_LD, XIdxAddrDouble>;

  defm : XIdxStorePat<truncstorei8, XIDX_SB, XIdxAddrByte>;
  defm : XIdxStorePat<truncstorei16, XIDX_SH, XIdxAddrHalf>;
  defm : XIdxStorePat<truncstorei32, XIDX_SW, XIdxAddrWord>;
  defm : XIdxStorePat<store, XIDX_SD, XIdxAddrDouble>;
}
