///////////////////////////////////////////////////////////////////////////////
// R5P Mouse processor
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

module r5p_mouse #(
  // configuration options
  bit            ENA_NOP = 1'b0,  // enable single clock cycle NOP
  // address space
  logic [32-1:0] RST_ADR = 'h0000_0000,  // reset address
  logic [32-1:0] GPR_ADR = 'h0000_0000   // GPR address
)(
  // system signals
  input  logic          clk,
  input  logic          rst,
`ifdef TRACE_DEBUG
  // internal state signals
  output logic          dbg_ifu,  // indicator of instruction fetch
  output logic          dbg_lsu,  // indicator of load/store
  output logic          dbg_gpr,  // indicator of GPR access
`endif
  // TCL system bus (shared by instruction/load/store)
  output logic          bus_vld,  // valid
  output logic          bus_wen,  // write enable
  output logic [32-1:0] bus_adr,  // address
  output logic [ 4-1:0] bus_ben,  // byte enable
  output logic [32-1:0] bus_wdt,  // write data
  input  logic [32-1:0] bus_rdt,  // read data
  input  logic          bus_err,  // error
  input  logic          bus_rdy   // ready
);

///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA definitions
///////////////////////////////////////////////////////////////////////////////

// base opcode map
localparam logic [6:2] LOAD   = 5'b00_000;
localparam logic [6:2] OP_IMM = 5'b00_100;
localparam logic [6:2] AUIPC  = 5'b00_101;
localparam logic [6:2] STORE  = 5'b01_000;
localparam logic [6:2] OP     = 5'b01_100;
localparam logic [6:2] LUI    = 5'b01_101;
localparam logic [6:2] BRANCH = 5'b11_000;
localparam logic [6:2] JALR   = 5'b11_001;
localparam logic [6:2] JAL    = 5'b11_011;
localparam logic [6:2] SYSTEM = 5'b11_100;

// funct3 arithmetic/logic unit (R/I-type)
localparam logic [3-1:0] ADD  = 3'b000;  // funct7[5] ? SUB : ADD
localparam logic [3-1:0] SL   = 3'b001;  //
localparam logic [3-1:0] SLT  = 3'b010;  //
localparam logic [3-1:0] SLTU = 3'b011;  //
localparam logic [3-1:0] XOR  = 3'b100;  //
localparam logic [3-1:0] SR   = 3'b101;  // funct7[5] ? SRA : SRL
localparam logic [3-1:0] OR   = 3'b110;  //
localparam logic [3-1:0] AND  = 3'b111;  //

// funct3 load unit (I-type)
localparam logic [3-1:0] LB   = 3'b000;  // RV32I RV64I RV128I
localparam logic [3-1:0] LH   = 3'b001;  // RV32I RV64I RV128I
localparam logic [3-1:0] LW   = 3'b010;  // RV32I RV64I RV128I
localparam logic [3-1:0] LD   = 3'b011;  //       RV64I RV128I
localparam logic [3-1:0] LBU  = 3'b100;  // RV32I RV64I RV128I
localparam logic [3-1:0] LHU  = 3'b101;  // RV32I RV64I RV128I
localparam logic [3-1:0] LWU  = 3'b110;  //       RV64I RV128I
localparam logic [3-1:0] LDU  = 3'b111;  //             RV128I

// funct3 store (S-type)
localparam logic [3-1:0] SB   = 3'b000;  // RV32I RV64I RV128I
localparam logic [3-1:0] SH   = 3'b001;  // RV32I RV64I RV128I
localparam logic [3-1:0] SW   = 3'b010;  // RV32I RV64I RV128I
localparam logic [3-1:0] SD   = 3'b011;  //       RV64I RV128I
localparam logic [3-1:0] SQ   = 3'b100;  //             RV128I

// funct3 branch (B-type)
localparam logic [3-1:0] BEQ  = 3'b000;  //     equal
localparam logic [3-1:0] BNE  = 3'b001;  // not equal
localparam logic [3-1:0] BLT  = 3'b100;  // less    then            signed
localparam logic [3-1:0] BGE  = 3'b101;  // greater then or equal   signed
localparam logic [3-1:0] BLTU = 3'b110;  // less    then          unsigned
localparam logic [3-1:0] BGEU = 3'b111;  // greater then or equal unsigned

