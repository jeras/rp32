///////////////////////////////////////////////////////////////////////////////
// R5P: Degu core
///////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////////////////////////////////////////////////////////////////////////////////

module r5p_degu
  import riscv_isa_pkg::*;
  import riscv_isa_i_pkg::*;
  import riscv_isa_c_pkg::*;
  //import riscv_csr_pkg::*;
  //import r5p_pkg::*;
  import r5p_degu_pkg::*;
  import tcb_lite_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  localparam int unsigned ILEN = 32,
  // RISC-V ISA
`ifndef SYNOPSYS_VERILOG_COMPILER
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
//parameter  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  parameter  isa_ext_t    XTEN = RV_C,
  // privilege modes
  parameter  isa_priv_t   MODES = MODES_M,
  // ISA
`ifdef ENABLE_CSR
  parameter  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES}
`else
  parameter  isa_t        ISA = '{spec: RV32I, priv: MODES_NONE},
`endif
`endif
  // system bus implementation details
  parameter  logic [XLEN-1:0] IFU_RST = 32'h0000_0000,  // reset vector
  parameter  logic [XLEN-1:0] IFU_MSK = 32'h803f_ffff,  // PC mask // TODO: check if this actually helps, or will synthesis minimize the mux-es anyway
  // optimizations: timing versus area compromises
  parameter  r5p_degu_cfg_t CFG = r5p_degu_cfg_def
)(
  // system signals
  input  logic clk,
  input  logic rst,
  // TCB system bus
  tcb_lite_if.man tcb_ifu,  // instruction fetch
  tcb_lite_if.man tcb_lsu   // load/store
);

`ifdef SYNOPSYS_VERILOG_COMPILER
parameter isa_t ISA = '{spec: RV32I, priv: MODES_NONE};
`endif

///////////////////////////////////////////////////////////////////////////////
// parameter validation
///////////////////////////////////////////////////////////////////////////////

// TODO

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

// instruction fetch
logic            ifu_run;  // running status
logic            ifu_tkn;  // taken
logic [XLEN-1:0] ifu_pc;   // program counter
logic [XLEN-1:0] ifu_pcn;  // program counter next
logic [XLEN-1:0] ifu_pcs;  // program counter sum

logic            stall;

// instruction decode
dec_t            idu_dec;  // control structure
logic            idu_vld;  // instruction valid

// GPR read
logic [XLEN-1:0] gpr_rs1;  // register source 1
logic [XLEN-1:0] gpr_rs2;  // register source 2

// ALU
logic [XLEN-1:0] alu_dat;  // register destination
logic [XLEN-0:0] alu_sum;  // summation result including overflow bit

// MUL/DIV/REM
logic [XLEN-1:0] mul_dat;  // multiplier unit output

// CSR
logic [XLEN-1:0] csr_rdt;  // read  data

// CSR address map union
`ifdef VERILATOR
//csr_map_ut       csr_csr;
`endif

logic [XLEN-1:0] csr_tvec;
logic [XLEN-1:0] csr_epc ;

// load/sore unit temporary signals
logic [XLEN-1:0] lsu_adr;  // address
logic [XLEN-1:0] lsu_wdt;  // write data
logic [XLEN-1:0] lsu_rdt;  // read data
logic            lsu_mal;  // MisALigned
logic            lsu_rdy;  // ready

// write back unit (GPR destination register access)
logic            wbu_wen;  // write enable
logic    [5-1:0] wbu_adr;  // address
logic [XLEN-1:0] wbu_dat;  // data

///////////////////////////////////////////////////////////////////////////////
// instruction fetch
///////////////////////////////////////////////////////////////////////////////

// start running after reset
always_ff @(posedge clk, posedge rst)
if (rst)  ifu_run <= 1'b0;
else      ifu_run <= 1'b1;

// request becomes active after reset
assign tcb_ifu.vld = ifu_run;

// TODO
assign tcb_ifu.req.lck = 1'b0;
assign tcb_ifu.req.wen = 1'b0;
assign tcb_ifu.req.ren = 1'b1;
assign tcb_ifu.req.ctl = '0;
assign tcb_ifu.req.siz = 2'b10;  // 32-bit transfer size
assign tcb_ifu.req.byt = 'x;     // TODO: not really used for TCB RISC-V mode
assign tcb_ifu.req.wdt = 'x;

// instruction fetch is always little endian
assign tcb_ifu.req.ndn = 1'b0;

// PC next is used as IF address
assign tcb_ifu.req.adr = ifu_pcn;

// instruction valid
always_ff @(posedge clk, posedge rst)
if (rst)  idu_vld <= 1'b0;
else      idu_vld <= tcb_ifu.trn | (idu_vld & stall);

///////////////////////////////////////////////////////////////////////////////
// program counter
///////////////////////////////////////////////////////////////////////////////

// TODO:
assign stall = (tcb_ifu.vld & ~tcb_ifu.rdy) | (tcb_lsu.vld & ~tcb_lsu.rdy);
//assign stall = tcb_ifu.stl | tcb_lsu.stl;

// program counter
always_ff @(posedge clk, posedge rst)
if (rst)  ifu_pc <= IFU_RST;
else begin
    if (idu_vld & ~stall) ifu_pc <= ifu_pcn & IFU_MSK;
end

generate
if (CFG.BRU_BRU) begin: gen_bru_ena

  // branch ALU for checking branch conditions
  r5p_bru #(
    .XLEN    (XLEN)
  ) br (
    // control
    .dec     (idu_dec),
    // data
    .rs1     (gpr_rs1),
    .rs2     (gpr_rs2),
    // status
    .tkn     (ifu_tkn)
  );

end: gen_bru_ena
else begin: gen_bru_alu

  always_comb
  unique case (fn3_bru_et'(idu_dec.fn3))
    BEQ    : ifu_tkn = ~(|alu_sum[XLEN-1:0]);
    BNE    : ifu_tkn =  (|alu_sum[XLEN-1:0]);
    BLT    : ifu_tkn =    alu_sum[XLEN];
    BGE    : ifu_tkn = ~  alu_sum[XLEN];
    BLTU   : ifu_tkn =    alu_sum[XLEN];
    BGEU   : ifu_tkn = ~  alu_sum[XLEN];
    default: ifu_tkn = 'x;
  endcase

end: gen_bru_alu
endgenerate

// TODO: optimization parameters
// split PC adder into 12-bit immediate adder and the rest is an incrementer/decrementer, calculate both increment and decrement in advance.

generate
if (CFG.BRU_BRA) begin: gen_bra_add
  // simultaneous running adders, multiplexer with a late select signal
  // requires more adder logic improves timing
  logic [XLEN-1:0] ifu_pci;  // PC incrementer
  logic [XLEN-1:0] ifu_pcb;  // PC branch address adder

  // PC incrementer
  assign ifu_pci = ifu_pc + XLEN'(idu_dec.siz);

  // branch address
  assign ifu_pcb = ifu_pc +       idu_dec.i_b ;

  // PC adder result multiplexer
  assign ifu_pcs = (idu_dec.opc == BRANCH) & ifu_tkn ? ifu_pcb
                                                     : ifu_pci;

end: gen_bra_add
else begin: gen_bra_mux
  // the same adder is shared for next and branch address
  // least logic area
  logic [XLEN-1:0] ifu_pca;  // PC addend

  // PC addend multiplexer
  assign ifu_pca = (idu_dec.opc == BRANCH) & ifu_tkn ?       idu_dec.i_b
                                                     : XLEN'(idu_dec.siz);

  // PC sum
  assign ifu_pcs = ifu_pc + ifu_pca;

end: gen_bra_mux
endgenerate

// program counter next
always_comb
if (tcb_ifu.rdy & idu_vld) begin
  unique case (idu_dec.opc)
    JAL    ,
    JALR   : ifu_pcn = {alu_sum[XLEN-1:1], 1'b0};
    BRANCH : ifu_pcn = ifu_pcs;
//  PC_TRP : ifu_pcn = XLEN'(csr_tvec);
//  PC_EPC : ifu_pcn = XLEN'(csr_epc);
    default: ifu_pcn = ifu_pcs;
  endcase
end else begin
  ifu_pcn = ifu_pc;
end

///////////////////////////////////////////////////////////////////////////////
// instruction decode
///////////////////////////////////////////////////////////////////////////////


// TODO: uncomment this code
  generate
  `ifndef ALTERA_RESERVED_QIS
  if (ISA.spec.ext.C) begin: gen_d16
  `else
  if (1'b1) begin: gen_d16
  `endif
    dec_t          idu_tmp;

    // 16/32-bit instruction decoder
    always_comb
    unique case (opsiz(tcb_ifu.rsp.rdt[16-1:0]))
      2      : idu_tmp = dec16(ISA, tcb_ifu.rsp.rdt[16-1:0]);  // 16-bit C standard extension
      4      : idu_tmp = dec32(ISA, tcb_ifu.rsp.rdt[32-1:0]);  // 32-bit
      default: idu_tmp = '{ill: ILL, opc: opc_t'('x), default: 'x};  // OP sizes above 4 bytes are not supported
    endcase

    // distributed I/C decoder mux
  //if (CFG.DEC_DIS) begin: gen_dec_dis
    if (1'b1) begin: gen_dec_dis
      assign idu_dec = idu_tmp;
    end: gen_dec_dis
    // 32-bit I/C decoder mux
    else begin
      (* keep = "true" *)
      logic [32-1:0] idu_enc;

      assign idu_enc = enc32(ISA, idu_tmp);
      always_comb
      begin
        idu_dec     = 'x;
        idu_dec     = dec32(ISA, idu_enc);
        idu_dec.siz = idu_tmp.siz;
      end
    end

  end: gen_d16
  else begin: gen_d32

    // 32-bit instruction decoder
    assign idu_dec = dec32(ISA, tcb_ifu.rsp.rdt[32-1:0]);

//  // enc32 debug code
//  dec_t  idu_tmp;
//  logic [32-1:0] idu_enc;
//  assign idu_tmp = dec32(ISA, tcb_ifu.rsp.rdt[32-1:0]);
//  assign idu_enc = enc32(ISA, idu_tmp);
//  assign idu_dec = dec32(ISA, idu_enc);

  end: gen_d32
  endgenerate

///////////////////////////////////////////////////////////////////////////////
// execute
///////////////////////////////////////////////////////////////////////////////

// TODO: check if access should be blocked during reset
// general purpose registers
r5p_gpr_2r1w #(
//  .AW      (ISA.spec.base.E ? 4 : 5),
  .XLEN    (XLEN),
  .WBYP    (1'b1)
) gpr (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // configuration/control
  .en0     (1'b0),
  // read/write enable
  .e_rs1   (idu_dec.gpr.rs1),
  .e_rs2   (idu_dec.gpr.rs2),
  .e_rd    (    wbu_wen    ),  // TODO: should depend on LSU stall
  // read/write address
  .a_rs1   (idu_dec.rs1),
  .a_rs2   (idu_dec.rs2),
  .a_rd    (    wbu_adr),
  // read/write data
  .d_rs1   (    gpr_rs1),
  .d_rs2   (    gpr_rs2),
  .d_rd    (    wbu_dat)
);

  // base ALU
  r5p_alu #(
    // enable opcode
    .CFG_BRANCH (~CFG.BRU_BRU),
    .CFG_LOAD   (~CFG.ALU_LSA),
    .CFG_STORE  (~CFG.ALU_LSA),
    .CFG_AUIPC  (1'b1),
    .CFG_JAL    (1'b1),
    // optimizations: timing versus area compromises
    .CFG_LOM (CFG.ALU_LOM),
    .CFG_SOM (CFG.ALU_SOM),
    // FPGA specific optimizations
    .CFG_SHF (CFG.SHF)
  ) alu (
     // system signals
    .clk     (clk),
    .rst     (rst),
    // control
    .dec     (idu_dec),
    // data input/output
    .pc      (XLEN'(ifu_pc)),
    .rs1     (gpr_rs1),
    .rs2     (gpr_rs2),
    .rd      (alu_dat),
    // side outputs
    .sum     (alu_sum)
  );

`ifndef ALTERA_RESERVED_QIS
generate
if (ISA.spec.ext.M == 1'b1) begin: gen_mdu
/*
  // mul/div/rem unit
  r5p_mdu #(
    .XLEN    (XLEN)
  ) mdu (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // control
    .ctl     (idu_dec.m),
    // data input/output
    .rs1     (gpr_rs1),
    .rs2     (gpr_rs2),
    .rd      (mul_dat)
  );
*/
end: gen_mdu
else begin: gen_nomdu

  // data output
  assign mul_dat = 'x;

end: gen_nomdu
endgenerate
`endif

///////////////////////////////////////////////////////////////////////////////
// CSR
///////////////////////////////////////////////////////////////////////////////

//`ifndef ALTERA_RESERVED_QIS
//generate
//if (ISA.spec.ext.Zicsr) begin: gen_csr_ena
//
//  r5p_csr #(
//    .XLEN    (XLEN)
//  ) csr (
//    // system signals
//    .clk     (clk),
//    .rst     (rst),
//    // CSR address map union output
//    .csr_map (csr_csr),
//    // CSR control and data input/output
//    .csr_ctl (idu_dec.csr),
//    .csr_wdt (gpr_rs1),
//    .csr_rdt (csr_rdt),
//    // trap handler
//    .priv_i  (idu_dec.priv),
//    .trap_i  (idu_dec.i.pc == PC_TRP),
//  //.cause_i (CAUSE_EXC_OP_EBREAK),
//    .epc_i   (XLEN'(ifu_pc)),
//    .epc_o   (csr_epc ),
//    .tvec_o  (csr_tvec),
//    // hardware performance monitor
//    .event_i (r5p_hpmevent_t'(1))
//    // TODO: debugger, ...
//  );
//
//end: gen_csr_ena
//else begin: gen_csr_byp

  // CSR data output
  assign csr_rdt  = 'x;
  // trap handler
  assign csr_epc  = 'x;
  assign csr_tvec = 'x;

//end: gen_csr_byp
//endgenerate
//`endif

///////////////////////////////////////////////////////////////////////////////
// load/store
///////////////////////////////////////////////////////////////////////////////

generate
if (CFG.ALU_LSA) begin: gen_lsa_ena

  logic [XLEN-1:0] lsu_adr_ld;  // address load
  logic [XLEN-1:0] lsu_adr_st;  // address store

  // dedicated load/store adders
  assign lsu_adr_ld = gpr_rs1 + idu_dec.i_l;  // I-type (load)
  assign lsu_adr_st = gpr_rs1 + idu_dec.i_s;  // S-type (store)

  always_comb
  unique casez (idu_dec.opc)
    LOAD   : lsu_adr = lsu_adr_ld;  // I-type (load)
    STORE  : lsu_adr = lsu_adr_st;  // S-type (store)
    default: lsu_adr = 'x ;
  endcase

end:gen_lsa_ena
else begin: gen_lsa_alu

  // ALU is used to calculate load/store address
  assign lsu_adr = alu_sum[XLEN-1:0];

end: gen_lsa_alu
endgenerate

// intermediate signals
assign lsu_wdt = gpr_rs2;

// load/store unit
r5p_lsu #(
  .XLEN    (XLEN),
  // optimizations
  .CFG_VLD_ILL (CFG.VLD_ILL),
  .CFG_WEN_ILL (CFG.WEN_ILL),
  .CFG_WEN_IDL (CFG.WEN_IDL),
  .CFG_BEN_IDL (CFG.BEN_IDL),
  .CFG_BEN_ILL (CFG.BEN_ILL)
) lsu (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // control
  .dec     (idu_dec),
  // data input/output
  .run     (idu_vld),
  .ill     (1'b0),
//.ill     (idu_dec.ill == ILL),
  .adr     (lsu_adr),
  .wdt     (lsu_wdt),
  .rdt     (lsu_rdt),
  .mal     (lsu_mal),
  .rdy     (lsu_rdy),
  // data bus (load/store)
  .tcb     (tcb_lsu)
);

///////////////////////////////////////////////////////////////////////////////
// write back
///////////////////////////////////////////////////////////////////////////////

r5p_wbu #(
  .XLEN    (XLEN)
) wbu (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // control
  .dec     (idu_dec),
  // write data inputs
  .alu     (alu_dat),                 // ALU output
  .lsu     (lsu_rdt),                 // LSU load
  .pcs     (XLEN'(ifu_pcs)),          // PC increment
  .lui     (idu_dec.i_u),             // upper immediate
  .csr     (csr_rdt),                 // CSR
  .mul     (mul_dat),                 // mul/div/rem
  // GPR write back
  .wen     (wbu_wen),
  .adr     (wbu_adr),
  .dat     (wbu_dat)
);

endmodule: r5p_degu
