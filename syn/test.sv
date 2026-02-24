module test
  import riscv_isa_pkg::*;
  import riscv_isa_i_pkg::*;
  import riscv_isa_c_pkg::*;
  //import riscv_csr_pkg::*;
  //import r5p_pkg::*;
  //import r5p_degu_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  localparam int unsigned ILEN = 32,
  // RISC-V ISA
  parameter  isa_ext_t    XTEN = RV_C,
  // privilege modes
  parameter  isa_priv_t   MODES = MODES_M,
  // ISA
  parameter  isa_t        ISA = '{spec: RV32I, priv: MODES_NONE}
)(
  // system signals
  input  logic clk,
  input  logic rst,
  // instruction
  input  logic [32-1:0] ifu_rdt,
  // decoder
  output dec_t          idu_dec
);

`ifdef SYNOPSYS_VERILOG_COMPILER
parameter isa_t ISA = '{spec: RV32I, priv: MODES_NONE};
`endif

///////////////////////////////////////////////////////////////////////////////
// instruction decode
///////////////////////////////////////////////////////////////////////////////

// TODO: uncomment this code
  generate
  if (ISA.spec.ext.C) begin: gen_d16
    dec_t          idu_tmp;

    // 16/32-bit instruction decoder
    always_comb
    unique case (opsiz(ifu_rdt[16-1:0]))
      2      : idu_tmp = dec16(ISA, ifu_rdt[16-1:0]);  // 16-bit C standard extension
      4      : idu_tmp = dec32(ISA, ifu_rdt[32-1:0]);  // 32-bit
      default: idu_tmp = 'x;                           // OP sizes above 4 bytes are not supported
    endcase

    // distributed I/C decoder mux
  //if (CFG.DEC_DIS) begin: gen_dec_dis
    if (1'b1) begin: gen_dec_dis
      assign idu_dec = idu_tmp;
    end: gen_dec_dis
    // 32-bit I/C decoder mux
    else begin
      (* keep = "true" *)
      logic [32-1:0] idu_enc;

      assign idu_enc = enc32(ISA, idu_tmp);
      always_comb
      begin
        idu_dec     = 'x;
        idu_dec     = dec32(ISA, idu_enc);
        idu_dec.siz = idu_tmp.siz;
      end
    end

  end: gen_d16
  else begin: gen_d32

    // 32-bit instruction decoder
    assign idu_dec = dec32(ISA, ifu_rdt[32-1:0]);

  end: gen_d32
  endgenerate

endmodule: test
