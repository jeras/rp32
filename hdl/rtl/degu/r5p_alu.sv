///////////////////////////////////////////////////////////////////////////////
// R5P: arithmetic/logic unit (ALU)
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
///////////////////////////////////////////////////////////////////////////////

`ifdef ALTERA_RESERVED_QIS
`define LANGUAGE_UNSUPPORTED_STREAM_OPERATOR
`endif

module r5p_alu
  import riscv_isa_i_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  // enable opcode to be implemented withing ALU (otherwise it must be implemented elsewhere)
  parameter  bit          CFG_BRANCH = 1'b1,  // enable BRANCH
  parameter  bit          CFG_LOAD   = 1'b1,  // enable LOAD
  parameter  bit          CFG_STORE  = 1'b1,  // enable STORE
  parameter  bit          CFG_AUIPC  = 1'b1,  // enable AUIPC
  parameter  bit          CFG_JAL    = 1'b1,  // enable JAL
  // optimizations: timing versus area compromises
  parameter  bit          CFG_LOM = 1'b0,  // enable dedicated Logical Operand Multiplexer
  parameter  bit          CFG_SOM = 1'b0,  // enable dedicated Shift   Operand Multiplexer
  // FPGA specific optimizations
  parameter  int unsigned CFG_SHF = 1      // shift per stage, 1 - LUT4, 2 - LUT6, else no optimizations
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // control structure from instruction decode
  input  dec_t            dec,
  // data input/output
  input  logic [XLEN-1:0] pc ,  // PC
  input  logic [XLEN-1:0] rs1,  // source register 1
  input  logic [XLEN-1:0] rs2,  // source register 2
  output logic [XLEN-1:0] rd ,  // destination register
  // side ouputs
  output logic [XLEN-0:0] sum   // summation result including overflow bit
);

  // ALU shared operand multiplexer
  logic        [XLEN-1:0] mux_op1;  // arithmetic operand 1
  logic        [XLEN-1:0] mux_op2 /* synthesis keep */;  // arithmetic operand 2

  // arithmetic operation modes
  logic                   add_inv;  // inverted (for subtraction)
  logic                   add_uns;  // unsigned

  // arithmetic operands (extended by 1 bit)
  logic        [XLEN-0:0] add_op1;  // arithmetic operand 1
  logic        [XLEN-0:0] add_op2;  // arithmetic operand 2

  // arithmetic results
  logic        [XLEN-0:0] add_sum;  // arithmetic sum
  logic                   add_sgn;  // arithmetic sign

  // logical operations
  logic        [XLEN-1:0] log_op1;  // logical operand 1
  logic        [XLEN-1:0] log_op2;  // logical operand 2
  logic        [XLEN-1:0] log_val;  // logical result

  // barrel shifter
  logic        [XLEN-1:0] shf_op1;  // shift operand 1
  logic        [XLOG-1:0] shf_amm;  // shift amount
  logic        [XLEN-1:0] shf_tmp;  // bit reversed operand/result
  logic signed [XLEN-0:0] shf_ext;
  logic        [XLEN-1:0] shf_val /* synthesis keep */;  // result

  // ALU operation result
  logic [XLEN-1:0] val;

///////////////////////////////////////////////////////////////////////////////
// arithmetic operations
///////////////////////////////////////////////////////////////////////////////

  // ALU input multiplexer
  always_comb
  begin
    // conbinational logic
    unique case (dec.opc)
      OP     : if (1'b1      ) begin mux_op1 = rs1; mux_op2 = rs2    ; end  // R-type (arithmetic/logic)
      BRANCH : if (CFG_BRANCH) begin mux_op1 = rs1; mux_op2 = rs2    ; end  // B-type (branch)
      JALR   : if (1'b1      ) begin mux_op1 = rs1; mux_op2 = dec.i_i; end  // I-type (jump)
      OP_IMM : if (1'b1      ) begin mux_op1 = rs1; mux_op2 = dec.i_i; end  // I-type (arithmetic/logic)
      LOAD   : if (CFG_LOAD  ) begin mux_op1 = rs1; mux_op2 = dec.i_l; end  // I-type (load)
      STORE  : if (CFG_STORE ) begin mux_op1 = rs1; mux_op2 = dec.i_s; end  // S-type (store)
      AUIPC  : if (CFG_AUIPC ) begin mux_op1 = pc ; mux_op2 = dec.i_u; end  // U-type
      JAL    : if (CFG_JAL   ) begin mux_op1 = pc ; mux_op2 = dec.i_j; end  // J-type (jump)
      default:                 begin mux_op1 = 'x ; mux_op2 = 'x     ; end
    endcase
  end

  // ALU signed/unsigned extension
  always_comb
  begin
    // conbinational logic
    unique case (dec.opc)
      OP     : if (1'b1      ) begin
        unique case (fn3_alu_et'(dec.fn3))
          ADD    :             begin add_inv = dec.fn7[5]; add_uns = 1'bx; end
          SLT    :             begin add_inv = 1'b1; add_uns = 1'b0; end
          SLTU   :             begin add_inv = 1'b1; add_uns = 1'b1; end
          default:             begin add_inv = 1'bx; add_uns = 1'bx; end
        endcase
      end
      OP_IMM : if (1'b1      ) begin
        unique case (fn3_alu_et'(dec.fn3))
          ADD    :             begin add_inv = 1'b0; add_uns = 1'bx; end
          SLT    :             begin add_inv = 1'b1; add_uns = 1'b0; end
          SLTU   :             begin add_inv = 1'b1; add_uns = 1'b1; end
          default:             begin add_inv = 1'bx; add_uns = 1'bx; end
        endcase
      end
      BRANCH : if (CFG_BRANCH) begin
        unique case (fn3_bru_et'(dec.fn3))
          BEQ    ,
          BNE    :             begin add_inv = 1'b1; add_uns = 1'bx; end
          BLT    ,
          BGE    :             begin add_inv = 1'b1; add_uns = 1'b0; end
          BLTU   ,
          BGEU   :             begin add_inv = 1'b1; add_uns = 1'b1; end
          default:             begin add_inv = 1'bx; add_uns = 1'bx; end
        endcase
      end
      JALR   : if (1'b1      ) begin add_inv = 1'b0; add_uns = 1'bx; end
      LOAD   : if (CFG_LOAD  ) begin add_inv = 1'b0; add_uns = 1'bx; end
      STORE  : if (CFG_STORE ) begin add_inv = 1'b0; add_uns = 1'bx; end
      AUIPC  : if (CFG_AUIPC ) begin add_inv = 1'b0; add_uns = 1'bx; end
      JAL    : if (CFG_JAL   ) begin add_inv = 1'b0; add_uns = 1'bx; end
      default:                 begin add_inv = 1'bx; add_uns = 1'bx; end
    endcase
  end

  // adder operands
  assign add_op1 = {1'b0, mux_op1};
  assign add_op2 = {1'b0, mux_op2} ^ {XLEN+1{add_inv}};

  // adder sum
  assign add_sum = add_op1 + add_op2 + (XLEN+1)'(add_inv);

  // adder sign
  assign add_sgn = add_uns ? add_sum[XLEN]
                           : add_sum[XLEN] ^ mux_op1[XLEN-1] ^ mux_op2[XLEN-1] ^ ~add_inv;

  // output sum
  assign sum = {add_sgn, add_sum[XLEN-1:0]};

//// https://docs.xilinx.com/v/u/en-US/pg120-c-addsub
//c_addsub_0 your_instance_name (
//  .A  ( add_op1),  // input  wire [32 : 0] A
//  .B  ( add_op2),  // input  wire [32 : 0] B
//  .ADD(~add_inv),  // input  wire          ADD
//  .S  ( sum    )   // output wire [32 : 0] S
//);

///////////////////////////////////////////////////////////////////////////////
// bitwise logical operations
///////////////////////////////////////////////////////////////////////////////

  generate
  if (CFG_LOM) begin: log_mux_dedicated

    // dedicated logical operand multiplexer
    always_comb
    unique casez (dec.opc)
      OP     : begin log_op1 = rs1; log_op2 = rs2;     end  // R-type
      OP_IMM : begin log_op1 = rs1; log_op2 = dec.i_i; end  // I-type (arithmetic/logic)
      default: begin log_op1 = 'x ; log_op2 = 'x;      end
    endcase

  end: log_mux_dedicated
  else begin: log_mux_shared

    // shared multiplexer with arithmetic operations
    assign log_op1 = mux_op1;
    assign log_op2 = mux_op2;

  end: log_mux_shared
  endgenerate

  // this can be implemented with a single LUT4
  always_comb
  unique case (fn3_alu_et'(dec.fn3))
    // bitwise logical operations
    AND    : log_val = log_op1 & log_op2;
    OR     : log_val = log_op1 | log_op2;
    XOR    : log_val = log_op1 ^ log_op2;
    default: log_val = 'x;
  endcase

///////////////////////////////////////////////////////////////////////////////
// barrel shifter
///////////////////////////////////////////////////////////////////////////////

// reverse bit order
function automatic logic [XLEN-1:0] bitrev (logic [XLEN-1:0] val);
`ifdef LANGUAGE_UNSUPPORTED_STREAM_OPERATOR
  for (int unsigned i=0; i<XLEN; i++)  bitrev[i] = val[XLEN-1-i];
