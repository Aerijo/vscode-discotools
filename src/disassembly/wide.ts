import { INSTRUCTION } from "./instructions";

function idCDP (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.CDP_T2
    : INSTRUCTION.CDP_T1;
}

function idMCR (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.MCR_T2
    : INSTRUCTION.MCR_T1;
}

function idMRC (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.MRC_T2
    : INSTRUCTION.MRC_T1;
}

function idMRRC (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.MRRC_T2
    : INSTRUCTION.MRRC_T1;
}

function idMCRR (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.MCRR_T2
    : INSTRUCTION.MCRR_T1;
}

function idLDC (word: number): INSTRUCTION {
  if (((word >>> 16) & 0b1111) === 0b1111) return idLDC_LIT(word);

  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.LDC_IMM_T2
    : INSTRUCTION.LDC_IMM_T1;
}

function idLDC_LIT (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.LDC_LIT_T2
    : INSTRUCTION.LDC_LIT_T1;
}

function idSTC (word: number): INSTRUCTION {
  return ((word >>> 28) & 0b1)
    ? INSTRUCTION.STC_T2
    : INSTRUCTION.STC_T1;
}

function AND_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.AND_REG_T2;
}

function TST_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.TST_REG_T2;
}

function BIC_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.BIC_REG_T2;
}

function ORR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.ORR_REG_T2;
}

function ORN_REG_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.ORN_REG_T1;
}

function MVN_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.MVN_REG_T2;
}

function EOR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.EOR_REG_T2;
}

function TEQ_REG_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.TEQ_REG_T1;
}

function PKHBT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.PKHBT_T1; // TODO: Identify PKHBT vs PKHTB
}

function ADD_REG_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADD_REG_T3;
}

function CMN_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.CMN_REG_T2;
}

function ADC_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADC_REG_T2;
}

function SBC_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.SBC_REG_T2;
}

function SUB_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.SUB_REG_T2;
}

function CMP_REG_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.CMP_REG_T3;
}

function RSB_REG_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.RSB_REG_T1;
}

function MOV_REG_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.MOV_REG_T3;
}

function LSL_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LSL_IMM_T2;
}

function LSR_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LSR_IMM_T2;
}

function ASR_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.ASR_IMM_T2;
}

function RRX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.RRX_T1;
}

function ROR_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.ROR_IMM_T1;
}

function LDM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDM_T2;
}

function POP_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.POP_T2;
}

function STM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.STM_T2;
}

function LDMDB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDMDB_T1;
}

function PUSH_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.PUSH_T2;
}

function STMDB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.STMDB_T1;
}

function idLDRD (word: number): INSTRUCTION {
  const RN = (word >>> 16) & 0b1111;
  return (RN === 0b1111) ? LDRD_LIT_T1(word) : LDRD_IMM_T1(word);
}

function LDRD_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRD_LIT_T1;
}

function LDRD_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRD_IMM_T1;
}

function STREX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.STREX_T1;
}

function LDREX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDREX_T1;
}

function STRD_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRD_IMM_T1;
}

function STREXB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.STREXB_T1;
}

function STREXH_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.STREXH_T1;
}

function TBB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.TBB_T1;
}

function TBH_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.TBH_T1;
}

function LDREXB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDREXB_T1;
}

function LDREXH_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDREXH_T1;
}

function BL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.BL_T1;
}

function B_T4 (_word: number): INSTRUCTION {
  return INSTRUCTION.B_T4;
}

function B_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.B_T3;
}

function MSR_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.MSR_T1;
}

function MRS_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.MRS_T1;
}

function NOP_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.NOP_T2;
}

function YIELD_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.YIELD_T2;
}

function WFE_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.WFE_T2;
}

function WFI_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.WFI_T2;
}

function SEV_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.SEV_T2;
}

function DBG_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.DBG_T1;
}

function CLREX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.CLREX_T1;
}

function DSB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.DSB_T1;
}

function DMB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.DMB_T1;
}

function ISB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.ISB_T1;
}

function AND_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.AND_IMM_T1;
}

function TST_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.TST_IMM_T1;
}

function BIC_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.BIC_IMM_T1;
}

function ORR_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.ORR_IMM_T1;
}

function MOV_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.MOV_IMM_T2;
}

function ORN_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.ORN_IMM_T1;
}

function MVN_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.MVN_IMM_T1;
}

function EOR_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.EOR_IMM_T1;
}

function TEQ_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.TEQ_IMM_T1;
}

function ADD_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADD_IMM_T3;
}

function CMN_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.CMN_IMM_T1;
}

function ADC_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADC_IMM_T1;
}

function SBC_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SBC_IMM_T1;
}

function SUB_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.SUB_IMM_T3;
}

function CMP_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.CMP_IMM_T2;
}

function RSB_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.RSB_IMM_T2;
}

function ADD_IMM_T4 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADD_IMM_T4;
}

function ADR_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADR_T3;
}