///////////////////////////////////////////////////////////////////////////////
// local definitions
///////////////////////////////////////////////////////////////////////////////

// SFM states
localparam logic [2-1:0] ST0  = 2'd0;
localparam logic [2-1:0] ST1  = 2'd1;
localparam logic [2-1:0] ST2  = 2'd2;
localparam logic [2-1:0] ST3  = 2'd3;

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
logic           [2-1:0] ctl_fsm;  // FSM state register
logic           [2-1:0] ctl_nxt;  // FSM state next

// IFU: instruction fetch unit
// TODO: rename, also in GTKWave savefile
logic          [32-1:0] ctl_pcr;  // ctl_pcr register
logic          [32-1:0] ctl_pcn;  // ctl_pcr next
// TODO: rename, also in GTKWave savefile
logic          [32-1:0] inw_buf;  // instruction word buffer

// decoder (from bus read data)
logic           [5-1:0] bus_opc;  // OP code
logic           [5-1:0] bus_rd ;  // GPR `rd`  address
logic           [5-1:0] bus_rs1;  // GPR `rs1` address
logic           [3-1:0] bus_fn3;  // funct3
// decoder (from buffer)
logic           [5-1:0] dec_opc;  // OP code
logic           [5-1:0] dec_rd ;  // GPR `rd`  address
logic           [5-1:0] dec_rs1;  // GPR `rs1` address
logic           [5-1:0] dec_rs2;  // GPR `rs2` address
logic           [3-1:0] dec_fn3;  // funct3
logic           [7-1:0] dec_fn7;  // funct7

// immediates (from bus read data)
logic   signed [32-1:0] bus_imi;  // decoder immediate I (integer, load, jump)
logic   signed [32-1:0] bus_imu;  // decoder immediate U (upper)
// immediates (from buffer)
logic   signed [32-1:0] dec_imi;  // decoder immediate I (integer, load, jump)
logic   signed [32-1:0] dec_imb;  // decoder immediate B (branch)
logic   signed [32-1:0] dec_ims;  // decoder immediate S (store)
logic   signed [32-1:0] dec_imu;  // decoder immediate U (upper)
logic   signed [32-1:0] dec_imj;  // decoder immediate J (jump)

// ALU adder (used for arithmetic and address calculations)
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
logic           [5-1:0] shf_op2;  // shift operand 2 (shift amount)
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

///////////////////////////////////////////////////////////////////////////////
// TCL system bus
///////////////////////////////////////////////////////////////////////////////

assign bus_trn = bus_vld & bus_rdy;

///////////////////////////////////////////////////////////////////////////////
// decoder
///////////////////////////////////////////////////////////////////////////////

// GPR address (from bus read data)
assign bus_rd  = bus_rdt[11: 7];  // decoder GPR `rd`  address
assign bus_rs1 = bus_rdt[19:15];  // decoder GPR `rs1` address
// GPR address (from buffer)
assign dec_rd  = inw_buf[11: 7];  // decoder GPR `rd`  address
assign dec_rs1 = inw_buf[19:15];  // decoder GPR `rs1` address
assign dec_rs2 = inw_buf[24:20];  // decoder GPR `rs2` address

// OP and functions (from bus read data)
assign bus_opc = bus_rdt[ 6: 2];  // OP code (instruction word [6:2], [1:0] are ignored)
assign bus_fn3 = bus_rdt[14:12];  // funct3
// OP and functions (from buffer)
assign dec_opc = inw_buf[ 6: 2];  // OP code (instruction word [6:2], [1:0] are ignored)
assign dec_fn3 = inw_buf[14:12];  // funct3
assign dec_fn7 = inw_buf[31:25];  // funct7

