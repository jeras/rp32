#!/bin/sh

################################################################################
# prepare OVPsim requirements
################################################################################

# Check if OVPsim Installation supports this example
checkinstall.exe -p OVP_install.pkg --nobanner || exit

# generate and compile the iGen created module
make -C OVP_module 

################################################################################
# compile combined evecutable containing
# - OVPsim harness (instruction tracing)
# - verilator campiled RTL (clock cycle tracing)
################################################################################

# compile the hand coded C harness
make -f Makefile.verilator

################################################################################
# cross compile test application
################################################################################

# compile the application
make -C ../src/

# run the module using the local C harness
sim --program ../src/test_isa.bin
