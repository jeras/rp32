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
  int unsigned DW = 32,    // data    width
  int unsigned BW = DW/8,  // byte en width
  // privilege implementation details
  logic [32-1:0] PC0 = 'h0000_0000,   // reset vector
  // optimizations: timing versus area compromises
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
logic                   ctl_run;  // run status becomes active after reset
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
ctl_t                   idu_buf;
logic                   idu_vld;  // instruction valid

// GPR: general purpose registers
logic                   gpr_wen;  // write enable
logic                   gpr_ren;  // read  enable
logic           [5-1:0] gpr_wad;  // write address
logic           [5-1:0] gpr_rad;  // read  address
logic          [32-1:0] gpr_wdt;  // write data
logic          [32-1:0] gpr_rdt;  // read  data
logic          [32-1:0] gpr_rdb;  // read  data buffer

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

// ALU result output
logic          [32-1:0] alu_out;
logic          [32-1:0] alu_buf;

// register read buffer
logic          [32-1:0] buf_dat;

// read data multiplexer
logic           [2-1:0] rdm_adr;  // load address buffer
logic          [32-1:0] rdm_dtw;  // word
logic          [16-1:0] rdm_dth;  // half
logic          [ 8-1:0] rdm_dtb;  // byte
logic          [32-1:0] rdm_dat;  // data
fn3_ldu_et              rdm_fn3;  // load funct3

// branch taken
logic                   bru_tkn;
logic                   buf_tkn;

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
  assign idu_rdt = dec32(ISA, bus_rdt[32-1:0]);

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
  .XLEN    (32),
  .WBYP    (1'b1),
  .CHIP    (CHIP)
) gpr (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // configuration/control
  .en0     (1'b0),
  // read/write enable
  .e_rd    (gpr_wen),
  .e_rs    (gpr_ren),
  // read/write address
  .a_rd    (gpr_wad),
  .a_rs    (gpr_rad),
  // read/write data
  .d_rd    (gpr_wdt),
  .d_rs    (gpr_rdt)
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
unique case (idu_buf.alu.fn3)
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
unique case (idu_buf.alu.fn3)
  // barrel shifter
  SR     : shf_tmp =        shf_op1 ;
  SL     : shf_tmp = bitrev(shf_op1);
  default: shf_tmp = 'x;
endcase

// sign extension to (32+1)
always_comb
unique case (idu_buf.alu.fn7[5])
  1'b1   : shf_ext = {shf_tmp[32-1], shf_tmp};
  1'b0   : shf_ext = {1'b0         , shf_tmp};
endcase

// TODO: implement a layered barrel shifter to reduce logic size

// combined barrel shifter for left/right shifting
assign shf_val = 32'($signed(shf_ext) >>> shf_op2[5-1:0]);

///////////////////////////////////////////////////////////////////////////////
// FSM and pipeline
///////////////////////////////////////////////////////////////////////////////

localparam op32_i_t NOP = op32_i_t'{imm_11_0: 12'd0, rs1: 5'd0, funct3: ADD, rd: 5'd0, opcode: '{opc: OP_IMM, c11: 2'b11}};  // addi x0, x0, 0

// sequential logic
always_ff @(posedge clk, posedge rst)
if (rst) begin
  // control
  ctl_run <= 1'b0;
  ctl_fsm <= SIF;
  // system bus
  bus_vld <= 1'b0;
  bus_wen <= 1'b0;
  bus_ben <= '1;  // TODO: rethink reset
  bus_wdt <= 'x;
  // PC
  ifu_pcr <= '0;
  // instruction buffer
  // TODO: jump again or some kind of NOP?
  ifu_buf <= NOP;
  // data buffer
  buf_dat <= '0;
  // load address buffer
  rdm_adr <= '0;
  rdm_fn3 <= '0;
  // branch taken
  buf_tkn <= 1'b0;
