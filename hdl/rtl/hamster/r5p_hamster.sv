///////////////////////////////////////////////////////////////////////////////
// R5P: Hamster core
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

  import riscv_isa_i_pkg::*;
  import riscv_isa_c_pkg::*;
module r5p_hamster
  import riscv_isa_pkg::*;
  //import riscv_csr_pkg::*;
  //import r5p_pkg::*;
#(
  // RISC-V ISA
  int unsigned XLEN = 32,   // is used to quickly switch between 32 and 64 for testing
`ifndef SYNOPSYS_VERILOG_COMPILER
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C | RV_Zicsr,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
`ifdef ENABLE_CSR
  isa_t        ISA = '{spec: '{base: RV_32I , ext: XTEN}, priv: MODES}
`else
  isa_t        ISA = '{spec: RV32I, priv: MODES_NONE},
`endif
`endif
  // system bus
  int unsigned AW = 32,    // address width
  int unsigned DW = XLEN,  // data    width
  int unsigned BW = DW/8,  // byte en width
  // privilege implementation details
  logic [XLEN-1:0] PC0 = 'h0000_0000,   // reset vector
  // optimizations: timing versus area compromises
  // optimizations: BRU
  bit          CFG_BRU_BRU = 1'b0,  // enable dedicated BRanch Unit (comparator)
  bit          CFG_BRU_BRA = 1'b0,  // enable dedicated BRanch Adder
  // optimizations: ALU
  bit          CFG_ALU_LSA = 1'b0,  // enable dedicated Load/Store Adder
  bit          CFG_ALU_LOM = 1'b0,  // enable dedicated Logical Operand Multiplexer
  bit          CFG_ALU_SOM = 1'b0,  // enable dedicated Shift   Operand Multiplexer
  bit          CFG_ALU_L4M = 1'b1,  // enable dedicated 4 to 1 Logic    Multiplexer
  // optimizations: LSU
  logic        CFG_VLD_ILL = 1'bx,  // valid        for illegal instruction
  logic        CFG_WEN_ILL = 1'bx,  // write enable for illegal instruction
  logic        CFG_WEN_IDL = 1'bx,  // write enable for idle !(LOAD | STORE)
  logic        CFG_BEN_IDL = 1'bx,  // byte  enable for idle !(LOAD | STORE)
  logic        CFG_BEN_ILL = 1'bx,  // byte  enable for illegal instruction
  // FPGA specific optimizations
  int unsigned CFG_SHF     = 1,  // shift per stage, 1 - LUT4, 2 - LUT6, else no optimizations
  // implementation device (ASIC/FPGA vendor/device)
  string       CHIP = ""
)(
  // system signals
  input  logic          clk,
  input  logic          rst,
`ifdef TRACE_DEBUG
  // internal state signals
  output logic          dbg_ifu,  // indicator of instruction fetch
  output logic          dbg_lsu,  // indicator of load/store
