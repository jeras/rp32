////////////////////////////////////////////////////////////////////////////////
// R5P testbench for core module
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
///////////////////////////////////////////////////////////////////////////////

module tcb_gpio_tb #(
  int unsigned AW = 22,  // address width
  int unsigned DW = 32,  // data width
  int unsigned GW = 32   // GPIO width
)(
`ifdef VERILATOR
  // system signals
  input  logic clk,  // clock
  input  logic rst   // reset
`endif
);

`ifndef VERILATOR
// system signals
logic clk = 1'b1;  // clock
logic rst = 1'b1;  // reset
`endif

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

tcb_if #(.AW (AW), .DW (DW)) bus (.clk (clk), .rst (rst));

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

`ifndef VERILATOR
// clock
always #(20ns/2) clk = ~clk;
// reset
initial
begin
  repeat (4) @(posedge clk);
  rst <= 1'b0;
  repeat (10000) @(posedge clk);
  $finish();
end
`endif

////////////////////////////////////////////////////////////////////////////////
// load/store bus decoder
////////////////////////////////////////////////////////////////////////////////

tcb_dec #(
  .AW  (DAW),
  .DW  (DDW),
  .PN  (2),                      // port number
  .AS  ({ {2'b1x, 20'hxxxxx} ,   // 0x00_0000 ~ 0x1f_ffff - data memory
          {2'b0x, 20'hxxxxx} })  // 0x20_0000 ~ 0x2f_ffff - controller
) ls_dec (
  .s  (bus_ls      ),
  .m  (bus_mem[1:0])
);

////////////////////////////////////////////////////////////////////////////////
// memory
////////////////////////////////////////////////////////////////////////////////

// bus manager
tcb_man man (
  .bus  (bus)
);

// bus monitor
tcb_mon #(
  .NAME ("GPIO"),
  .MODE ("D")
) mon (
  .bus  (bus)
);

// GPIO controller
tcb_gpio #(
  .FN   (IFN),
  .SZ   (2**IAW)
) gpio (
  .bus  (bus)
);

////////////////////////////////////////////////////////////////////////////////
// timeout
////////////////////////////////////////////////////////////////////////////////

// clock period counter
int unsigned cnt;
bit timeout = 1'b0;

// time counter
always_ff @(posedge clk, posedge rst)
if (rst) begin
  cnt <= 0;
end else begin
  cnt <= cnt+1;
end

// timeout
//always @(posedge clk)
//if (cnt > 5000)  timeout <= 1'b1;

////////////////////////////////////////////////////////////////////////////////
// waveforms
////////////////////////////////////////////////////////////////////////////////

//initial begin
//  $dumpfile("tcb_gpio_tb.vcd");
//  $dumpvars(0, tcb_gpio_tb);
//end

endmodule: tcb_gpio_tb