function MOV_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.MOV_IMM_T3;
}

function SUB_IMM_T4 (_word: number): INSTRUCTION {
  return INSTRUCTION.SUB_IMM_T4;
}

function ADR_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.ADR_T2;
}

function MOVT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.MOVT_T1;
}

function SSAT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SSAT_T1;
}

function SSAT16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SSAT16_T1;
}

function SBFX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SBFX_T1;
}

function BFI_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.BFI_T1;
}

function BFC_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.BFC_T1;
}

function USAT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.USAT_T1;
}

function USAT16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.USAT16_T1;
}

function UBFX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UBFX_T1;
}

function MLS_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.MLS_T1;
}

function MUL_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.MUL_T2;
}

function MLA_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.MLA_T1;
}

function SMULTT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULTT_T1;
}

function SMULTB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULTB_T1;
}

function SMULBT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULBT_T1;
}

function SMULBB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULBB_T1;
}

function SMLATT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLATT_T1;
}

function SMLATB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLATB_T1;
}

function SMLABT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLABT_T1;
}

function SMLABB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLABB_T1;
}

function SMUADX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMUADX_T1;
}

function SMUAD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMUAD_T1;
}

function SMLADX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLADX_T1;
}

function SMLAD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLAD_T1;
}

function SMULWT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULWT_T1;
}

function SMULWB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULWB_T1;
}

function SMLAWT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLAWT_T1;
}

function SMLAWB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLAWB_T1;
}

function SMUSDX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMUSDX_T1;
}

function SMUSD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMUSD_T1;
}

function SMLSDX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLSDX_T1;
}

function SMLSD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLSD_T1;
}

function SMMULR_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMMULR_T1;
}

function SMMUL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMMUL_T1;
}

function SMMLAR_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMMLAR_T1;
}

function SMMLA_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMMLA_T1;
}

function SMMLSR_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMMLSR_T1;
}

function SMMLS_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMMLS_T1;
}

function USADA8 (_word: number): INSTRUCTION {
  return INSTRUCTION.USADA8;
}

function USAD8 (_word: number): INSTRUCTION {
  return INSTRUCTION.USAD8;
}

function LSL_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LSL_REG_T2;
}

function LSR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LSR_REG_T2;
}

function ASR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.ASR_REG_T2;
}

function ROR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.ROR_REG_T2;
}

function SXTH_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.SXTH_T2;
}

function SXTAH_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SXTAH_T1;
}

function UXTH_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.UXTH_T2;
}

function UXTAH_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UXTAH_T1;
}

function SXTB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SXTB16_T1;
}

function SXTAB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SXTAB16_T1;
}

function UXTB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UXTB16_T1;
}

function UXTAB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UXTAB16_T1;
}

function SXTB_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.SXTB_T2;
}

function SXTAB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SXTAB_T1;
}

function UXTB_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.UXTB_T2;
}

function UXTAB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UXTAB_T1;
}

function QADD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QADD_T1;
}

function QDADD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QDADD_T1;
}

function QSUB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QSUB_T1;
}

function QDSUB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QDSUB_T1;
}

function REV_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.REV_T2;
}

function REV16_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.REV16_T2;
}

function RBIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.RBIT_T1;
}

function REVSH_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.REVSH_T2;
}

function SEL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SEL_T1;
}

function CLZ_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.CLZ_T1;
}

function SADD8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SADD8_T1;
}

function SADD16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SADD16_T1;
}

function SASX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SASX_T1;
}

function SSUB8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SSUB8_T1;
}

function SSUB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SSUB16_T1;
}

function SSAX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SSAX_T1;
}

function QADD8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QADD8_T1;
}

function QADD16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QADD16_T1;
}

function QASX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QASX_T1;
}

function QSUB8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QSUB8_T1;
}

function QSUB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QSUB16_T1;
}

function QSAX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.QSAX_T1;
}

function SHADD8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SHADD8_T1;
}

function SHADD16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SHADD16_T1;
}

function SHASX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SHASX_T1;
}

function SHSUB8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SHSUB8_T1;
}

function SHSUB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SHSUB16_T1;
}

function SHSAX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SHSAX_T1;
}

function UADD8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UADD8_T1;
}

function UADD16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UADD16_T1;
}

function UASX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UASX_T1;
}

function USUB8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.USUB8_T1;
}

function USUB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.USUB16_T1;
}

function USAX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.USAX_T1;
}

function UQADD8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UQADD8_T1;
}

function UQADD16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UQADD16_T1;
}

function UQASX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UQASX_T1;
}

function UQSUB8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UQSUB8_T1;
}

function UQSUB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UQSUB16_T1;
}

function UQSAX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UQSAX_T1;
}

function UHADD8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UHADD8_T1;
}

function UHADD16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UHADD16_T1;
}

function UHASX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UHASX_T1;
}

function UHSUB8_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UHSUB8_T1;
}

function UHSUB16_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UHSUB16_T1;
}

