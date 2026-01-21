////////////////////////////////////////////////////////////////////////////////
// R5P: single RW port tightly coupled memory (Xilinx XPM instance)
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

module r5p_soc_memory
    import tcb_lite_pkg::*;
#(
    string       FNM = "",    // binary initialization file name
    int unsigned SIZ = 4096   // memory size in bytes (4kB by default)
)(
    // TCB interface
    tcb_lite_if.sub sub
);

////////////////////////////////////////////////////////////////////////////////
// TCB interface parameter validation
////////////////////////////////////////////////////////////////////////////////

  initial
  begin
    // TCB mode must be memory (RISC-V mode is not supported)
    assert (sub.MOD == 1'b1) else $fatal("Unsupported TCB-Lite mode.");
  end

////////////////////////////////////////////////////////////////////////////////
// array definition
////////////////////////////////////////////////////////////////////////////////

    // xpm_memory_spram: Single Port RAM
    // Xilinx Parameterized Macro, version 2021.2
    xpm_memory_spram #(
        .ADDR_WIDTH_A        ($clog2(SIZ/sub.BYT)),   // DECIMAL
        .AUTO_SLEEP_TIME     (0),                     // DECIMAL
        .BYTE_WRITE_WIDTH_A  (8),                     // DECIMAL
        .CASCADE_HEIGHT      (0),                     // DECIMAL
        .ECC_MODE            ("no_ecc"),              // String
        .MEMORY_INIT_FILE    (FNM),                   // String
        .MEMORY_INIT_PARAM   (""),                    // String
        .MEMORY_OPTIMIZATION ("true"),                // String
        .MEMORY_PRIMITIVE    ("auto"),                // String
        .MEMORY_SIZE         (8 * SIZ),               // DECIMAL
        .MESSAGE_CONTROL     (0),                     // DECIMAL
        .READ_DATA_WIDTH_A   (sub.DAT),               // DECIMAL
        .READ_LATENCY_A      (1),                     // DECIMAL
        .READ_RESET_VALUE_A  ("0"),                   // String
        .RST_MODE_A          ("SYNC"),                // String
        .SIM_ASSERT_CHK      (0),                     // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        .USE_MEM_INIT        (1),                     // DECIMAL
        .USE_MEM_INIT_MMI    (0),                     // DECIMAL
        .WAKEUP_TIME         ("disable_sleep"),       // String
        .WRITE_DATA_WIDTH_A  (sub.DAT),               // DECIMAL
        .WRITE_MODE_A        ("read_first"),          // String
        .WRITE_PROTECT       (1)                      // DECIMAL
    ) mem (
        // unused control/status signals
        .injectdbiterra (1'b0),
        .injectsbiterra (1'b0),
        .dbiterra       (),
        .sbiterra       (),
        .sleep          (1'b0),
        .regcea         (1'b1),
        // system bus
        .clka   (sub.clk),
        .rsta   (sub.rst),
        .ena    (sub.vld),
        .wea    (sub.req.byt & {sub.BYT{sub.req.wen}}),
        .addra  (sub.req.adr[$clog2(SIZ)-1:sub.MAX]),
        .dina   (sub.req.wdt),
        .douta  (sub.rsp.rdt)
    );

    // respond with no error
    assign sub.rsp.sts = '0;
    assign sub.rsp.err = 1'b0;
    // always ready
    assign sub.rdy = 1'b1;

endmodule: r5p_soc_memory
