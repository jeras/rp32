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
    logic            wen  , wen_lo  , wen_hi  ;
    logic [XLEN-1:0] t_rs1, t_rs1_lo, t_rs1_hi;
    logic [XLEN-1:0] t_rs2, t_rs2_lo, t_rs2_hi;
    
    // special handling of x0
    assign wen    = e_rd & (|a_rd | en0);
    assign wen_lo = wen & (a_rd[4] == 1'b0);
    assign wen_hi = wen & (a_rd[4] == 1'b1);

///////////////////////////////////////////////////////////////////////////////
// register array instantiation
///////////////////////////////////////////////////////////////////////////////

    RAM16SDP4 #(
        .INIT_0 (16'h0000),
        .INIT_1 (16'h0000),
        .INIT_2 (16'h0000),
        .INIT_3 (16'h0000)
    ) gpr_1_lo [XLEN/4-1:0] (
        .CLK (clk       ),
        .WRE (wen_lo    ),
        .DI  (d_rd      ),
        .WAD (a_rd [3:0]),
        .RAD (a_rs1[3:0]),
        .DO  (t_rs1_lo  )
    );

    RAM16SDP4 #(
        .INIT_0 (16'h0000),
        .INIT_1 (16'h0000),
        .INIT_2 (16'h0000),
        .INIT_3 (16'h0000)
    ) gpr_2_lo [XLEN/4-1:0] (
        .CLK (clk       ),
        .WRE (wen_lo    ),
        .DI  (d_rd      ),
        .WAD (a_rd [3:0]),
        .RAD (a_rs2[3:0]),
        .DO  (t_rs2_lo  )
    );

    RAM16SDP4 #(
        .INIT_0 (16'h0000),
        .INIT_1 (16'h0000),
        .INIT_2 (16'h0000),
        .INIT_3 (16'h0000)
    ) gpr_1_hi [XLEN/4-1:0] (
        .CLK (clk       ),
        .WRE (wen_hi    ),
        .DI  (d_rd      ),
        .WAD (a_rd [3:0]),
        .RAD (a_rs1[3:0]),
        .DO  (t_rs1_hi  )
    );

    RAM16SDP4 #(
        .INIT_0 (16'h0000),
        .INIT_1 (16'h0000),
        .INIT_2 (16'h0000),
        .INIT_3 (16'h0000)
    ) gpr_2_hi [XLEN/4-1:0] (
        .CLK (clk       ),
        .WRE (wen_hi    ),
        .DI  (d_rd      ),
        .WAD (a_rd [3:0]),
        .RAD (a_rs2[3:0]),
        .DO  (t_rs2_hi  )
    );

    // read access
    assign t_rs1 = a_rs1[4] ? t_rs1_hi : t_rs1_lo;
    assign t_rs2 = a_rs2[4] ? t_rs2_hi : t_rs2_lo;

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
