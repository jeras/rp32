// Verilator driver for the r5p_mouse SoC gate-level co-simulation.
// Holds reset, then free-runs the boot program, checking RTL == netlist every
// cycle.  Exit code 0 on match, 1 on any mismatch.
#include <verilated.h>
#include "Vtb.h"
#include <cstdio>
#include <cstdlib>

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  unsigned ncyc = (argc > 1) ? std::strtoul(argv[1], nullptr, 0) : 6000;

  Vtb* d = new Vtb;
  auto tick = [&]() { d->clk = 0; d->eval(); d->clk = 1; d->eval(); };

  // hold reset
  d->rst = 1; d->gpio_i = 0x12345678; d->uart_rxd = 1;
  for (int i = 0; i < 8; i++) tick();
  d->rst = 0;

  long mismatches = 0;
  int first = -1;
  for (unsigned i = 0; i < ncyc; i++) {
    tick();
    if (d->mismatch) { if (first < 0) first = (int)i; mismatches++; }
  }
  d->final();

  std::printf("cycles=%u mismatches=%ld first_mismatch=%d\n",
              ncyc, mismatches, first);
  if (mismatches) { std::printf("COSIM FAIL\n"); return 1; }
  std::printf("COSIM PASS\n");
  return 0;
}
