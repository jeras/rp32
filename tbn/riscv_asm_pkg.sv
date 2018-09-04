package riscv_asm_pkg;

localparam string REG_X [0:31] = '{"zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0/fp", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
                                   "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

function string reg_x (logic [5-1:0] r, bit abi=1'b0);
  reg_x = abi ? REG_X[r] : $sformatf("x%0d", r);
endfunction: reg_x

endpackage: riscv_asm_pkg
