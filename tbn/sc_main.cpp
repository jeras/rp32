// SystemC global header
#include <systemc.h>

// Include common routines
#include <verilated.h>
#include <verilated_vcd_sc.h>

#include <sys/stat.h>  // mkdir

// RTL
#include "Vrp_tb.h"

int sc_main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // system signals
    sc_clock        clk ("clk", 10, SC_NS, 0.5, 3, SC_NS, true);
    sc_signal<bool> rst;

    Vrp_tb* top;
    top = new Vrp_tb("top");   // SP_CELL (top, Vour);

    top->clk(clk);           // SP_PIN  (top, clk, clk);
    top->rst(rst);           // TODO add a sequence

    // Before any evaluation, need to know to calculate those signals only used for tracing
    Verilated::traceEverOn(true);

    // You must do one evaluation before enabling waves, in order to allow
    // SystemC to interconnect everything for testing.
    sc_start(1,SC_NS);

    // If verilator was invoked with --trace argument,
    // and if at run time passed the +trace argument, turn on tracing
    VerilatedVcdSc* tfp = NULL;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0==strcmp(flag, "+trace")) {
        cout << "Enabling waves into logs/vlt_dump.vcd...\n";
        tfp = new VerilatedVcdSc;
        top->trace(tfp, 99);
        mkdir("logs", 0777);
        tfp->open("logs/vlt_dump.vcd");
    }

    // reset sequence
    rst = 1;
    sc_start(100, SC_NS);
    rst = 0;

    //while (!Verilated::gotFinish()) { sc_start(30, SC_NS); }
    sc_start(100, SC_NS);

    // Final model cleanup
    top->final();
    // Close trace if opened
    if (tfp) { tfp->close(); tfp = NULL; }
    // cleanup
    delete top;
    exit(0);
}