function UHSAX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UHSAX_T1;
}

function LDR_LIT_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDR_LIT_T2;
}

function LDR_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDR_IMM_T3;
}

function LDR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDR_REG_T2;
}

function LDR_IMM_T4 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDR_IMM_T4;
}

function LDRT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRT_T1;
}

function LDRH_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRH_LIT_T1;
}

function LDRSH_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSH_LIT_T1;
}

function LDRH_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRH_IMM_T3;
}

function LDRSH_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSH_IMM_T1;
}

function LDRH_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRH_REG_T2;
}

function LDRHT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRHT_T1;
}

function LDRSH_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSH_REG_T2;
}

function LDRSH_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSH_IMM_T2;
}

function LDRSHT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSHT_T1;
}

function PLD_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLD_LIT_T1;
}

function PLI_IMM_LIT_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLI_IMM_LIT_T3;
}

function PLD_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLD_IMM_T1;
}

function PLI_IMM_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLI_IMM_LIT_T1;
}

function PLD_REG_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLD_REG_T1;
}

function PLD_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLD_IMM_T2;
}

function PLI_REG_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLI_REG_T1;
}

function idCoprocessorInstr (word: number): INSTRUCTION {
  const op1 = (word >>> 20) & 0b111111;
  const op = (word >>> 4) & 0b1;

  if (((op1 >>> 4) & 0b11) === 0b10) {
    if (op === 0) return idCDP(word);
    return ((op1 & 0b1) === 0b1)
      ? idMCR(word)
      : idMRC(word);
  }

  if ((op1 | 0b000101) === 0b000101) {
    return ((op1 & 0b100) === 0b100)
      ? ((op1 & 0b1) === 0b1)
        ? idMRRC(word)
        : idMCRR(word)
      : INSTRUCTION.UNDEFINED;
  }

  if ((op1 >>> 5) === 0b0) {
    return ((op1 & 0b1) === 0b1)
      ? idLDC(word)
      : idSTC(word);
  }

  return INSTRUCTION.UNDEFINED;
}

