// For std::unique_ptr
#include <memory>

// SystemC global header
#include <systemc.h>

// Include common routines
#include <verilated.h>
#include <verilated_fst_sc.h>

// OS tools
#include <sys/stat.h>  // mkdir

// model header generated from SystemVerilog HDL code
#include "Vr5p_soc_top.h"

int sc_main(int argc, char **argv) {
    ////////////////////////////////////////////////////////////////////////////
    // verilator initialization
    ////////////////////////////////////////////////////////////////////////////

    // Prevent unused variable warnings
    if (false && argc && argv) {}

    // Create logs/ directory
    Verilated::mkdir("logs");

    // Before any evaluation, need to know to calculate those signals only used for tracing
    Verilated::traceEverOn(true);

    // parse Verilator arguments
    Verilated::commandArgs(argc, argv);

    // General logfile
    ios::sync_with_stdio();

    // system signals
    sc_clock              clk ("clk", 10, SC_NS, 0.5, 0, SC_NS, true);
    sc_signal<bool>       rst_n;
    sc_signal<vluint32_t> gpio;

    // Construct the Verilated model, from inside Vr5p_soc_top.h
    // Using unique_ptr is similar to "Vr5p_soc_top* top = new Vr5p_soc_top" then deleting at end
    const std::unique_ptr<Vr5p_soc_top> top{new Vr5p_soc_top{"top"}};

    // Attach Vr5p_soc_top's signals to this upper model
    top->clk  (clk);
    top->rst_n(rst_n);
    top->gpio (gpio);

    // You must do one evaluation before enabling waves, in order to allow
    // SystemC to interconnect everything for testing.
    sc_start(1,SC_NS);

    // If Verilator was invoked with --trace argument,
    // and if at run time passed the +trace argument, turn on tracing
    VerilatedFstSc* tfp = nullptr;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0==strcmp(flag, "+trace")) {
        cout << "Enabling waves into logs/vlt_dump.fst...\n";
        tfp = new VerilatedFstSc;
        top->trace(tfp, 99);
        Verilated::mkdir("logs");
        tfp->open("logs/vlt_dump.fst");
    }

    ////////////////////////////////////////////////////////////////////////////
    // test sequence
    ////////////////////////////////////////////////////////////////////////////

    // reset sequence
    rst_n = 0;
    sc_start(20, SC_NS);
    rst_n = 1;
    sc_start(200000, SC_NS);
    //sc_start();

    ////////////////////////////////////////////////////////////////////////////
    // Verilator cleanup
    ////////////////////////////////////////////////////////////////////////////

    // Final model cleanup
    top->final();
    // Close trace if opened
    if (tfp) {
        tfp->close();
        tfp = nullptr;
    }

    ////////////////////////////////////////////////////////////////////////////
    // exit simulation
    ////////////////////////////////////////////////////////////////////////////
    exit(0);
}
