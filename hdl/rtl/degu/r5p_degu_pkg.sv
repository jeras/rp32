///////////////////////////////////////////////////////////////////////////////
// R5P: Degu core
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
////////////////////////////////////////////////////////////////////////////////

package r5p_degu_pkg;

  typedef struct packed {
    // optimizations: BRU
    bit          BRU_BRU;  // enable dedicated BRanch Unit (comparator)
    bit          BRU_BRA;  // enable dedicated BRanch Adder
    // optimizations: ALU
    bit          ALU_LSA;  // enable dedicated Load/Store Adder (instead of sharing it with ALU)
    bit          ALU_LOM;  // enable dedicated Logical Operand Multiplexer
    bit          ALU_SOM;  // enable dedicated Shift   Operand Multiplexer
    // optimizations: LSU
    logic        VLD_ILL;  // valid        for illegal instruction
    logic        WEN_ILL;  // write enable for illegal instruction
    logic        WEN_IDL;  // write enable for idle !(LOAD | STORE)
    logic        BEN_IDL;  // byte  enable for idle !(LOAD | STORE)
    logic        BEN_ILL;  // byte  enable for illegal instruction
    // FPGA specific optimizations
    int unsigned SHF    ;  // shift per stage, 1 - LUT4, 2 - LUT6, else no optimizations
  } r5p_degu_cfg_t;

  localparam r5p_degu_cfg_t r5p_degu_cfg_def = '{
    // optimizations: BRU
    BRU_BRU: 1'b0,
    BRU_BRA: 1'b0,
    // optimizations: ALU
    ALU_LSA: 1'b0,
    ALU_LOM: 1'b1,
    ALU_SOM: 1'b0,
    // optimizations: LSU
    VLD_ILL: 1'bx,
    WEN_ILL: 1'bx,
    WEN_IDL: 1'bx,
    BEN_IDL: 1'bx,
    BEN_ILL: 1'bx,
    // FPGA specific optimizations
    SHF    : 2
  };

endpackage: r5p_degu_pkg
