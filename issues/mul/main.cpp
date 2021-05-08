#include "Vmul.h"
#include "verilated.h"

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vmul* top = new Vmul;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    exit(0);
}
