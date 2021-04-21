// SystemC global header
#include <systemc.h>

// Include common routines
#include <verilated.h>
#include <verilated_fst_sc.h>

// OS tools
#include <sys/stat.h>  // mkdir

// OVP RISC-V simulator
//extern "C" {
//#include "op/op.h"
//}

// RTL
#include "Vr5p_tb.h"

int sc_main(int argc, char **argv) {
    ////////////////////////////////////////////////////////////////////////////
    // verilator initialization
    ////////////////////////////////////////////////////////////////////////////

    // parse Verilator arguments
    Verilated::commandArgs(argc, argv);

    // system signals
    sc_clock        clk ("clk", 10, SC_NS, 0.5, 0, SC_NS, true);
    sc_signal<bool> rst;

    Vr5p_tb* top;
    top = new Vr5p_tb("top");   // SP_CELL (top, Vour);

    top->clk(clk);           // SP_PIN  (top, clk, clk);
    top->rst(rst);           // TODO add a sequence

    // Before any evaluation, need to know to calculate those signals only used for tracing
    Verilated::traceEverOn(true);

    // You must do one evaluation before enabling waves, in order to allow
    // SystemC to interconnect everything for testing.
    sc_start(1,SC_NS);

    // If Verilator was invoked with --trace argument,
    // and if at run time passed the +trace argument, turn on tracing
    VerilatedFstSc* tfp = NULL;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0==strcmp(flag, "+trace")) {
        cout << "Enabling waves into logs/vlt_dump.fst...\n";
        tfp = new VerilatedFstSc;
        top->trace(tfp, 99);
        mkdir("logs", 0777);
        tfp->open("logs/vlt_dump.fst");
    }

//    ////////////////////////////////////////////////////////////////////////////
//    // OVPsim initialization
//    ////////////////////////////////////////////////////////////////////////////
//
//    opSessionInit(OP_VERSION);
//
//    opCmdParseStd (argv[0], OP_AC_ALL, argc, (const char**) argv);
//
//    optModuleP mr = opRootModuleNew(0, 0, 0);
//    optModuleP mi = opModuleNew(mr, "OVP_module", "u1", 0, 0);
//
//    opRootModulePreSimulate(mr);
//
//    // Get processor
//    optProcessorP processor = opProcessorNext(mi, NULL);
//
//    if(!processor)
//        opMessage("F", "MODULE", "No Processor Found");
//
//    opMessage("I", "MODULE", "Trace processor '%s'", opObjectName(processor));

    ////////////////////////////////////////////////////////////////////////////
    // test sequence
    ////////////////////////////////////////////////////////////////////////////

    // reset sequence
    rst = 1;
    sc_start(20, SC_NS);
    rst = 0;

    //while (!Verilated::gotFinish()) { sc_start(30, SC_NS); }
    sc_start(400, SC_NS);

    ////////////////////////////////////////////////////////////////////////////
    // Verilator cleanup
    ////////////////////////////////////////////////////////////////////////////

    // Final model cleanup
    top->final();
    // Close trace if opened
    if (tfp) { tfp->close(); tfp = NULL; }
    // cleanup
    delete top;

//    ////////////////////////////////////////////////////////////////////////////
//    // OVPsim cleanup
//    ////////////////////////////////////////////////////////////////////////////
//
//    opSessionTerminate();

    ////////////////////////////////////////////////////////////////////////////
    // exit simulation
    ////////////////////////////////////////////////////////////////////////////
    exit(0);
}
