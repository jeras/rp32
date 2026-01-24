////////////////////////////////////////////////////////////////////////////////
// TCB interface UART controller, stream FIFO
////////////////////////////////////////////////////////////////////////////////
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

module tcb_peri_uart_fifo #(
    parameter  int unsigned SIZ = 32,            // size
    localparam int unsigned ADR = $clog2(SIZ),    // address width (clog2)
    localparam int unsigned CNT = $clog2(SIZ+1),  // counter width
    parameter  int unsigned DAT = 8              // data width
)(
    // system signals
    input  logic           clk,
    input  logic           rst,
    // parallel stream input
    input  logic           sti_vld,  // valid
    input  logic [DAT-1:0] sti_dat,  // data
    output logic           sti_rdy,  // ready
    // parallel stream output
    output logic           sto_vld,  // valid
    output logic [DAT-1:0] sto_dat,  // data
    input  logic           sto_rdy,  // ready
    // status
    output logic [CNT-1:0] cnt       // load counter
);

////////////////////////////////////////////////////////////////////////////////
// parameter validation
////////////////////////////////////////////////////////////////////////////////

initial begin
    // at least for now only FIFO depth of 16 is supported
    assert (SIZ == 16) else $error("FIFO depth of SIZ=%0d is not supported, for Gowin devices only depth of 16 is allowed.", SIZ);
end

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

    // input interface
    logic           sti_trn;  // transfer
    logic [ADR-1:0] sti_adr;  // address counter

    // output interface
    logic           sto_trn;  // transfer
    logic [ADR-1:0] sto_adr;  // counter

////////////////////////////////////////////////////////////////////////////////
// input interface
////////////////////////////////////////////////////////////////////////////////

    // transfer
    assign sti_trn = sti_vld & sti_rdy;

    // address
    always_ff @(posedge clk, posedge rst)
    if (rst)           sti_adr <= 'd0;
    else if (sti_trn)  sti_adr <= (sti_adr == ADR'(SIZ-1)) ? 'd0 : sti_adr + 'd1;

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

    RAM16SDP4 #(
        .INIT_0 (16'h0000),
        .INIT_1 (16'h0000),
        .INIT_2 (16'h0000),
        .INIT_3 (16'h0000)
    ) gpr_1_lo [DAT/4-1:0] (
        .CLK (clk    ),
        .WRE (sti_trn),
        .DI  (sti_dat),
        .WAD (sti_adr[ADR-1:0]),
        .RAD (sto_adr[ADR-1:0]),
        .DO  (sto_dat)
    );

////////////////////////////////////////////////////////////////////////////////
// output interface
////////////////////////////////////////////////////////////////////////////////

    // transfer
    assign sto_trn = sto_vld & sto_rdy;

    // address
    always_ff @(posedge clk, posedge rst)
    if (rst)           sto_adr <= 'd0;
    else if (sto_trn)  sto_adr <= (sto_adr == ADR'(SIZ-1)) ? 'd0 : sto_adr + 'd1;

////////////////////////////////////////////////////////////////////////////////
// load counter
////////////////////////////////////////////////////////////////////////////////

    // counter binary
    always_ff @(posedge clk, posedge rst)
    if (rst)  cnt <= 'd0;
    else      cnt <= cnt + CNT'(sti_trn) - CNT'(sto_trn);

    // input ready (not full)
    assign sti_rdy = (cnt != CNT'(SIZ));

    // output valid (not empty)
    assign sto_vld = (cnt != 'd0);

endmodule: tcb_peri_uart_fifo
