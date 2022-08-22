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

// funct3 arithetic/logic unit (R/I-type)
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

// SFM states (phases)
localparam logic [2-1:0] PH0  = 2'd0;
localparam logic [2-1:0] PH1  = 2'd1;
localparam logic [2-1:0] PH2  = 2'd2;
localparam logic [2-1:0] PH3  = 2'd3;

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

// control
logic           [2-1:0] ctl_fsm;  // FSM state register
logic           [2-1:0] ctl_nxt;  // FSM state next
logic          [32-1:0] ctl_pcr;  // ctl_pcr register
logic          [32-1:0] ctl_pcn;  // ctl_pcr next

// buffers
logic          [32-1:0] inw_buf;  // instruction word buffer

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
logic          [32-1:0] log_out;  // ALU logical output

// register read buffer
logic          [32-1:0] buf_dat;  //

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

// GPR address
assign bus_rd  = bus_rdt[11: 7];  // decoder GPR `rd`  address (from bus read data)
assign dec_rd  = inw_buf[11: 7];  // decoder GPR `rd`  address (from buffer)
assign bus_rs1 = bus_rdt[19:15];  // decoder GPR `rs1` address (from bus read data)
assign dec_rs1 = inw_buf[19:15];  // decoder GPR `rs1` address (from buffer)
assign dec_rs2 = inw_buf[24:20];  // decoder GPR `rs2` address

// OP and functions
assign bus_opc = bus_rdt[ 6: 2];  // OP code (instruction word [6:2], [1:0] are ignored)
assign dec_opc = inw_buf[ 6: 2];  // OP code (instruction word [6:2], [1:0] are ignored)
assign dec_fn3 = inw_buf[14:12];  // funct3
assign dec_fn7 = inw_buf[31:25];  // funct7