`endif
  // TCL system bus (shared by instruction/load/store)
  output logic          bus_vld,  // valid
  output logic          bus_wen,  // write enable
  output logic [AW-1:0] bus_adr,  // address
  output logic [BW-1:0] bus_ben,  // byte enable
  output logic [DW-1:0] bus_wdt,  // write data
  input  logic [DW-1:0] bus_rdt,  // read data
  input  logic          bus_err,  // error
  input  logic          bus_rdy   // ready
);

`ifdef SYNOPSYS_VERILOG_COMPILER
parameter isa_t ISA = '{spec: RV32I, priv: MODES_NONE};
`endif

///////////////////////////////////////////////////////////////////////////////
// local definitions
///////////////////////////////////////////////////////////////////////////////

// SFM states
typedef enum logic {
  SIF = 1'b0,  // instruction fetch
  SLS = 1'b1   // load store
} fsm_et;

///////////////////////////////////////////////////////////////////////////////
// helper functions
///////////////////////////////////////////////////////////////////////////////

// extend sign to 33 bits
function logic signed [33-1:0] ext_sgn (logic signed [32-1:0] val);
  ext_sgn = {val[32-1], val[32-1:0]};
endfunction

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

// TCL system bus
logic                   bus_trn;  // transfer

// FSM: finite state machine
fsm_et                  ctl_fsm;  // FSM state register
fsm_et                  ctl_nxt;  // FSM state next

// TODO:
// flush: in case of branch misprediction
// skip: in case of instructions requiering only a single pipeline stage (JAL, JALR) ???

// IFU: instruction fetch unit
logic          [32-1:0] ifu_pcr;  // ifu_pcr register
logic          [32-1:0] ifu_pcn;  // ifu_pcr next
logic          [32-1:0] ifu_mux;  // instruction buffer
logic          [32-1:0] ifu_buf;  // instruction buffer

// IDU: instruction decode unit
ctl_t                   idu_rdt;
ctl_t                   idu_mux;
ctl_t                   idu_buf;
logic                   idu_vld;  // instruction valid

// GPR: general purpose registers
logic                   gpr_wen;  // write enable
logic                   gpr_ren;  // read  enable
logic           [5-1:0] gpr_wad;  // write address
logic           [5-1:0] gpr_rad;  // read  address
logic          [32-1:0] gpr_wdt;  // write data
logic          [32-1:0] gpr_rdt;  // read  data
logic          [32-1:0] gpr_rbf;  // read  buffer



// decoder
logic           [5-1:0] bus_opc;  // OP code (from bus read data)
logic           [5-1:0] dec_opc;  // OP code (from buffer)
logic           [5-1:0] bus_rd ;  // GPR `rd`  address (from bus read data)
logic           [5-1:0] dec_rd ;  // GPR `rd`  address (from buffer)
logic           [5-1:0] bus_rs1;  // GPR `rs1` address (from bus read data)
logic           [5-1:0] dec_rs1;  // GPR `rs1` address (from buffer)
logic           [5-1:0] dec_rs2;  // GPR `rs2` address
logic           [3-1:0] dec_fn3;  // funct3
logic           [7-1:0] dec_fn7;  // funct7

// immediates
logic   signed [32-1:0] dec_imi;  // decoder immediate I (integer, load, jump)
logic   signed [32-1:0] dec_imb;  // decoder immediate B (branch)
logic   signed [32-1:0] dec_ims;  // decoder immediate S (store)
logic   signed [32-1:0] bus_imu;  // decoder immediate U (upper)
logic   signed [32-1:0] dec_imu;  // decoder immediate U (upper)
logic   signed [32-1:0] dec_imj;  // decoder immediate J (jump)

// ALU adder (used for aritmetic and address calculations)
logic                   add_inc;  // ALU adder increment (input carry)
logic   signed [33-1:0] add_op1;  // ALU adder operand 1
logic   signed [33-1:0] add_op2;  // ALU adder operand 2
logic   signed [33-1:0] add_sum;  // ALU adder output
logic                   add_sgn;  // ALU adder output sign (MSB bit of sum)
logic                   add_zro;  // ALU adder output zero

// ALU logical
logic          [32-1:0] log_op1;  // ALU logical operand 1
logic          [32-1:0] log_op2;  // ALU logical operand 2
logic          [32-1:0] log_val;  // ALU logical output

// ALU barrel shifter
logic          [32-1:0] shf_op1;  // shift operand 1
logic           [5-1:0] shf_op2;  // shift operand 2 (shift ammount)
logic          [32-1:0] shf_tmp;  // bit reversed operand/result
logic signed   [32-0:0] shf_ext;
logic          [32-1:0] shf_val /* synthesis keep */;  // result

// register read buffer
logic          [32-1:0] buf_dat;

// load address buffer
logic           [2-1:0] buf_adr;
// read data multiplexer
logic          [32-1:0] rdm_dtw;  // word
logic          [16-1:0] rdm_dth;  // half
logic          [ 8-1:0] rdm_dtb;  // byte
logic          [32-1:0] rdm_dat;  // data

// branch taken
logic                   bru_tkn;
logic                   buf_tkn;

// store unit GPR write (the last stage)
logic                   stu_wen;
logic          [ 5-1:0] stu_wad;




// ALU
logic [XLEN-1:0] alu_dat;  // register destination
logic [XLEN-0:0] alu_sum;  // summation result including overflow bit



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
// TCL system bus
///////////////////////////////////////////////////////////////////////////////

assign bus_trn = bus_vld & bus_rdy;

///////////////////////////////////////////////////////////////////////////////
// instruction decode
///////////////////////////////////////////////////////////////////////////////

generate
`ifndef ALTERA_RESERVED_QIS
if (ISA.spec.ext.C) begin: gen_d16
`else
if (1'b1) begin: gen_d16
`endif

  // 16/32-bit instruction decoder
  always_comb
  unique case (opsiz(bus_rdt[16-1:0]))
    2      : idu_rdt = dec16(ISA, bus_rdt[16-1:0]);  // 16-bit C standard extension
    4      : idu_rdt = dec32(ISA, bus_rdt[32-1:0]);  // 32-bit
    default: idu_rdt = 'x;                           // OP sizes above 4 bytes are not supported
  endcase

  // next stage instruction is reencoded from muxed 32/16 decoders
  assign ifu_mux = enc32(ISA, idu_rdt);

