///////////////////////////////////////////////////////////////////////////////
// R5P: arithmetic/logic unit (ALU)
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::*;

module r5p_alu #(
  int unsigned XLEN = 32
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // control
  input  alu_t            ctl,
  // data input/output
  input  logic [XLEN-1:0] imm,  // immediate
  input  logic [XLEN-1:0] pc ,  // PC
  input  logic [XLEN-1:0] rs1,  // source register 1
  input  logic [XLEN-1:0] rs2,  // source register 2
  output logic [XLEN-1:0] rd    // destination register
);

// multiplexed inputs
logic [XLEN-1:0] in1;  // input 1
logic [XLEN-1:0] in2;  // input 2

// operands
logic [XLEN-1:0] op1;  // operand 1
logic [XLEN-1:0] op2;  // operand 2

// invert operand 2
logic            inv;

// shift ammount
logic [$clog2(XLEN)-1:0] sa;

// summation
logic            ovf;  // overflow bit
logic [XLEN-1:0] sum;

// operation result
logic [XLEN-1:0] val;

// ALU input multiplexer
always_comb
unique casez (ctl.ai)
  AI_R1_R2: begin in1 = rs1; in2 = rs2; end
  AI_R1_IM: begin in1 = rs1; in2 = imm; end
  AI_PC_IM: begin in1 = pc ; in2 = imm; end
  default : begin in1 = 'x ; in2 = 'x ; end
endcase

// handle inputs for operations with less than XLEN width
always_comb
unique casez (ctl.rt)
  R_X    : op1 =                 in1          ;  // XLEN
  R_SW   : op1 = XLEN'(  signed'(in1[32-1:0]));  //   signed word
  R_UW   : op1 = XLEN'(unsigned'(in1[32-1:0]));  // unsigned word
  default: op1 =                 in1          ;  // XLEN
endcase

// invert operand 2 (bit 5 of f7 segment of operand)
assign inv = ctl.ao.f7_5;

// invert second operand for subtraction
always_comb
unique casez (inv)
  1'b0   : op2 =  in2;  // addition
  1'b1   : op2 = ~in2;  // subtraction
endcase

// adder (summation, subtraction)
assign {ovf, sum} = $signed(op1) + $signed(op2) + $signed(XLEN'(inv));

// TODO:
// * see if overflow can be used

// shift length
always_comb
unique casez (ctl.rt)
  R_X    : sa =                                   in2[$clog2(XLEN)-1:0] ;  // XLEN
  R_SW,
  R_UW   : sa = {{$clog2(XLEN)-$clog2(32){1'b0}}, in2[$clog2(32  )-1:0]};  // word
  default: sa =                                   in2[$clog2(XLEN)-1:0] ;  // XLEN
endcase

// operations
always_comb
unique casez (ctl.ao)
  // adder based instructions
  AO_ADD : val = sum;
  AO_SUB : val = sum;
  AO_SLT : val =   $signed(in1) <   $signed(in2) ? XLEN'(1) : XLEN'(0);
  AO_SLTU: val = $unsigned(in1) < $unsigned(in2) ? XLEN'(1) : XLEN'(0);
  // bitwise logical operations
  AO_AND : val = in1 & in2;
  AO_OR  : val = in1 | in2;
  AO_XOR : val = in1 ^ in2;
  // barrel shifter
  AO_SRA : val =   $signed(op1) >>> sa;
  AO_SRL : val = $unsigned(op1)  >> sa;
  AO_SLL : val = $unsigned(op1)  << sa;
  default: val = 'x;
endcase

// handling operations narower than XLEN
always_comb
unique casez (ctl.rt)
  R_X    : rd =                        val         ;  // XLEN
  R_SW,
  R_UW   : rd = {{XLEN-32{val[32-1]}}, val[32-1:0]};  // sign extended word
  default: rd =                        val         ;  // XLEN
endcase

endmodule: r5p_alu