function idMoveAndImmShift (word: number): INSTRUCTION {
  const type = (word >>> 4) & 0b11;
  const imm2 = (word >>> 6) & 0b11;
  const imm3 = (word >>> 12) & 0b111;
  const immIs0 = (imm2 + imm3) === 0;

  switch (type) {
    case 0b00: return immIs0 ? MOV_REG_T3(word) : LSL_IMM_T2(word);
    case 0b01: return LSR_IMM_T2(word);
    case 0b10: return ASR_IMM_T2(word);
    case 0b11: return immIs0 ? RRX_T1(word) : ROR_IMM_T1(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idDataProcessingShifted (word: number): INSTRUCTION {
  const op = (word >>> 21) & 0b1111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;
  const RD_PC = ((word >>>  8) & 0b1111) === 0b1111;
  const S  = (word >>> 20) & 0b1;

  switch (op) {
    case 0b0000: return RD_PC ? (S ? TST_REG_T2(word) : INSTRUCTION.UNPREDICTABLE) : AND_REG_T2(word);
    case 0b0001: return BIC_REG_T2(word);
    case 0b0010: return RN_PC ? idMoveAndImmShift(word) : ORR_REG_T2(word);
    case 0b0011: return RN_PC ? MVN_REG_T2(word) : ORN_REG_T1(word);
    case 0b0100: return RD_PC ? (S ? TEQ_REG_T1(word) : INSTRUCTION.UNPREDICTABLE) : EOR_REG_T2(word);
    case 0b0110: return PKHBT_T1(word);
    case 0b1000: return RD_PC ? (S ? CMN_REG_T2(word) : INSTRUCTION.UNPREDICTABLE) : ADD_REG_T3(word);
    case 0b1010: return ADC_REG_T2(word);
    case 0b1011: return SBC_REG_T2(word);
    case 0b1101: return RD_PC ? (S ? CMP_REG_T3(word) : INSTRUCTION.UNPREDICTABLE) : SUB_REG_T2(word);
    case 0b1110: return RSB_REG_T1(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idLdrStrMultiple (word: number) {
  const op = (word >>> 23) & 0b11;
  const L = (word >>> 20) & 0b1;
  const W = (word >>> 21) & 0b1;
  const RN = (word >>> 16) & 0b1111;
  const cond = (W === 0b1) && (RN === 0b1101);

  switch (op) {
    case 0b01: return (L === 0)
      ? STM_T2(word)
      : cond
        ? POP_T2(word)
        : LDM_T2(word);
    case 0b10: return L
      ? LDMDB_T1(word)
      : cond
        ? PUSH_T2(word)
        : STMDB_T1(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idLdrStrDual (word: number): INSTRUCTION {
  const op1 = (word >>> 23) & 0b11;
  const op2 = (word >>> 20) & 0b11;
  const op3 = (word >>> 4) & 0b1111;

  switch (op1) {
    case 0b00: switch (op2) {
        case 0b00: return STREX_T1(word);
        case 0b01: return LDREX_T1(word);
        case 0b10: return STRD_IMM_T1(word);
        case 0b11: return idLDRD(word);
        default: return INSTRUCTION.UNDEFINED;
      }
    case 0b01: switch (op2) {
        case 0b00: switch (op3) {
            case 0b0100: return STREXB_T1(word);
            case 0b0101: return STREXH_T1(word);
            default: return INSTRUCTION.UNDEFINED;
          }
        case 0b01: switch (op3) {
            case 0b0000: return TBB_T1(word);
            case 0b0001: return TBH_T1(word);
            case 0b0100: return LDREXB_T1(word);
            case 0b0101: return LDREXH_T1(word);
            default: return INSTRUCTION.UNDEFINED;
          }
        case 0b10: return STRD_IMM_T1(word);
        case 0b11: return idLDRD(word);
        default: return INSTRUCTION.UNDEFINED;
      }
    default: return (op2 % 2 === 0) ? STRD_IMM_T1(word) : idLDRD(word);
  }
}

function idHint (word: number): INSTRUCTION {
  const op1 = (word >>> 8) & 0b111;
  const op2 = word & 0b11111111;
  if (op1 !== 0b000) return INSTRUCTION.UNDEFINED;

  switch (op2) {
    case 0b00000000: return NOP_T2(word);
    case 0b00000001: return YIELD_T2(word);
    case 0b00000010: return WFE_T2(word);
    case 0b00000011: return WFI_T2(word);
    case 0b00000100: return SEV_T2(word);
    default:
      return ((op2 & 0b11110000) === 0b11110000)
        ? DBG_T1(word)
        : INSTRUCTION.UNDEFINED;
  }
}

function idMiscControl (word: number): INSTRUCTION {
  const op = (word >>> 4) & 0b1111;
  switch (op) {
    case 0b0010: return CLREX_T1(word);
    case 0b0100: return DSB_T1(word);
    case 0b0101: return DMB_T1(word);
    case 0b0110: return ISB_T1(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idBranchesAndMisc (word: number): INSTRUCTION {
  const op1 = (word >>> 12) & 0b111;
  const op = (word >>> 20) & 0b1111111;

  if (op1 === 0b010 && op === 0b1111111) return INSTRUCTION.UNDEFINED;

  switch (op1 & 0b101) {
    case 0b101: return BL_T1(word);
    case 0b001: return B_T4(word);
    case 0b000:
      if (((op >>> 3) & 0b111) !== 0b111) return B_T3(word);
      switch (op) {
        case 0b0111000:
        case 0b0111001: return MSR_T1(word);
        case 0b0111010: return idHint(word);
        case 0b0111011: return idMiscControl(word);
        case 0b0111110:
        case 0b0111111: return MRS_T1(word);
        default: return INSTRUCTION.UNDEFINED;
      }
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idDataProcModifiedImmediate (word: number): INSTRUCTION {
  const op = (word >>> 20) & 0b11111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;
  const RD_PC = ((word >>>  8) & 0b1111) === 0b1111;

  const opEff = op >>> 1; // the table uses `op`, but all ignore the last bit

  switch (opEff) {
    case 0b0000: return RD_PC ? TST_IMM_T1(word) : AND_IMM_T1(word);
    case 0b0001: return BIC_IMM_T1(word);
    case 0b0010: return RN_PC ? MOV_IMM_T2(word) : ORR_IMM_T1(word);
    case 0b0011: return RN_PC ? MVN_IMM_T1(word) : ORN_IMM_T1(word);
    case 0b0100: return RD_PC ? TEQ_IMM_T1(word) : EOR_IMM_T1(word);
    case 0b1000: return RD_PC ? CMN_IMM_T1(word) : ADD_IMM_T3(word);
    case 0b1010: return ADC_IMM_T1(word);
    case 0b1011: return SBC_IMM_T1(word);
    case 0b1101: return RD_PC ? CMP_IMM_T2(word) : SUB_IMM_T3(word);
    case 0b1110: return RSB_IMM_T2(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idDataProcPlainBinaryImmediate (word: number): INSTRUCTION {
  const op = (word >>> 20) & 0b11111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;
  const imm5is0 = ((word >>> 12) & 0b111) + ((word >>> 6) & 0b11) > 0;

  switch (op) {
    case 0b00000: return RN_PC ? ADR_T3(word) : ADD_IMM_T4(word);
    case 0b00100: return MOV_IMM_T3(word);
    case 0b01010: return RN_PC ? ADR_T2(word) : SUB_IMM_T4(word);
    case 0b01100: return MOVT_T1(word);
    case 0b10000: return SSAT_T1(word);
    case 0b10010: return imm5is0 ? SSAT16_T1(word) : SSAT_T1(word);
    case 0b10100: return SBFX_T1(word);
    case 0b10110: return RN_PC ? BFC_T1(word) : BFI_T1(word);
    case 0b11000: return USAT_T1(word);
    case 0b11010: return imm5is0 ? USAT16_T1(word) : USAT_T1(word);
    case 0b11100: return UBFX_T1(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idMultiplyDiff (word: number): INSTRUCTION {
  if (((word >>> 6) & 0b11) !== 0b00) return INSTRUCTION.UNDEFINED;
  const op1 = (word >>> 20) & 0b111;
  const op2 = (word >>> 4) & 0b11;
  if ((op2 & 0b10) > 0 && op1 !== 0b001) return INSTRUCTION.UNDEFINED;
  const RA_PC = ((word >>> 12) & 0b1111) === 0b1111;
  const X = ((word >>> 4) & 0b1) === 0b1;
  const W = ((word >>> 5) & 0b1) === 0b1;

  switch (op1) {
    case 0b000: return (op2 === 0b00)
      ? RA_PC
        ? MUL_T2(word)
        : MLA_T1(word)
      : MLS_T1(word);
    case 0b001: return RA_PC
      ? W
        ? (X ? SMULTT_T1(word) : SMULTB_T1(word))
        : (X ? SMULBT_T1(word) : SMULBB_T1(word))
      : W
        ? (X ? SMLATT_T1(word) : SMLATB_T1(word))
        : (X ? SMLABT_T1(word) : SMLABB_T1(word));
    case 0b010: return RA_PC
      ? (X ? SMUADX_T1(word) : SMUAD_T1(word))
      : (X ? SMLADX_T1(word) : SMLAD_T1(word));
    case 0b011: return RA_PC
      ? (X ? SMULWT_T1(word) : SMULWB_T1(word))
      : (X ? SMLAWT_T1(word) : SMLAWB_T1(word));
    case 0b100: return RA_PC
      ? (X ? SMUSDX_T1(word) : SMUSD_T1(word))
      : (X ? SMLSDX_T1(word) : SMLSD_T1(word));
    case 0b101: return RA_PC
      ? (X ? SMMULR_T1(word) : SMMUL_T1(word))
      : (X ? SMMLAR_T1(word) : SMMLA_T1(word));
    case 0b110: return X ? SMMLSR_T1(word) : SMMLS_T1(word);
    case 0b111:
      if (op2 !== 0b00) return INSTRUCTION.UNDEFINED;
      return RA_PC ? USADA8(word) : USAD8(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idMiscOperations (word: number): INSTRUCTION {
  if (((word >>> 12) & 0b1111) !== 0b1111) return INSTRUCTION.UNDEFINED;
  const op1 = (word >>> 20) & 0b11;
  const op2 = (word >>> 4) & 0b11;

  switch (op1) {
    case 0b00: switch (op2) {
      case 0b00: return QADD_T1(word);
      case 0b01: return QDADD_T1(word);
      case 0b10: return QSUB_T1(word);
      case 0b11: return QDSUB_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b01: switch (op2) {
      case 0b00: return REV_T2(word);
      case 0b01: return REV16_T2(word);
      case 0b10: return RBIT_T1(word);
      case 0b11: return REVSH_T2(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b10: return (op2 === 0) ? SEL_T1(word) : INSTRUCTION.UNDEFINED;
    case 0b11: return (op2 === 0) ? CLZ_T1(word) : INSTRUCTION.UNDEFINED;
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idParallelAddSubSigned (word: number): INSTRUCTION {
  if (((word >>> 12) & 0b1111) !== 0b1111) return INSTRUCTION.UNDEFINED;
  const op1 = (word >>> 20) & 0b11;
  const op2 = (word >>> 4) & 0b11;

  switch (op2) {
    case 0b00: switch (op1) {
      case 0b000: return SADD8_T1(word);
      case 0b001: return SADD16_T1(word);
      case 0b010: return SASX_T1(word);
      case 0b100: return SSUB8_T1(word);
      case 0b101: return SSUB16_T1(word);
      case 0b110: return SSAX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b01: switch (op1) {
      case 0b000: return QADD8_T1(word);
      case 0b001: return QADD16_T1(word);
      case 0b010: return QASX_T1(word);
      case 0b100: return QSUB8_T1(word);
      case 0b101: return QSUB16_T1(word);
      case 0b110: return QSAX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b10: switch (op1) {
      case 0b000: return SHADD8_T1(word);
      case 0b001: return SHADD16_T1(word);
      case 0b010: return SHASX_T1(word);
      case 0b100: return SHSUB8_T1(word);
      case 0b101: return SHSUB16_T1(word);
      case 0b110: return SHSAX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idParallelAddSubUnsigned (word: number): INSTRUCTION {
  if (((word >>> 12) & 0b1111) !== 0b1111) return INSTRUCTION.UNDEFINED;
  const op1 = (word >>> 20) & 0b11;
  const op2 = (word >>> 4) & 0b11;

  switch (op2) {
    case 0b00: switch (op1) {
      case 0b000: return UADD8_T1(word);
      case 0b001: return UADD16_T1(word);
      case 0b010: return UASX_T1(word);
      case 0b100: return USUB8_T1(word);
      case 0b101: return USUB16_T1(word);
      case 0b110: return USAX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b01: switch (op1) {
      case 0b000: return UQADD8_T1(word);
      case 0b001: return UQADD16_T1(word);
      case 0b010: return UQASX_T1(word);
      case 0b100: return UQSUB8_T1(word);
      case 0b101: return UQSUB16_T1(word);
      case 0b110: return UQSAX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b10: switch (op1) {
      case 0b000: return UHADD8_T1(word);
      case 0b001: return UHADD16_T1(word);
      case 0b010: return UHASX_T1(word);
      case 0b100: return UHSUB8_T1(word);
      case 0b101: return UHSUB16_T1(word);
      case 0b110: return UHSAX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idDataProcRegister (word: number): INSTRUCTION {
  // 1111 1010 aaaa nnnn 1111 ---- bbbb ----
  if (((word >>> 12) & 0b1111) !== 0b1111) return INSTRUCTION.UNDEFINED;

  const op1 = (word >>> 20) & 0b1111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;
  const op2 = (word >>> 4) & 0b1111;
  const op1StartsWith1 = (op1 & 0b1000) > 0;
  const op2StartsWith1 = (op2 & 0b1000) > 0;

  if (op2StartsWith1) {
    switch (op1) {
      case 0b0000: return RN_PC ? SXTH_T2(word) : SXTAH_T1(word);
      case 0b0001: return RN_PC ? UXTH_T2(word) : UXTAH_T1(word);
      case 0b0010: return RN_PC ? SXTB16_T1(word) : SXTAB16_T1(word);
      case 0b0011: return RN_PC ? UXTB16_T1(word) : UXTAB16_T1(word);
      case 0b0100: return RN_PC ? SXTB_T2(word) : SXTAB_T1(word);
      case 0b0101: return RN_PC ? UXTB_T2(word) : UXTAB_T1(word);
      default: return ((op2 & 0b0100) === 0 && (op1 & 0b1100) === 0b1000)
        ? idMiscOperations(word)
        : INSTRUCTION.UNDEFINED;
    }
  }

  if (op1StartsWith1) {
    return ((op2 & 0b0100) > 0)
      ? idParallelAddSubUnsigned(word)
      : idParallelAddSubSigned(word);
  }

  if (op2 !== 0) return INSTRUCTION.UNDEFINED;

  switch (op1 >>> 1) {
    case 0b000: return LSL_REG_T2(word);
    case 0b001: return LSR_REG_T2(word);
    case 0b010: return ASR_REG_T2(word);
    case 0b011: return ROR_REG_T2(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idLoadWord (word: number): INSTRUCTION {
  const op1 = (word >>> 23) & 0b11;
  const op2 = (word >>> 6) & 0b111111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;

  if ((op1 & 0b10) > 0) return INSTRUCTION.UNDEFINED;

  if (RN_PC) return LDR_LIT_T2(word);

  if (op1 === 0b01) return LDR_IMM_T3(word);

  if (op2 === 0) return LDR_REG_T2(word);

  const op3 = op2 >>> 2;

  if (op3 === 0b1100 || (op3 & 0b1001) === 0b1001) return LDR_IMM_T4(word);

  if (op3 === 0b1110) return LDRT_T1(word);

  return INSTRUCTION.UNDEFINED;
}

function PLD_IMM_LIT_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.PLD_IMM_LIT_T2;
}

function LDRB_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRB_LIT_T1;
}

function LDRSB_LIT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSB_LIT_T1;
}

function LDRB_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRB_IMM_T2;
}

function LDRSB_IMM_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSB_IMM_T1;
}

function LDRB_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRB_REG_T2;
}

function LDRB_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRB_IMM_T3;
}

function LDRBT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRBT_T1;
}

function LDRSB_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSB_REG_T2;
}

function LDRSB_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSB_IMM_T2;
}

function LDRSBT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.LDRSBT_T1;
}

function STRB_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRB_REG_T2;
}

function STRB_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRB_IMM_T3;
}

function STRH_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRH_REG_T2;
}

function STRH_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRH_IMM_T3;
}

function STR_REG_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.STR_REG_T2;
}

function STR_IMM_T4 (_word: number): INSTRUCTION {
  return INSTRUCTION.STR_IMM_T4;
}

function STRB_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRB_IMM_T2;
}

function STRH_IMM_T2 (_word: number): INSTRUCTION {
  return INSTRUCTION.STRH_IMM_T2;
}

function STR_IMM_T3 (_word: number): INSTRUCTION {
  return INSTRUCTION.STR_IMM_T3;
}

function SMULL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMULL_T1;
}

function SDIV_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SDIV_T1;
}

function UMULL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UMULL_T1;
}

function UDIV_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UDIV_T1;
}

function SMLAL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLAL_T1;
}

function SMLALBB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLALBB_T1;
}

function SMLALBT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLALBT_T1;
}

function SMLALTB_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLALTB_T1;
}

function SMLALTT_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLALTT_T1;
}

function SMALD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMALD_T1;
}

function SMALDX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMALDX_T1;
}

function SMLSLD_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLSLD_T1;
}

function SMLSLDX_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.SMLSLDX_T1;
}

function UMLAL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UMLAL_T1;
}

function UMAAL_T1 (_word: number): INSTRUCTION {
  return INSTRUCTION.UMAAL_T1;
}

function idLoadHalfWord (word: number): INSTRUCTION {
  const op1 = (word >>> 23) & 0b11;
  const op2 = (word >>> 6) & 0b111111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;
  const RT_PC = ((word >>> 12) & 0b1111) === 0b1111;

  if (RN_PC) {
    return RT_PC
      ? ((op1 & 0b10) > 0)
        ? INSTRUCTION.UNALLOCATED
        : INSTRUCTION.UNPREDICTABLE
      : ((op1 & 0b10) === 0)
        ? LDRH_LIT_T1(word)
        : LDRSH_LIT_T1(word);
  }

  if (RT_PC) {
    if ((op1 & 0b01) > 0) return INSTRUCTION.UNALLOCATED;

    if (op2 === 0 || (op2 & 0b111100) === 0b1100) {
      return INSTRUCTION.UNALLOCATED;
    }

    if ((op2 & 0b100100) === 0b100100 || (op2 & 0b111100) === 0b111000) {
      return INSTRUCTION.UNPREDICTABLE;
    }

    return INSTRUCTION.UNDEFINED;
  }

  switch (op1) {
    case 0b01: return LDRH_IMM_T3(word);
    case 0b11: return LDRSH_IMM_T1(word);
    case 0b00:
      if (op2 === 0) return LDRH_REG_T2(word);
      if ((op2 & 0b100100) === 0b100100) return LDRH_IMM_T3(word);
      if ((op2 & 0b111100) === 0b110000) return LDRH_IMM_T3(word);
      if ((op2 & 0b111100) === 0b111000) return LDRHT_T1(word);
      return INSTRUCTION.UNDEFINED;
    case 0b10:
      if (op2 === 0) return LDRSH_REG_T2(word);
      if ((op2 & 0b100100) === 0b100100) return LDRSH_IMM_T2(word);
      if ((op2 & 0b111100) === 0b110000) return LDRSH_IMM_T2(word);
      if ((op2 & 0b111100) === 0b111000) return LDRSHT_T1(word);
      return INSTRUCTION.UNDEFINED;
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idLoadByte (word: number): INSTRUCTION {
  const op1 = (word >>> 23) & 0b11;
  const op2 = (word >>> 6) & 0b111111;
  const RN_PC = ((word >>> 16) & 0b1111) === 0b1111;
  const RT_PC = ((word >>> 12) & 0b1111) === 0b1111;

  if (RT_PC) {
    if (RN_PC) {
      switch (op1) {
        case 0b00:
        case 0b01: return PLD_LIT_T1(word);
        case 0b10:
        case 0b11: return PLI_IMM_LIT_T3(word);
        default: return INSTRUCTION.UNDEFINED;
      }
    }

    switch (op1) {
      case 0b01: return PLD_IMM_T1(word);
      case 0b11: return PLI_IMM_LIT_T1(word);
      case 0b00:
        if (op2 === 0) return PLD_REG_T1(word);
        if ((op2 & 0b100100) === 0b100100) return INSTRUCTION.UNPREDICTABLE;
        if ((op2 & 0b111100) === 0b110000) return PLD_IMM_T2(word);
        if ((op2 & 0b111100) === 0b111000) return INSTRUCTION.UNPREDICTABLE;
        return INSTRUCTION.UNDEFINED;
      case 0b10:
        if (op2 === 0) return PLI_REG_T1(word);
        if ((op2 & 0b100100) === 0b100100) return INSTRUCTION.UNPREDICTABLE;
        if ((op2 & 0b111100) === 0b110000) return PLD_IMM_LIT_T2(word);
        if ((op2 & 0b111100) === 0b111000) return INSTRUCTION.UNPREDICTABLE;
        return INSTRUCTION.UNDEFINED;
      default: return INSTRUCTION.UNDEFINED;
    }
  }

  if (RN_PC) {
    switch (op1) {
      case 0b00:
      case 0b01: return LDRB_LIT_T1(word);
      case 0b10:
      case 0b11: return LDRSB_LIT_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
  }

  switch (op1) {
    case 0b01: return LDRB_IMM_T2(word);
    case 0b11: return LDRSB_IMM_T1(word);
    case 0b00:
      if (op2 === 0) return LDRB_REG_T2(word);
      if ((op2 & 0b100100) === 0b100100) return LDRB_IMM_T3(word);
      if ((op2 & 0b111100) === 0b110000) return LDRB_IMM_T3(word);
      if ((op2 & 0b111100) === 0b111000) return LDRBT_T1(word);
      return INSTRUCTION.UNDEFINED;
    case 0b10:
      if (op2 === 0) return LDRSB_REG_T2(word);
      if ((op2 & 0b100100) === 0b100100) return LDRSB_IMM_T2(word);
      if ((op2 & 0b111100) === 0b110000) return LDRSB_IMM_T2(word);
      if ((op2 & 0b111100) === 0b111000) return LDRSBT_T1(word);
      return INSTRUCTION.UNDEFINED;
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idStoreSingle (word: number): INSTRUCTION {
  const op1 = (word >>> 21) & 0b111;
  const op2Eff = (word >>> 11) & 0b1;

  switch (op1) {
    case 0b000: return (op2Eff === 0) ? STRB_REG_T2(word) : STRB_IMM_T3(word);
    case 0b001: return (op2Eff === 0) ? STRH_REG_T2(word) : STRH_IMM_T3(word);
    case 0b010: return (op2Eff === 0) ? STR_REG_T2(word) : STR_IMM_T4(word);
    case 0b100: return STRB_IMM_T2(word);
    case 0b101: return STRH_IMM_T2(word);
    case 0b110: return STR_IMM_T3(word);
    default: return INSTRUCTION.UNDEFINED;
  }
}

function idLongMultiplyDiff (word: number): INSTRUCTION {
  const op1 = (word >>> 20) & 0b111;
  const op2 = (word >>> 4) & 0b1111;

  switch (op1) {
    case 0b000: return (op2 === 0) ? SMULL_T1(word) : INSTRUCTION.UNDEFINED;
    case 0b001: return (op2 === 0b1111) ? SDIV_T1(word) : INSTRUCTION.UNDEFINED;
    case 0b010: return (op2 === 0) ? UMULL_T1(word) : INSTRUCTION.UNDEFINED;
    case 0b011: return (op2 === 0b1111) ? UDIV_T1(word) : INSTRUCTION.UNDEFINED;
    case 0b100:
      if (op2 === 0) return SMLAL_T1(word);
      switch (op2) {
        case 0b1000: return SMLALBB_T1(word);
        case 0b1001: return SMLALBT_T1(word);
        case 0b1010: return SMLALTB_T1(word);
        case 0b1011: return SMLALTT_T1(word);
        case 0b1100: return SMALD_T1(word);
        case 0b1101: return SMALDX_T1(word);
        default: return INSTRUCTION.UNDEFINED;
      }
    case 0b101: switch (op2) {
      case 0b1100: return SMLSLD_T1(word);
      case 0b1101: return SMLSLDX_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    case 0b110: switch (op2) {
      case 0b0000: return UMLAL_T1(word);
      case 0b0110: return UMAAL_T1(word);
      default: return INSTRUCTION.UNDEFINED;
    }
    default: return INSTRUCTION.UNDEFINED;
  }
}

export function identifyWideInstruction (word: number, halfWord: boolean = false): INSTRUCTION {
  if (halfWord) {
    // handle when we only have the first half of the command
    return INSTRUCTION.INVALID;
  }

  const op1 = (word >>> 27) & 0b11;
  const op2 = (word >>> 20) & 0b1111111;
  const op = (word >>> 15) & 0b1;

  switch (op1) {
    case 0b01:
      if ((op2 & 0b1100100) === 0b0000000) return idLdrStrMultiple(word);
      if ((op2 & 0b1100100) === 0b0000100) return idLdrStrDual(word);
      if ((op2 & 0b1100000) === 0b0100000) return idDataProcessingShifted(word);
      if ((op2 & 0b1000000) === 0b1000000) return idCoprocessorInstr(word);
      return INSTRUCTION.UNDEFINED;
    case 0b10:
      if (op) return idBranchesAndMisc(word);
      if (((op2 >>> 5) & 0b1) === 0b0) {
        return idDataProcModifiedImmediate(word);
      } else {
        return idDataProcPlainBinaryImmediate(word);
      }
    case 0b11:
      if ((op2 & 0b1000000) > 0) return idCoprocessorInstr(word);
      if (((op2 >>> 5) & 0b1) > 0) {
        return (((op2 >>> 4) & 0b1) > 0)
          ? (((op2 >>> 3) & 0b1) === 1)
            ? idLongMultiplyDiff(word)
            : idMultiplyDiff(word)
          : idDataProcRegister(word);
      }
      if ((op2 & 0b1110001) === 0) return idStoreSingle(word);
      switch (op2 & 0b111) {
        case 0b001: return idLoadByte(word);
        case 0b011: return idLoadHalfWord(word);
        case 0b101: return idLoadWord(word);
        default: break;
      }
      return INSTRUCTION.UNDEFINED;
    default:
      return INSTRUCTION.UNDEFINED; // the word is a narrow command
  }
}
