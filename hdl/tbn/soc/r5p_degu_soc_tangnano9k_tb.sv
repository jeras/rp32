////////////////////////////////////////////////////////////////////////////////
// Tang Nano 9k SoC testbench
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

`timescale 1ns/1ps

module r5p_degu_soc_tangnano9k_tb;

    logic       XTAL_IN = 1'b1;
    logic [2:1] S;
    wire  [6:1] LED;
    wire        FPGA_TX;
    wire        FPGA_RX;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

    r5p_degu_soc_tangnano9k dut (
        .XTAL_IN (XTAL_IN),
        .S       (S),
        .LED     (LED),
        .FPGA_TX (FPGA_TX),
        .FPGA_RX (FPGA_RX)
    );

    // UART loopback
    assign FPGA_RX = FPGA_TX;

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

    // 50ns period is 20MHz frequency
    // 37.037ns period is 27MHz (Tang Nano 9k)
//    always #((37.037 ns)/2) XTAL_IN = ~XTAL_IN;
    always #(37.037/2) XTAL_IN = ~XTAL_IN;

    // reset sequence
    initial begin
        S[2] <= 1'b1;
        S[1] <= 1'b1;
        repeat(4) @(posedge XTAL_IN);
        S[1] <= 1'b0;
        repeat(4) @(posedge XTAL_IN);
        S[1] <= 1'b1;
        repeat(200) @(posedge XTAL_IN);
        $finish();
    end

////////////////////////////////////////////////////////////////////////////////
// netlist timing
////////////////////////////////////////////////////////////////////////////////

//    initial begin
//        $sdf_annotate("r5p_degu_soc_tangnano9k.sdf", dut);
//    end

endmodule
