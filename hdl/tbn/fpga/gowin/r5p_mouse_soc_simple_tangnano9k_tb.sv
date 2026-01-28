////////////////////////////////////////////////////////////////////////////////
// R5P mouse: testbench for SoC simple on Tang Nano 9k
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

module r5p_mouse_soc_simple_tangnano9k_tb ();

    // 27MHz clock
    logic       XTAL_IN = 1'b1;
    // buttons
    wire  [2:1] S;
    // LEDs (orange)
    wire  [6:1] LED;
    // UART
    wire        FPGA_TX;
    wire        FPGA_RX;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

    r5p_mouse_soc_simple_tangnano9k #(

    ) dut (
        // 27MHz clock
        .XTAL_IN (XTAL_IN),
        // buttons
        .S       (S),
        // LEDs (orange)
        .LED     (LED),
        // UART
        .FPGA_TX (FPGA_TX),
        .FPGA_RX (FPGA_RX)
    );

    // 27MHz clock
    always #(37.037ns/2) XTAL_IN = ~XTAL_IN;

    // buttons (reset sequence)
    bit [2:1] B = '0;
    initial begin
        repeat(8) @(posedge XTAL_IN);
        B[1] <= 1'b1;
        repeat(8) @(posedge XTAL_IN);
        B[1] <= 1'b0;
        repeat(200) @(posedge XTAL_IN);
        $finish();
    end

    // buttons pullup
    generate
    for (genvar i=1; i<=2; i++) begin: buttons
        pullup pullup_s (S[i]);
        assign S[i] = B[i] ? 1'b0 : 1'bz;
    end: buttons
    endgenerate


    // LED pullup
    pullup pullup_led [6:1] (LED);

    // UART loopback
    assign FPGA_RX = FPGA_TX;

////////////////////////////////////////////////////////////////////////////////
// GPR lookup
////////////////////////////////////////////////////////////////////////////////

    // GPR array
    logic [32-1:0] gpr [0:32-1];

    // copy GPR array from system memory
    assign gpr = dut.soc.mem[dut.soc.MEM_SIZ/4-1 -: 32];

endmodule: r5p_mouse_soc_simple_tangnano9k_tb
