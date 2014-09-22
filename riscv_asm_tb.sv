module riscv_asm_tb ();

logic [4-1:0][8-1:0] mem [0:2**16];

initial begin
  $readmemh ("code.hex", mem);
  for (int unsigned adr=0; adr<64; adr++) begin
    $system ({"echo 'DASM(", $sformatf("%08x", mem[adr]), ")' | /opt/riscv/bin/riscv-dis >> code_ref.dis"});
    $system ({"echo '", riscv_asm::dis(mem[adr]),                                     "' >> code_dut.dis"});
  end
end

endmodule: riscv_asm_tb
