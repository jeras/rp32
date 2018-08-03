// PC multiplexer
enum logic [2-1:0] {
  PC_0   = 2'b00;  // current PC
  PC_NXT = 2'b01;  // next   address
  PC_ALU = 2'b10;  // branch address
  PC_EPC = 2'b10;  // EPC value from CSR
} rp_sel_pc_t;

// ALU RS1 multiplexer
enum logic {
  RS1_GPR = 1'b0;
  RS1_PC  = 1'b1;
} rp_sel_rs1_t;

// ALU RS1 multiplexer
enum logic {
  RS2_GPR = 1'b0;
  RS2_IMM = 1'b1;
} rp_sel_rs2_t;

// branch type
enum logic [3-1:0] {
  BR_EQ  = 3'b00_0;  //     equal
  BR_NE  = 3'b00_1;  // not equal
  BR_LTS = 3'b10_0;  // less    then            signed
  BR_GES = 3'b10_1;  // greater then or equal   signed
  BR_LTU = 3'b11_0;  // less    then          unsigned
  BR_GEU = 3'b11_1;  // greater then or equal unsigned
  BR_XXX = 3'bxx_x;  // idle
} rp_br_t;

// ALU operation
enum logic [4-1:0] {
  ALU_ADD = 4'b0010,  // addition
  ALU_SUB = 4'b0110,  // subtraction
  ALU_AND = 4'b0000,  // logic AND
  ALU_OR  = 4'b0001,  // logic OR
  ALU_XOR = 4'b0001,  // logic XOR
  ALU_LTS = 4'b1100,  // less then   signed (not greater then or equal)
  ALU_LTU = 4'b1100,  // less then unsigned (not greater then or equal)
  ALU_SLL,  // shift left logical
  ALU_SRL,  // shift right logical
  ALU_SRA,  // shift right arithmetic
  ALU_CP1,  // copy rs1
  ALU_CP2,  // copy rs2
  ALU_XXX,  // do nothing
} rp_alu_t;

// TODO: check AXI4 encoding for transfer size

// store type
enum logic [3-1:0] {
  ST_SB = 3'b000;
  ST_SH = 3'b001;
  ST_SW = 3'b010;
  ST_SD = 3'b011;
  ST_SQ = 3'b100;
} rp_st_t;

// load type
enum logic [3-1:0] {
  LD_LB  = 4'b0_000;
  LD_LH  = 4'b0_001;
  LD_LW  = 4'b0_010;
  LD_LD  = 4'b0_011;
  LD_LQ  = 4'b0_100;
  LD_LBU = 4'b1_000;
  LD_LHU = 4'b1_001;
  LD_LWU = 4'b1_010;
  LD_LDU = 4'b1_011;
  LD_LQU = 4'b1_100;
} rp_ld_t;

// write back multiplexer
enum logic [3-1:0] {
  WB_ALU = 2'b00;
  WB_MEM = 2'b01;
  WB_PC4 = 2'b10;
  WB_CSR = 2'b11;
} rp_wb_t;

// control structure
typedef struct packed {
  rp_sel_pc_t  pc,   // PC multiplexer
  rp_br_t,     br,   // branch type
  rp_sel_rs1_t rs1,  // ALU RS1 multiplexer
  rp_sel_rs2_t rs2,  // ALU RS1 multiplexer
  rp_imm_t     imm,  // immediate select
  rp_alu_t     alu,  // ALU operation
  rp_st_t      st,   // store type
  rp_ld_t      ld,   // load type
  rp_wb_t      wb,   // write back multiplexer
  logic        wbe,  // write back enable
  logic        csr,  // CSR operation
  logic        ill   // illegal
} rp_ctl_t;

endpackage: rp_pkg