`else
  bitrev = {<<{val}};
`endif
endfunction: bitrev

generate
  if (CFG_SOM) begin: shf_mux_dedicated

    // dedicated shift operand multiplexer (actually shared with logical)
    assign shf_op1 = log_op1;
    assign shf_amm = log_op2[XLOG-1:0];
    // NOTE: I would expect it to give better Vivado results, but it does not

  end: shf_mux_dedicated
  else begin: shf_mux_shared

    // shared multiplexer with arithmetic operations
    assign shf_op1 = mux_op1;
    assign shf_amm = mux_op2[XLOG-1:0];

  end: shf_mux_shared
  endgenerate

  // bit inversion
  always_comb
  unique casez (fn3_alu_et'(dec.fn3))
    // barrel shifter
    SR     : shf_tmp =        shf_op1 ;
    SL     : shf_tmp = bitrev(shf_op1);
    default: shf_tmp = 'x;
  endcase

  // sign extension to (XLEN+1)
  always_comb
  unique case (dec.fn7[5])
    1'b1   : shf_ext = (XLEN+1)'(  $signed(shf_tmp));
    1'b0   : shf_ext = (XLEN+1)'($unsigned(shf_tmp));
    default: shf_ext = 'x;
  endcase

  generate
  if (CFG_SHF == 1) begin: gen_shf_1
  
    logic signed [XLEN-0:0] shf_tm0;  // operand
    logic signed [XLEN-0:0] shf_tm1;  // operand
    logic signed [XLEN-0:0] shf_tm2;  // operand
    logic signed [XLEN-0:0] shf_tm3;  // operand
    logic signed [XLEN-0:0] shf_tm4;  // operand
  
    // 1-bit shift per stage, LUT4 optimization
    always_comb
    begin
      shf_tm0 = shf_ext >>>  shf_amm[0];
      shf_tm1 = shf_tm0 >>> {shf_amm[1], 1'b0};
      shf_tm2 = shf_tm1 >>> {shf_amm[2], 2'b00};
      shf_tm3 = shf_tm2 >>> {shf_amm[3], 3'b000};
      shf_tm4 = shf_tm3 >>> {shf_amm[4], 4'b0000};
    end
  
    // remove sign extension from result
    assign shf_val = shf_tm4[XLEN-1:0];
  
  end: gen_shf_1
  else if (CFG_SHF == 2) begin: gen_shf_2
  
    logic signed [XLEN-0:0] shf_tm1;  // operand
    logic signed [XLEN-0:0] shf_tm3;  // operand
    logic signed [XLEN-0:0] shf_tm4;  // operand
  
    // 2-bit shift per stage, LUT6 optimization
    always_comb
    begin
      shf_tm1 = shf_ext >>>  shf_amm[1:0];
      shf_tm3 = shf_tm1 >>> {shf_amm[3:2], 2'b00};
      shf_tm4 = shf_tm3 >>> {shf_amm[  4], 4'b0000};
    end
  
    // remove sign extension from result
    assign shf_val = shf_tm4[XLEN-1:0];
  
  end: gen_shf_2
  else begin: gen_shf
  
    // combined barrel shifter for left/right shifting
    assign shf_val = XLEN'($signed(shf_ext) >>> shf_amm);
  
  end: gen_shf
  endgenerate

///////////////////////////////////////////////////////////////////////////////
// output multiplexer
///////////////////////////////////////////////////////////////////////////////

  // operations
  always_comb
  unique case (dec.opc)
    OP     ,
    OP_IMM : unique case (fn3_alu_et'(dec.fn3))
        // adder based instructions
        ADD : val = XLEN'(sum);
        SLT ,
        SLTU: val = XLEN'(sum[XLEN]);
        // bitwise logical operations
        AND ,
        OR  ,
        XOR : val = log_val;
        // barrel shifter
        SR  : val =        shf_val ;
        SL  : val = bitrev(shf_val);
      endcase
    AUIPC  : val = XLEN'(sum);
    default: val = 'x;
  endcase

  assign rd = val;  // XLEN

endmodule: r5p_alu
