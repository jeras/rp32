////////////////////////////////////////////////////////////////////////////////
// R5P: package
////////////////////////////////////////////////////////////////////////////////

package r5p_pkg;

// Hardware Performance Monitor events
typedef struct packed {
  logic cycle;       // 00 - clock cycle
  logic reserved;    // 01 - reserved (similar to gap between CSR mcycle and instret)
  logic instret;     // 02 - instruction retire
  logic compressed;  // 03 - compressed instruction retire
  logic ls_wait;     // 04 - load/store delay (cache/memory/periphery access wait cycle)
  logic if_wait;     // 05 - instruction fetch delay (instruction cache/memory access wait cycle)
  logic load;        // 06 - load operation
  logic store;       // 07 - store operation
  logic jump;        // 08 - unconditional jump
  logic branch;      // 09 - branch
  logic taken;       // 10 - branch taken
  logic mul_wait;    // 11 - multiply delay
  logic div_wait;    // 12 - divide delay
} r5p_hpmevent_t;

endpackage: r5p_pkg