// immediates
assign dec_imi = {{21{inw_buf[31]}}, inw_buf[30:20]};  // I (integer, load, jump)
assign dec_imb = {{20{inw_buf[31]}}, inw_buf[7], inw_buf[30:25], inw_buf[11:8], 1'b0};  // B (branch)
assign dec_ims = {{21{inw_buf[31]}}, inw_buf[30:25], inw_buf[11:7]};  // S (store)
assign bus_imu = {bus_rdt[31:12], 12'd0};  // U (upper)
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
  AND    : log_out = log_op1 & log_op2;
  OR     : log_out = log_op1 | log_op2;
  XOR    : log_out = log_op1 ^ log_op2;
  default: log_out = 'x;
endcase

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clk, posedge rst)
if (rst) begin
  // bus valid
  bus_vld <= 1'b0;
  // control
  ctl_fsm <= PH0;
  // PC
  ctl_pcr <= '0;
  // instruction buffer
  inw_buf <= {20'd0, 5'd0, JAL, 2'b00};  // JAL x0, 0
  // data buffer
  buf_dat <= '0;
end else begin
  // bus valid (always valid after reset)
  bus_vld <= 1'b1;
  // internal state 
  if (bus_trn) begin
    // control (go to the next state)
    ctl_fsm <= ctl_nxt;
    // update program counter
    if (ctl_fsm == PH0) begin
      ctl_pcr <= ctl_pcn;
    end
    // load the buffer when the instruction is available on the bus
    if (ctl_fsm == PH1) begin
      inw_buf <= bus_rdt;
    end
    // load the buffer when the data is available on the bus
    if ((ctl_fsm == PH2) || (ctl_fsm == PH3)) begin
      buf_dat <= bus_rdt;
    end
    // buffer taken bit for branch address calculation
    if (ctl_fsm == PH3) begin
      buf_tkn <= bru_tkn;
    end
  end
end

always_comb
begin
  // control
  ctl_nxt = 'x;
  // phases
  unique case (ctl_fsm)
    PH0: begin
      // control
      ctl_nxt = PH1;
      // calculate instruction address
      case (dec_opc)
        JAL: begin
          // adder: current instruction address
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(dec_imj);
          // system bus
          bus_adr = add_sum[32-1:0];
        end
        JALR: begin
          // adder: current instruction address
          add_inc = 1'b0;
          add_op1 = ext_sgn(buf_dat);
          add_op2 = ext_sgn(dec_imi);
          // system bus
          bus_adr = add_sum[32-1:0];
        end
        BRANCH: begin
          // adder
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
      bus_ben = '1;
      bus_wdt = 'x;
      // PC next
      ctl_pcn = bus_adr;
    end
    PH1: begin
      // adder, system bus
      case (bus_opc)
        LUI: begin
          // control
          ctl_nxt = PH0;
          // GPR rd write
          bus_wen = (bus_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], bus_rd , 2'b00};
          bus_ben = '1;
          bus_wdt = bus_imu;
        end
        AUIPC: begin
          // control
          ctl_nxt = PH0;
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
          ctl_nxt = PH0;
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
            OP     : ctl_nxt = PH2;  // GPR rs2 read
            OP_IMM ,
            JALR   : ctl_nxt = PH3;  // execute
            default: ctl_nxt = 'x;
          endcase
          // rs1 read
          bus_wen = 1'b0;
          bus_adr = {GPR_ADR[32-1:5+2], bus_rs1, 2'b00};
          bus_ben = '1;
          bus_wdt = 'x;
        end
        default: begin
        end
      endcase
    end
    PH2: begin
      case (dec_opc)
        BRANCH, STORE, OP: begin
          // control
          ctl_nxt = PH3;
          // GPR rs2 read
          bus_wen = 1'b0;
          bus_adr = {GPR_ADR[32-1:5+2], dec_rs2, 2'b00};
          bus_ben = '1;
          bus_wdt = 'x;
        end
        default: begin
        end
      endcase
    end
    PH3: begin
      // control
      ctl_nxt = PH0;
      case (dec_opc)
        JALR: begin
          // control
          ctl_nxt = PH0;
          // adder
          add_inc = 1'b0;
          add_op1 = ext_sgn(ctl_pcr);
          add_op2 = ext_sgn(32'd4);
          // GPR rd write
          bus_wen = (dec_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], dec_rd , 2'b00};
          bus_ben = '1;
          bus_wdt = add_sum[32-1:0];
        end
        OP, OP_IMM: begin
          // GPR rd write
          bus_wen = (dec_rd != 5'd0);
          bus_adr = {GPR_ADR[32-1:5+2], dec_rd , 2'b00};
          bus_ben = '1;
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
            end
            default: begin
            end
          endcase
          case (dec_fn3)
            // adder based inw_bufuctions
            ADD : bus_wdt = add_sum[32-1:0];
            SLT ,
            SLTU: bus_wdt = {31'd0, add_sum[32]};
            // bitwise logical operations
            AND : bus_wdt = log_out;
            OR  : bus_wdt = log_out;
            XOR : bus_wdt = log_out;
            // barrel shifter
            // TODO
//            SR  : bus_wdt =        shf_val ;
//            SL  : bus_wdt = bitrev(shf_val);
            default: begin
            end
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
            SB : case (add_sum[1:0])
              2'b00: begin bus_wdt = {8'hxx         , 8'hxx         , 8'hxx         , bus_rdt[ 7: 0]}; bus_ben = 4'b0001; end
              2'b01: begin bus_wdt = {8'hxx         , 8'hxx         , bus_rdt[ 7: 0], 8'hxx         }; bus_ben = 4'b0010; end
              2'b10: begin bus_wdt = {8'hxx         , bus_rdt[ 7: 0], 8'hxx         , 8'hxx         }; bus_ben = 4'b0100; end
              2'b11: begin bus_wdt = {bus_rdt[ 7: 0], 8'hxx         , 8'hxx         , 8'hxx         }; bus_ben = 4'b1000; end
            endcase
            SH : case (add_sum[1])
              1'b0 : begin bus_wdt = {8'hxx         , 8'hxx         , bus_rdt[15: 8], bus_rdt[ 7: 0]}; bus_ben = 4'b0011; end
              1'b1 : begin bus_wdt = {bus_rdt[15: 8], bus_rdt[ 7: 0], 8'hxx         , 8'hxx         }; bus_ben = 4'b1100; end
            endcase
            SW :     begin bus_wdt = {bus_rdt[31:24], bus_rdt[23:16], bus_rdt[15: 8], bus_rdt[ 7: 0]}; bus_ben = 4'b1111; end
            default: begin bus_wdt = {8'hxx         , 8'hxx         , 8'hxx         , 8'hxx         }; bus_ben = 4'bxxxx; end
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
assign dbg_ifu = ctl_fsm == PH0;
assign dbg_lsu = ~(dbg_ifu | dbg_gpr);
assign dbg_gpr = bus_adr[32-1:5+2] == GPR_ADR[32-1:5+2];

logic search;

assign search = (dec_opc == STORE) && (dec_fn3 == SH);

`endif

endmodule: r5p_mouse