// immediates (from bus read data)
assign bus_imi = {{21{bus_rdt[31]}}, bus_rdt[30:20]};  // I (integer, load, jump)
assign bus_imu = {bus_rdt[31:12], 12'd0};  // U (upper)
// immediates (from buffer)
assign dec_imi = {{21{inw_buf[31]}}, inw_buf[30:20]};  // I (integer, load, jump)
assign dec_imb = {{20{inw_buf[31]}}, inw_buf[7], inw_buf[30:25], inw_buf[11:8], 1'b0};  // B (branch)
assign dec_ims = {{21{inw_buf[31]}}, inw_buf[30:25], inw_buf[11:7]};  // S (store)
assign dec_imu = {inw_buf[31:12], 12'd0};  // U (upper)
assign dec_imj = {{12{inw_buf[31]}}, inw_buf[19:12], inw_buf[20], inw_buf[30:21], 1'b0};  // J (jump)

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
// FSM (split into sequential and combinational blocks)
///////////////////////////////////////////////////////////////////////////////

// sequential block
always_ff @(posedge clk, posedge rst)
if (rst) begin
  // bus valid
  bus_vld <= 1'b0;
  // control
  ctl_fsm <= ST0;
  // PC
  ctl_pcr <= 32'h00000000;
  // instruction buffer
  inw_buf <= {20'd0, 5'd0, JAL, 2'b00};  // JAL x0, 0
  // data buffer
  buf_dat <= '0;
  // load address buffer
  buf_adr <= 2'd0;
  // branch taken
  buf_tkn <= 1'b0;
end else begin
  // bus valid (always valid after reset)
  bus_vld <= 1'b1;
  // internal state 
  if (bus_trn) begin
    // control (go to the next state)
    ctl_fsm <= ctl_nxt;
    // FSM dependant buffers
    if (ctl_fsm == ST0) begin
      // update program counter
      ctl_pcr <= ctl_pcn;
    end
    if (ctl_fsm == ST1) begin
      // load the buffer when the instruction is available on the bus
      inw_buf <= bus_rdt;
    end
    // load the buffer when the data is available on the bus
    if (ctl_fsm == ST2) begin
      // load the buffer when the data is available on the bus
      buf_dat <= bus_rdt;
      // load address buffer
      buf_adr <= add_sum[1:0];
    end
    if (ctl_fsm == ST3) begin
      // load the buffer when the data is available on the bus
      buf_dat <= bus_rdt;
      // branch taken bit for branch address calculation
      buf_tkn <= bru_tkn;
    end
  end
end

// combinational block
always_comb
begin
  // control
  ctl_nxt =  2'dx;
  // PC
  ctl_pcn = 32'hxxxxxxxx;
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
    ST0: begin
      // control
      ctl_nxt = ST1;
      // calculate instruction address
      case (dec_opc)
        JAL: begin
          // adder: current instruction address + J immediate
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(dec_imj);
          // system bus
          bus_adr = add_sum[32-1:0];
        end
        JALR: begin
          // adder: GPR rs1 + I immediate
          add_inc = 1'b0;
          add_op1 = ext_sgn(buf_dat);
          add_op2 = ext_sgn(dec_imi);
          // system bus
          bus_adr = {add_sum[32-1:1], 1'b0};
        end
        BRANCH: begin
          // adder: current instruction address + B immediate
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(buf_tkn ? dec_imb : 32'd4);
          // system bus
          bus_adr = add_sum[32-1:0];
        end
        default: begin
          // adder: current instruction address
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(32'd4);
          // system bus: instruction address
          bus_adr = add_sum[32-1:0];
        end
      endcase
      // system bus: instruction fetch
      bus_wen = 1'b0;
      bus_ben = 4'b1111;
      bus_wdt = 32'hxxxxxxxx;
      // PC next
      ctl_pcn = bus_adr;
    end
    ST1: begin
      // adder, system bus
      case (bus_opc)
        LUI: begin
          // control
          ctl_nxt = ST0;
          // GPR rd write
          bus_wen = (bus_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], bus_rd , 2'b00};
          bus_ben = '1;
          bus_wdt = bus_imu;
        end
        AUIPC: begin
          // control
          ctl_nxt = ST0;
          // adder
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(bus_imu);
          // GPR rd write
          bus_wen = (bus_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], bus_rd , 2'b00};
          bus_ben = '1;
          bus_wdt = add_sum[32-1:0];
        end
        JAL: begin
          // control
          ctl_nxt = ST0;
          // adder
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(32'd4);
          // GPR rd write
          bus_wen = (bus_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], bus_rd , 2'b00};
          bus_ben = '1;
          bus_wdt = add_sum[32-1:0];
        end
        JALR, BRANCH, LOAD, STORE, OP_IMM, OP: begin
          // control
          case (bus_opc)
            BRANCH ,
            LOAD   ,
            STORE  ,
            OP     : ctl_nxt = ST2;  // GPR rs2 read
            OP_IMM ,
            JALR   : ctl_nxt = ST3;  // execute
            default: ctl_nxt = 2'dx;
          endcase
          // rs1 read
          bus_wen = 1'b0;
          bus_adr = {GPR_ADR[32-1:5+2], bus_rs1, 2'b00};
          bus_ben = '1;
          bus_wdt = 32'hxxxxxxxx;
        end
        default: begin
        end
      endcase
    end
    ST2: begin
      // control
      ctl_nxt = ST3;
      // decode
      case (dec_opc)
        LOAD: begin
          // arithmetic operations
          add_inc = 1'b0;
          add_op1 = ext_sgn(bus_rdt);
          add_op2 = ext_sgn(dec_imi);
          // load
          bus_wen = 1'b0;
          bus_adr = {add_sum[32-1:2], 2'b00};
          case (dec_fn3)
            LB, LBU: case (add_sum[1:0])
              2'b00: bus_ben = 4'b0001;
              2'b01: bus_ben = 4'b0010;
              2'b10: bus_ben = 4'b0100;
              2'b11: bus_ben = 4'b1000;
            endcase
            LH, LHU: case (add_sum[1])
              1'b0 : bus_ben = 4'b0011;
              1'b1 : bus_ben = 4'b1100;
            endcase
            LW, LWU: bus_ben = 4'b1111;
            default: bus_ben = 4'bxxxx;
          endcase
        end
        BRANCH, STORE, OP: begin
          // GPR rs2 read
          bus_wen = 1'b0;
          bus_adr = {GPR_ADR[32-1:5+2], dec_rs2, 2'b00};
          bus_ben = '1;
          bus_wdt = 32'hxxxxxxxx;
        end
        default: begin
        end
      endcase
    end
    ST3: begin
      // control
      ctl_nxt = ST0;
      // decode
      case (dec_opc)
        JALR: begin
          // adder
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(32'd4);
          // GPR rd write
          bus_wen = (dec_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], dec_rd , 2'b00};
          bus_ben = 4'b1111;
          bus_wdt = add_sum[32-1:0];
        end
        OP, OP_IMM: begin
          // GPR rd write
          bus_wen = (dec_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], dec_rd , 2'b00};
          bus_ben = 4'b1111;
          case (dec_opc)
            OP: begin
              // arithmetic operations
              case (dec_fn3)
                ADD    : begin
                  add_inc = dec_fn7[5];
                  add_op1 = ext_sgn(buf_dat);
                  add_op2 = ext_sgn(bus_rdt ^ {32{dec_fn7[5]}});
                end
                SLT    : begin
                  add_inc = 1'b1;
                  add_op1 = ext_sgn( buf_dat);
                  add_op2 = ext_sgn(~bus_rdt);
                end
                SLTU   : begin
                  add_inc = 1'b1;
                  add_op1 = {1'b0,  buf_dat};
                  add_op2 = {1'b1, ~bus_rdt};
                end
                default: begin
                end
              endcase
              // logic operations
              log_op1 = buf_dat;
              log_op2 = bus_rdt;
              // shift operations
              shf_op1 = buf_dat;
              shf_op2 = bus_rdt[5-1:0];
            end
            OP_IMM: begin
              // arithmetic operations
              case (dec_fn3)
                ADD    : begin
                  add_inc = 1'b0;
                  add_op1 = ext_sgn(bus_rdt);
                  add_op2 = ext_sgn(dec_imi);
                end
                SLT    : begin
                  add_inc = 1'b1;
                  add_op1 = ext_sgn( bus_rdt);
                  add_op2 = ext_sgn(~dec_imi);
                end
                SLTU   : begin
                  add_inc = 1'b1;
                  add_op1 = {1'b0,  bus_rdt};
                  add_op2 = {1'b1, ~dec_imi};
                end
                default: begin
                end
              endcase
              // logic operations
              log_op1 = bus_rdt;
              log_op2 = dec_imi;
              // shift operations
              shf_op1 = bus_rdt;
              shf_op2 = dec_imi[5-1:0];
            end
            default: begin
            end
          endcase
          case (dec_fn3)
            // adder based inw_buf functions
            ADD : bus_wdt = add_sum[32-1:0];
            SLT ,
            SLTU: bus_wdt = {31'd0, add_sum[32]};
            // bitwise logical operations
            AND : bus_wdt = log_val;
            OR  : bus_wdt = log_val;
            XOR : bus_wdt = log_val;
            // barrel shifter
            SR  : bus_wdt =        shf_val ;
            SL  : bus_wdt = bitrev(shf_val);
            default: begin
            end
          endcase
        end
        LOAD: begin
          // GPR rd write
          bus_wen = (dec_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], dec_rd , 2'b00};
          bus_ben = 4'b1111;
          // read data multiplexer
          rdm_dtw = bus_rdt[31: 0];
          rdm_dth = buf_adr[1] ? rdm_dtw[31:16] : rdm_dtw[15: 0];
          rdm_dtb = buf_adr[0] ? rdm_dth[15: 8] : rdm_dth[ 7: 0];
          rdm_dat = {rdm_dtw[31:16], rdm_dth[15: 8], rdm_dtb[ 7: 0]};
          // sign extension, NOTE: this is a good fit for LUT4
          unique case (dec_fn3)
            LB     : bus_wdt = {{24{rdm_dat[ 8-1]}}, rdm_dat[ 8-1:0]};
            LH     : bus_wdt = {{16{rdm_dat[16-1]}}, rdm_dat[16-1:0]};
            LW     : bus_wdt = {                     rdm_dat[32-1:0]};
            LBU    : bus_wdt = { 24'd0             , rdm_dat[ 8-1:0]};
            LHU    : bus_wdt = { 16'd0             , rdm_dat[16-1:0]};
            LWU    : bus_wdt = {                     rdm_dat[32-1:0]};
            default: bus_wdt = 32'hxxxxxxxx;
          endcase
        end
        STORE: begin
          // arithmetic operations
          add_inc = 1'b0;
          add_op1 = ext_sgn(buf_dat);
          add_op2 = ext_sgn(dec_ims);
          // store
          bus_wen = 1'b1;
          bus_adr = {add_sum[32-1:2], 2'b00};
          case (dec_fn3)
            SB     : case (add_sum[1:0])
              2'b00: begin bus_wdt[ 7: 0] = bus_rdt[ 7: 0]; bus_ben = 4'b0001; end
              2'b01: begin bus_wdt[15: 8] = bus_rdt[ 7: 0]; bus_ben = 4'b0010; end
              2'b10: begin bus_wdt[23:16] = bus_rdt[ 7: 0]; bus_ben = 4'b0100; end
              2'b11: begin bus_wdt[31:24] = bus_rdt[ 7: 0]; bus_ben = 4'b1000; end
            endcase
            SH     : case (add_sum[1])
              1'b0 : begin bus_wdt[15: 0] = bus_rdt[15: 0]; bus_ben = 4'b0011; end
              1'b1 : begin bus_wdt[31:16] = bus_rdt[15: 0]; bus_ben = 4'b1100; end
            endcase
            SW     : begin bus_wdt[31: 0] = bus_rdt[31: 0]; bus_ben = 4'b1111; end
            default: begin bus_wdt[31: 0] = 32'hxxxxxxxx  ; bus_ben = 4'bxxxx; end
          endcase
        end
        BRANCH: begin
          // subtraction
          add_inc = 1'b1;
          unique case (dec_fn3)
            BEQ    ,
            BNE    ,
            BLT    ,
            BGE    : begin
              add_op1 = ext_sgn( buf_dat);
              add_op2 = ext_sgn(~bus_rdt);
            end
            BLTU   ,
            BGEU   : begin
              add_op1 = {1'b0,  buf_dat};
              add_op2 = {1'b1, ~bus_rdt};
            end
            default: begin
              add_op1 = 33'dx;
              add_op2 = 33'dx;
            end
          endcase
          unique case (dec_fn3)
            BEQ    : bru_tkn =  add_zro;
            BNE    : bru_tkn = ~add_zro;
            BLT    : bru_tkn =  add_sgn;
            BGE    : bru_tkn = ~add_sgn;
            BLTU   : bru_tkn =  add_sgn;
            BGEU   : bru_tkn = ~add_sgn;
            default: bru_tkn = 1'bx;
          endcase
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
assign dbg_ifu = ctl_fsm == ST0;
assign dbg_lsu = ~(dbg_ifu | dbg_gpr);
assign dbg_gpr = bus_adr[32-1:5+2] == GPR_ADR[32-1:5+2];

logic search;

assign search = (dec_opc == LOAD);

`endif

endmodule
