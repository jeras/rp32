///////////////////////////////////////////////////////////////////////////////
// arithmetic/logic unit (ALU)
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::alu_t;

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

// shift ammount
logic [$clog2(XLEN)-1:0] sa;

// summation
logic ovf;  // overflow bit
logic [XLEN-1:0] sum;

// operation result
logic [XLEN-1:0] val;

// ALU inputs
always_comb begin
  // ALU input multiplexer
  unique casez (ctl.ai)
    AI_R1_R2: begin in1 = rs1; in2 = rs2; end
    AI_R1_IM: begin in1 = rs1; in2 = imm; end
    AI_PC_IM: begin in1 = pc ; in2 = imm; end
    default : begin in1 = 'x ; in2 = 'x ; end
  endcase
  // handle inputs for operations with less than XLEN width
  unique casez (ctl.rt)
    R_X    : in1 =                        in1         ;  // XLEN
    R_SW   : in1 = {{XLEN-32{in1[32-1]}}, in1[32-1:0]};  //   signed word
    R_UW   : in1 = {{XLEN-32{1'b0     }}, in1[32-1:0]};  // unsigned word
    default: in1 =                        in1         ;  // XLEN
  endcase
end

// TODO: sum is not primarily for output, use it for adder based instructions
// TODO: construct proper subtraction condition
// adder (summation, subtraction)
//assign {ovf, sum} = $signed(rs1) + (ctl.alu.sig ? -$signed(rs2) : +$signed(rs2));
assign {ovf, sum} = $signed(in1) + $signed(in2);

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
  AO_ADD : val =   $signed(in1) +   $signed(in2);
  AO_SUB : val =   $signed(in1) -   $signed(in2);
  AO_SLT : val =   $signed(in1) <   $signed(in2) ? XLEN'(1) : XLEN'(0);
  AO_SLTU: val = $unsigned(in1) < $unsigned(in2) ? XLEN'(1) : XLEN'(0);
  // bitwise logical operations
  AO_AND : val = in1 & in2;
  AO_OR  : val = in1 | in2;
  AO_XOR : val = in1 ^ in2;
  // barrel shifter
  AO_SRA : val =   $signed(in1) >>> sa;
  AO_SRL : val = $unsigned(in1)  >> sa;
  AO_SLL : val = $unsigned(in1)  << sa;
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

//assign rd = val;

endmodule: r5p_alu