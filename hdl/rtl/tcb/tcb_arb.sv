////////////////////////////////////////////////////////////////////////////////
// TCB: Tightly Coupled Bus arbiter
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

module tcb_arb #(
  // bus parameters
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data    width
  int unsigned SW = DW/8,  // benect  width
  // interconnect parameters
  int unsigned BN = 2      // bus number
)(
  tcb_if.sub s[BN-1:0],  // TCB subordinate ports (manager     devices connect here)
  tcb_if.man m           // TCB manager     ports (subordinate device connects here)
);

// TODO: write the implementation

endmodule: tcb_arb