end else begin
  // RESET transition
  // TODO: rethink reset
  ctl_run <= 1'b1;
  bus_vld <= 1'b1;
  // progress into the next state
  if (ctl_run & (bus_trn | ~bus_vld)) begin
    // GPR (write rd)
    gpr_wad <= idu_buf.gpr.adr.rd;
    // system bus
    unique case (ctl_fsm)
      // instruction fetch state
      SIF: begin
        // FSM control (go to the next state)
        ctl_fsm <= SLS;
        // PC: program counter
        // TODO: PC is only reloaded if the prediction is correct
        ifu_pcr <= bus_adr;
        // load/store
        case (idu_buf.opc)
          JAL    ,
          JALR   : begin
            // TCB
            bus_vld <= 1'b0;
            // GPR
            gpr_wen <= 1'b1;
            alu_buf <= add_sum[32-1:0];
          end
          LUI    : begin
            // TCB
            bus_vld <= 1'b0;
            // GPR
            gpr_wen <= 1'b1;
            alu_buf <= idu_buf.uiu;
          end
          AUIPC  : begin
            // TCB
            bus_vld <= 1'b0;
            // GPR
            gpr_wen <= 1'b1;
            alu_buf <= add_sum[32-1:0];
          end
          LOAD   : begin
            // TCB
            bus_vld <= 1'b1;
            bus_wen <= 1'b0;
            bus_adr <= {add_sum[32-1:2], 2'b00};
            case (idu_buf.ldu.fn3)
              LB, LBU: case (add_sum[1:0])
                2'b00: bus_ben <= 4'b0001;
                2'b01: bus_ben <= 4'b0010;
                2'b10: bus_ben <= 4'b0100;
                2'b11: bus_ben <= 4'b1000;
              endcase
              LH, LHU: case (add_sum[1])
                1'b0 : bus_ben <= 4'b0011;
                1'b1 : bus_ben <= 4'b1100;
              endcase
              LW, LWU: bus_ben <= 4'b1111;
              default: ;    // NOTE: avoid toggling
            endcase
          //bus_wdt <= 32'hxxxxxxxx;  // NOTE: avoid toggling
            // GPR
            gpr_wen <= 1'b0;
            // read data multiplexer
            rdm_adr <=  add_sum[ 2-1:0];
            rdm_fn3 <= idu_buf.ldu.fn3;
          end
          STORE  : begin
            // TCB
            bus_vld <= 1'b1;
            bus_wen <= 1'b1;
            bus_adr <= {add_sum[32-1:2], 2'b00};
            case (idu_buf.stu.fn3)
              SB     : case (add_sum[1:0])
                2'b00: begin bus_wdt[ 7: 0] <= gpr_rdt[ 7: 0]; bus_ben <= 4'b0001; end
                2'b01: begin bus_wdt[15: 8] <= gpr_rdt[ 7: 0]; bus_ben <= 4'b0010; end
                2'b10: begin bus_wdt[23:16] <= gpr_rdt[ 7: 0]; bus_ben <= 4'b0100; end
                2'b11: begin bus_wdt[31:24] <= gpr_rdt[ 7: 0]; bus_ben <= 4'b1000; end
              endcase
              SH     : case (add_sum[1])
                1'b0 : begin bus_wdt[15: 0] <= gpr_rdt[15: 0]; bus_ben <= 4'b0011; end
                1'b1 : begin bus_wdt[31:16] <= gpr_rdt[15: 0]; bus_ben <= 4'b1100; end
              endcase
              SW     : begin bus_wdt[31: 0] <= gpr_rdt[31: 0]; bus_ben <= 4'b1111; end
              default: begin                                                       end  // NOTE: avoid toggling
            endcase
            // GPR
            gpr_wen <= 1'b0;
          end
          OP     ,
          OP_IMM : begin
            // TCB
            bus_vld <= 1'b0;
            // GPR
            gpr_wen <= 1'b1;
            alu_buf <= alu_out;
          end
          default: begin
            // TCB
            bus_vld <= 1'b0;
            // GPR
            gpr_wen <= 1'b0;
          end
        endcase
      end
      // load/store state
      SLS: begin
        // FSM control (go to the next state)
        ctl_fsm <= SIF;
        // instruction buffer
        ifu_buf <= ifu_mux;
        // next instruction fetch
        bus_vld <= 1'b1;
        bus_wen <= 1'b0;
        bus_adr <= add_sum[32-1:0];
        bus_ben <= 4'b1111;
      //bus_wdt <= 32'hxxxxxxxx;  // NOTE: avoid toggling to reduce power
        // GPR rs1 buffer
        case (idu_rdt.opc)
          AUIPC  : begin
            gpr_rdb <= ifu_pcr;
          end
          default: begin
            gpr_rdb <= gpr_rdt;
          end
        endcase
        case (idu_buf.opc)
          LOAD   : begin
            // load unit GPR write (the last stage)
            gpr_wen <= 1'b1;
          end
          default: begin
            gpr_wen <= 1'b0;
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
  ctl_nxt =  'x;
  // PC
  ifu_pcn = 32'hxxxxxxxx;
  // adder
  add_inc =  1'bx;
  add_op1 = 33'dx;
  add_op2 = 33'dx;
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
      // GPR (read rs1)
      gpr_ren = 1'b1;
      gpr_rad = idu_buf.gpr.adr.rs2;
      // LOAD: read data multiplexer
      rdm_dtw = bus_rdt[31: 0];
      rdm_dth = rdm_adr[1] ? rdm_dtw[31:16] : rdm_dtw[15: 0];
      rdm_dtb = rdm_adr[0] ? rdm_dth[15: 8] : rdm_dth[ 7: 0];
      rdm_dat = {rdm_dtw[31:16], rdm_dth[15: 8], rdm_dtb[ 7: 0]};
      // sign extension, NOTE: this is a good fit for LUT4
      unique case (rdm_fn3)
        LB     : gpr_wdt = {{24{rdm_dat[ 8-1]}}, rdm_dat[ 8-1:0]};
        LH     : gpr_wdt = {{16{rdm_dat[16-1]}}, rdm_dat[16-1:0]};
        LW     : gpr_wdt = {                     rdm_dat[32-1:0]};
        LBU    : gpr_wdt = { 24'd0             , rdm_dat[ 8-1:0]};
        LHU    : gpr_wdt = { 16'd0             , rdm_dat[16-1:0]};
        LWU    : gpr_wdt = {                     rdm_dat[32-1:0]};
        default: gpr_wdt = 32'hxxxxxxxx;
      endcase
      // decode operation code
      case (idu_buf.opc)
        JAL    ,
        JALR   : begin
          add_inc = 1'b0;
          add_op1 = 33'(ifu_pcr);
          add_op2 = 33'(33'd4);
        end
        AUIPC  : begin
          // adder
          add_inc = 1'b0;
          add_op1 = ext_sgn(gpr_rdb);
          add_op2 = ext_sgn(idu_buf.uiu.imm);
        end
        LOAD  : begin
          // adder for load address
          add_inc = 1'b0;
          add_op1 = ext_sgn(gpr_rdb);
          add_op2 = ext_sgn(32'(idu_buf.ldu.imm));
        end
        STORE : begin
          // adder for store address
          add_inc = 1'b0;
          add_op1 = ext_sgn(gpr_rdb);
          add_op2 = ext_sgn(32'(idu_buf.stu.imm));
        end
        OP     : begin
          // arithmetic operations
          case (idu_buf.alu.fn3)
            ADD    : begin
              add_inc = idu_buf.alu.fn7[5];
              add_op1 = ext_sgn(gpr_rdb);
              add_op2 = ext_sgn(gpr_rdt ^ {32{idu_buf.alu.fn7[5]}});
            end
            SLT    : begin
              add_inc = 1'b1;
              add_op1 = ext_sgn( gpr_rdb);
              add_op2 = ext_sgn(~gpr_rdt);
            end
            SLTU   : begin
              add_inc = 1'b1;
              add_op1 = {1'b0,  gpr_rdb};
              add_op2 = {1'b1, ~gpr_rdt};
            end
            default: begin
            end
          endcase
          // logic operations
          log_op1 = gpr_rdb;
          log_op2 = gpr_rdt;
          // shift operations
          shf_op1 = gpr_rdb;
          shf_op2 = gpr_rdt[5-1:0];
        end
        OP_IMM : begin
          // arithmetic operations
          case (idu_buf.alu.fn3)
            ADD    : begin
              add_inc = 1'b0;
              add_op1 = ext_sgn(gpr_rdb);
              add_op2 = ext_sgn(32'(idu_buf.alu.imm));
            end
            SLT    : begin
              add_inc = 1'b1;
              add_op1 = ext_sgn( gpr_rdb);
              add_op2 = ext_sgn(~32'(idu_buf.alu.imm));
            end
            SLTU   : begin
              add_inc = 1'b1;
              add_op1 = {1'b0,  gpr_rdb};
              add_op2 = {1'b1, ~32'(idu_buf.alu.imm)};
            end
            default: begin
            end
          endcase
          // logic operations
          log_op1 = gpr_rdb;
          log_op2 = 32'(idu_buf.alu.imm);
          // shift operations
          shf_op1 = gpr_rdb;
          shf_op2 = idu_buf.alu.imm[5-1:0];
        end
        default: begin
        end
      endcase
      // ALU output
      case (idu_buf.alu.fn3)
        // adder based inw_bufuctions
        ADD : alu_out = add_sum[32-1:0];
        SLT ,
        SLTU: alu_out = {31'd0, add_sum[32]};
        // bitwise logical operations
        AND : alu_out = log_val;
        OR  : alu_out = log_val;
        XOR : alu_out = log_val;
        // barrel shifter
        SR  : alu_out =        shf_val ;
        SL  : alu_out = bitrev(shf_val);
        default: begin
        end
      endcase
    end
    // load/store state
    SLS: begin
      // GPR (read rs1)
      gpr_ren = 1'b1;
      gpr_rad = idu_rdt.gpr.adr.rs1;
      gpr_wdt = alu_buf;
      // decode operation code
      case (idu_rdt.opc)
        // TODO: JAL/JALR can be 1 or 2 rounds long
        // 1 - better CPI
        // 2 - easier logic
        JAL    : begin
          add_inc = 1'b0;
          add_op1 = 33'(ifu_pcr);
          add_op2 = 33'(idu_rdt.jmp.jmp);
        end
        JALR   : begin
          add_inc = 1'b0;
          add_op1 = 33'(gpr_rdt);
          add_op2 = 33'(idu_rdt.jmp.imm);
        end
        BRANCH : begin
          // static branch prediction
          if (idu_buf.bru.imm[12]) begin
            // backward branches are predicted taken
            add_inc = 1'b0;
            add_op1 = 33'(ifu_pcr);
            add_op2 = 33'(idu_rdt.bru.imm);
          end else begin
            // forward branches are predicted not taken
            add_inc = 1'b0;
            add_op1 = 33'(ifu_pcr);
            // TODO: support for C extension?
            add_op2 = 33'd4;
          end
        end
        default: begin
            // increment instruction address
            add_inc = 1'b0;
            add_op1 = 33'(ifu_pcr);
            // TODO: support for C extension?
            add_op2 = 33'd4;
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

assign search = (idu_rdt.opc == LOAD);

`endif

endmodule: r5p_hamster