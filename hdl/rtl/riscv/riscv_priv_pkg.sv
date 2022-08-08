///////////////////////////////////////////////////////////////////////////////
// RISC-V privileged package (based on privileged spec)
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

package riscv_priv_pkg;

// privilege level
typedef enum logic [1:0] {
  LVL_U = 2'b00,  // User/Application
  LVL_S = 2'b01,  // Supervisor
  LVL_R = 2'b10,  // Reserved
  LVL_M = 2'b11   // Machine
} isa_level_t;

// access permissions
// NOTE: from privileged spec
typedef enum logic [2-1:0] {
  ACCESS_RW0 = 2'b00,  // read/write
  ACCESS_RW1 = 2'b01,  // read/write
  ACCESS_RW2 = 2'b10,  // read/write
  ACCESS_RO3 = 2'b11   // read-only
} csr_perm_t;

// CSR address structure
// NOTE: from privileged spec
typedef struct packed {
   csr_perm_t  perm;
   isa_level_t level;
   logic [7:0] addr;
} csr_adr_t;

endpackage: riscv_priv_pkg