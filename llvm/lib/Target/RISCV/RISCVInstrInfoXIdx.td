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

def XIdxOptionAsmOperand : AsmOperandClass {
  let Name = "XIdxOption";
  let RenderMethod = "addImmOperands";
  let ParserMethod = "parseXIdxOption";
  let DiagnosticType = "InvalidXIdxOption";
  let DiagnosticString = "operand must be one of 'x', 'uxtw', or 'sxtw'";
}

def xidx_option : RISCVOp {
  let ParserMatchClass = XIdxOptionAsmOperand;
  let PrintMethod = "printXIdxOption";
  let DecoderMethod = "decodeXIdxOption";
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

// opc = {store, unsigned_load}; opc=11 and opc=01/size=11 are reserved.
class XIdxInst<bits<2> opc, bits<2> size, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<1> scale;
  bits<2> option;
  bits<5> rs2;
  bits<5> rs1;

  let Inst{31-29} = 0;
  let Inst{28-27} = opc;
  let Inst{26-25} = option;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14} = scale;
  let Inst{13-12} = size;
  let Inst{6-0} = OPC_CUSTOM_0.Value;
  let DecoderNamespace = "XIdx";
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class XIdxLoad<bits<2> size, bit unsigned_load, string opcodestr>
    : XIdxInst<!if(unsigned_load, 0b01, 0b00), size, (outs GPR:$rd),
               (ins GPR:$rs1, GPR:$rs2,
                    xidx_option:$option, xidx_scale:$scale),
               opcodestr, "$rd, $rs1, $rs2, $option, $scale"> {
  bits<5> rd;
  let Inst{11-7} = rd;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class XIdxStore<bits<2> size, string opcodestr>
    : XIdxInst<0b10, size, (outs),
               (ins GPR:$rs3, GPR:$rs1, GPR:$rs2,
                    xidx_option:$option, xidx_scale:$scale),
               opcodestr, "$rs3, $rs1, $rs2, $option, $scale"> {
  bits<5> rs3;
  let Inst{11-7} = rs3;
}

let Predicates = [HasVendorXIdx, IsRV64] in {
def XIDX_LB  : XIdxLoad<0b00, 0, "lbx">,
               Sched<[WriteLDB, ReadMemBase]>;
def XIDX_LH  : XIdxLoad<0b01, 0, "lhx">,
               Sched<[WriteLDH, ReadMemBase]>;
def XIDX_LW  : XIdxLoad<0b10, 0, "lwx">,
               Sched<[WriteLDW, ReadMemBase]>;
def XIDX_LD  : XIdxLoad<0b11, 0, "ldx">,
               Sched<[WriteLDD, ReadMemBase]>;
def XIDX_LBU : XIdxLoad<0b00, 1, "lbux">,
               Sched<[WriteLDB, ReadMemBase]>;
def XIDX_LHU : XIdxLoad<0b01, 1, "lhux">,
               Sched<[WriteLDH, ReadMemBase]>;
def XIDX_LWU : XIdxLoad<0b10, 1, "lwux">,
               Sched<[WriteLDW, ReadMemBase]>;

def XIDX_SB : XIdxStore<0b00, "sbx">,
              Sched<[WriteSTB, ReadStoreData, ReadMemBase]>;
def XIDX_SH : XIdxStore<0b01, "shx">,
              Sched<[WriteSTH, ReadStoreData, ReadMemBase]>;
def XIDX_SW : XIdxStore<0b10, "swx">,
              Sched<[WriteSTW, ReadStoreData, ReadMemBase]>;
def XIDX_SD : XIdxStore<0b11, "sdx">,
              Sched<[WriteSTD, ReadStoreData, ReadMemBase]>;
} // Predicates = [HasVendorXIdx, IsRV64]

multiclass XIdxLoadPat<PatFrag LoadOp, RVInst Inst, ComplexPattern Addr> {
  def : Pat<(i64 (LoadOp (Addr (i64 GPR:$rs1), (i64 GPR:$rs2),
                                uimm2:$option, uimm1:$scale))),
            (Inst GPR:$rs1, GPR:$rs2, uimm2:$option, uimm1:$scale)>;
}

multiclass XIdxStorePat<PatFrag StoreOp, RVInst Inst, ComplexPattern Addr> {
  def : Pat<(StoreOp (i64 GPR:$rs3),
                     (Addr (i64 GPR:$rs1), (i64 GPR:$rs2),
                           uimm2:$option, uimm1:$scale)),
            (Inst GPR:$rs3, GPR:$rs1, GPR:$rs2,
                  uimm2:$option, uimm1:$scale)>;
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
