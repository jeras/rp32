// SystemC global header
#include <systemc.h>

// Include common routines
#include <verilated.h>
#include <verilated_vcd_sc.h>

// OS tools
#include <sys/stat.h>  // mkdir

// Spike simulator
#include "sim.h"

// RTL
#include "Vrp_tb.h"

static std::vector<std::pair<reg_t, mem_t*>> make_mems(const char* arg)
{
  // handle legacy mem argument
  char* p;
  auto mb = strtoull(arg, &p, 0);
  if (*p == 0) {
    reg_t size = reg_t(mb) << 20;
    if (size != (size_t)size)
      throw std::runtime_error("Size would overflow size_t");
    return std::vector<std::pair<reg_t, mem_t*>>(1, std::make_pair(reg_t(DRAM_BASE), new mem_t(size)));
  }

  // handle base/size tuples
  std::vector<std::pair<reg_t, mem_t*>> res;
  while (true) {
    auto base = strtoull(arg, &p, 0);
    auto size = strtoull(p + 1, &p, 0);
    res.push_back(std::make_pair(reg_t(base), new mem_t(size)));
    if (!*p)
      break;
    arg = p + 1;
  }
  return res;
}


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


    const char *isa = "RV64IMAFDC";
    size_t cores = 1;
    uint64_t pc = 0x80000000;
    const char *msize = "2048";
    std::vector<std::pair<reg_t, mem_t*>> mems = make_mems(msize);
    std::vector<std::string> htif_args;
    std::vector<int> hartids; // null hartid vector
    // initiate the spike simulator
    htif_args.push_back("pk");
    htif_args.push_back("");
    spike = NULL;

    spike = new sim_t(isa, cores, false, (reg_t)(pc), mems, htif_args, hartids, 2, 0, false );

    // setup the pre-runtime parameters
    spike->set_debug(false);
    spike->set_log(log);
    spike->set_histogram(false);
    spike->set_sst_func((void *)(&SR));

    // run the sim
    rtn = spike->run();


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
