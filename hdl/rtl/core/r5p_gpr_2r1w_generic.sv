///////////////////////////////////////////////////////////////////////////////
// R5P: general purpose registers
// register file with 2 read ports (asynchronous) and 1 write port
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

module r5p_gpr_2r1w #(
    int unsigned AW   = 5,     // can be 4 for RV32E base ISA
    int unsigned XLEN = 32,    // XLEN width
    bit          WBYP = 1'b0   // write bypass
    // TODO: impelemt register read enable for power reduction
)(
    // system signals
    input  logic            clk,  // clock
    input  logic            rst,  // reset
    // configuration/control
    input  logic            en0,  // enable X0 read/write access
    // read/write enable
    input  logic            e_rs1,
    input  logic            e_rs2,
    input  logic            e_rd,
    // read/write address
    input  logic   [AW-1:0] a_rs1,
    input  logic   [AW-1:0] a_rs2,
    input  logic   [AW-1:0] a_rd,
    // read/write data
    output logic [XLEN-1:0] d_rs1,
    output logic [XLEN-1:0] d_rs2,
    input  logic [XLEN-1:0] d_rd
);

    // local signals
    logic            wen;
    logic [XLEN-1:0] t_rs1;
    logic [XLEN-1:0] t_rs2;
    
    // special handling of x0
    assign wen = e_rd & (|a_rd | en0);

///////////////////////////////////////////////////////////////////////////////
// register array instantiation
///////////////////////////////////////////////////////////////////////////////

    // register file (FPGA would initialize it to all zeros)
`ifdef LANGUAGE_UNSUPPORTED_ARRAY_ASSIGNMENT_PATTERN
    logic [XLEN-1:0] gpr [0:2**AW-1];
`else
    logic [XLEN-1:0] gpr [0:2**AW-1] = '{default: '0};
`endif

    // write access
    always_ff @(posedge clk)
    if (wen)  gpr[a_rd] <= d_rd;

    // read access
    assign t_rs1 = gpr[a_rs1];
    assign t_rs2 = gpr[a_rs2];

///////////////////////////////////////////////////////////////////////////////
// write back bypass
///////////////////////////////////////////////////////////////////////////////

    // TODO: write a debug version, where ==? operator is used on read enable to catch more issues

    generate
    if (WBYP) begin: gen_wb_bypass

        assign d_rs1 = (wen & (a_rd == a_rs1)) ? d_rd : t_rs1;
        assign d_rs2 = (wen & (a_rd == a_rs2)) ? d_rd : t_rs2;

    end: gen_wb_bypass
    else begin: gen_wb_default

        assign d_rs1 = t_rs1;
        assign d_rs2 = t_rs2;

    end: gen_wb_default
    endgenerate

endmodule: r5p_gpr_2r1w