end: gen_d16
else begin: gen_d32

  // 32-bit instruction decoder
  assign idu_buf = dec32(ISA, bus_rdt[32-1:0]);

  // next stage instruction is same as fetched
  assign ifu_mux = bus_rdt;

end: gen_d32
endgenerate

// 32-bit instruction decoder
assign idu_buf = dec32(ISA, ifu_buf[32-1:0]);

///////////////////////////////////////////////////////////////////////////////
// GPR
///////////////////////////////////////////////////////////////////////////////

// TODO: check if access should be blocked during reset
// general purpose registers
r5p_gpr_1r1w #(
//  .AW      (ISA.spec.base.E ? 4 : 5),
  .XLEN    (XLEN),
  .WBYP    (1'b1),
  .CHIP    (CHIP)
) gpr (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // configuration/control
  .en0     (1'b0),
  // read/write enable
  .e_rs    (gpr_ren),
  .e_rd    (gpr_wen),
  // read/write address
  .a_rs    (gpr_wad),
  .a_rd    (gpr_rad),
  // read/write data
  .d_rs    (gpr_wdt),
  .d_rd    (gpr_rdt)
);

///////////////////////////////////////////////////////////////////////////////
// ALU adder
///////////////////////////////////////////////////////////////////////////////

// adder (summation, subtraction)
assign add_sum = add_op1 + add_op2 + $signed({31'd0, add_inc});
// ALU adder output sign (MSB bit of sum)
assign add_sgn = add_sum[32];
// ALU adder output zero
assign add_zro = add_sum[32-1:0] == 32'd0;

///////////////////////////////////////////////////////////////////////////////
// ALU logical
///////////////////////////////////////////////////////////////////////////////

always_comb
unique case (dec_fn3)
  // bitwise logical operations
  AND    : log_val = log_op1 & log_op2;
  OR     : log_val = log_op1 | log_op2;
  XOR    : log_val = log_op1 ^ log_op2;
  default: log_val = 32'hxxxxxxxx;
endcase

///////////////////////////////////////////////////////////////////////////////
// barrel shifter
///////////////////////////////////////////////////////////////////////////////

// reverse bit order
function automatic logic [32-1:0] bitrev (logic [32-1:0] val);
  for (int unsigned i=0; i<32; i++)  bitrev[i] = val[32-1-i];
endfunction

// bit inversion
always_comb
unique case (dec_fn3)
  // barrel shifter
  SR     : shf_tmp =        shf_op1 ;
  SL     : shf_tmp = bitrev(shf_op1);
  default: shf_tmp = 'x;
endcase

// sign extension to (32+1)
always_comb
unique case (dec_fn7[5])
  1'b1   : shf_ext = {shf_tmp[32-1], shf_tmp};
  1'b0   : shf_ext = {1'b0         , shf_tmp};
endcase

// TODO: implement a layered barrel shifter to reduce logic size

// combined barrel shifter for left/right shifting
assign shf_val = 32'($signed(shf_ext) >>> shf_op2[5-1:0]);

///////////////////////////////////////////////////////////////////////////////
// FSM and pipeline
///////////////////////////////////////////////////////////////////////////////

// sequential logic
always_ff @(posedge clk, posedge rst)
if (rst) begin
  // system bus
  bus_vld <= 1'b0;
  bus_wen <= 1'b0;
  bus_ben <= '0;
  bus_wdt <= 'x;
  // control
  ctl_fsm <= SLS;
  // PC
  ifu_pcr <= '0;
  // instruction buffer
  // TODO: jump again or some kind of NOP?
  ifu_buf <= {20'd0, 5'd0, JAL, 2'b00};  // JAL x0, 0
  // data buffer
  buf_dat <= '0;
  // load address buffer
  buf_adr <= 2'd0;
  // branch taken
  buf_tkn <= 1'b0;
  // store unit GPR write (the last stage)
  stu_wen <= 1'b0;
  stu_wad <= '0;
end else begin
  // progress into the next state
  if (bus_trn | ~bus_vld) begin
    // system bus
    unique case (ctl_fsm)
      // instruction fetch state
      SIF: begin
        // FSM control (go to the next state)
        ctl_fsm <= SLS;
        // load/store
        case (idu_buf.opc)
          LOAD   : begin
            bus_vld <= 1'b1;
            bus_wen <= 1'b0;
            bus_adr <= add_sum[32-1:0];
            bus_ben <= 4'b1111;
            bus_wdt <= 32'hxxxxxxxx;
          end
          STORE  : begin
            bus_vld <= 1'b1;
            bus_wen <= 1'b1;
            bus_adr <= add_sum[32-1:0];
            bus_ben <= 4'b1111;
            bus_wdt <= 32'hxxxxxxxx;
          end
          default: begin
            bus_vld <= 1'b1;
          end
        endcase
      end
      // load/store state
      SLS: begin
        // FSM control (go to the next state)
        ctl_fsm <= SIF;
        // PC: program counter
        ifu_pcr <= ifu_pcn;
        // instruction buffer
        ifu_buf <= ifu_mux;
        // next instruction fetch
        bus_vld <= 1'b1;
        bus_wen <= 1'b0;
        bus_ben <= 4'b1111;
        bus_wdt <= 32'hxxxxxxxx;
        // GPR rs1 buffer
        gpr_rbf <= gpr_rdt;
        case (idu_buf.opc)
          STORE  : begin
            // store unit GPR write (the last stage)
            stu_wen <= 1'b1;
            stu_wad <= idu_buf.gpr.adr.rd ;
          end
          default: begin
            stu_wen <= 1'b0;
          end
        endcase
      end
    endcase
  end
end

// combinational logic
always_comb
begin
  // control
  ctl_nxt =  2'dx;
  // PC
  ifu_pcn = 32'hxxxxxxxx;
  // adder
  add_inc =  1'bx;
  add_op1 = 33'dx;
  add_op2 = 33'dx;
  // system bus
  bus_wen =  1'bx;
  bus_adr = 32'hxxxxxxxx;
  bus_ben =  4'bxxxx;
  bus_wdt = 32'hxxxxxxxx;
  // logic operations
  log_op1 = 32'hxxxxxxxx;
  log_op2 = 32'hxxxxxxxx;
  // shift operations
  shf_op1 = 32'hxxxxxxxx;
  shf_op2 =  5'dx;
  // read data multiplexer
  rdm_dtw = 32'hxxxxxxxx;
  rdm_dth = 16'hxxxx;
  rdm_dtb =  8'hxx;
  rdm_dat = 32'hxxxxxxxx;
  // branch taken
  bru_tkn =  1'bx;

  // states
  unique case (ctl_fsm)
    // instruction fetch state
    SIF: begin
    end
    // load/store state
    SLS: begin
          case (idu_rdt.opc)
            JAL    : begin
              add_inc = 1'b0;
              add_op1 = ext_sgn(ifu_pcr);
              add_op2 = ext_sgn(idu_rdt.jmp.jmp);
            end
            // TODO: JALR can be 1 or 2 stages long
            // 1 - better CPI
            // 
            JALR   : begin
              add_inc = 1'b0;
              add_op1 = ext_sgn(ifu_pcr);
              add_op2 = ext_sgn(idu_rdt.jmp.jmp);
            end
            BRANCH : begin
              // static branch prediction
              if (idu_buf.bru.imm[31]) begin
                // backward branches are predicted taken
                add_inc = 1'b0;
                add_op1 = ext_sgn(ifu_pcr);
                add_op2 = ext_sgn(idu_rdt.bru.imm);
              end else begin
                // forward branches are predicted not taken
                add_inc = 1'b0;
                add_op1 = ext_sgn(ifu_pcr);
                // TODO: support for C extension?
                add_op2 = 32'd4;
              end
            end
            default: begin
            end
          endcase
    end
  endcase
end

///////////////////////////////////////////////////////////////////////////////
// debug code
///////////////////////////////////////////////////////////////////////////////

`ifdef TRACE_DEBUG
// internal state signals
assign dbg_ifu = ctl_fsm == SIF;
assign dbg_lsu = ctl_fsm == SLS;

logic search;

assign search = (dec_opc == LOAD);

`endif

endmodule: r5p_hamster