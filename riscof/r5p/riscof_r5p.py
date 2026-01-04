import os
import logging

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class r5p(pluginTemplate):
    __model__ = "r5p"

    # TODO: please update the below to indicate family, version, etc of your DUT.
    __version__ = "X.X.X"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        # If the config node for this DUT is missing or empty. Raise an error.
        # At minimum we need the paths to the ispec and pspec files.
        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        # Number of parallel jobs that can be spawned off by RISCOF
        # for various actions performed in later functions, specifically to run the tests in
        # parallel on the DUT executable. Can also be used in the build function if required.
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

        # Path to the directory where this python file is located. Collect it from the config.ini.
        self.pluginpath = os.path.abspath(config['pluginpath'])

        # Collect the paths to the  riscv-config absed ISA and platform yaml files.
        # One can choose to hardcode these here itself instead of picking it from the config.ini file.
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        # We capture if the user would like the run the tests on the target or not.
        # If you are interested in just compiling the tests and not running them on the target,
        # then following variable should be set to False.
        if 'target_run' in config and config['target_run']=='0':
            self.target_run = False
        else:
            self.target_run = True

        # Capture HDL simulator choice.
        self.simulator = config['simulator']
        self.dut       = config['dut']

        # Enable/disable debug functionality
        self.debug = config['debug']

    def initialise(self, suite, work_dir, archtest_env):

        # Capture the working directory.
        # Any artifacts that the DUT creates should be placed in this directory.
        # Other artifacts from the framework and the Reference plugin will also be placed here.
        self.work_dir = work_dir

        # Capture the architectural test-suite directory.
        self.suite_dir = suite

        # Capture the environment.
        self.archtest_env = archtest_env

        # In case of an RTL based DUT, this would be point to the final binary executable of your
        # test-bench produced by a simulator (like verilator, vcs, incisive, etc).
        # In case of an iss or emulator, this variable could point to where the iss binary is located.
        # If PATH variable is missing in the config.ini we can hardcode the alternate here.
        # TODO: PATH?
        if   self.simulator == 'questa':
            self.dut_exe = f'DUT={self.dut} make -C {os.path.join(self.work_dir, "../../sim/questa/")} -f Makefile'
        elif self.simulator == 'verilator':
            self.dut_exe = f'DUT={self.dut} make -C {os.path.join(self.work_dir, "../../sim/verilator/")} -f Makefile'
        elif self.simulator == 'vivado':
            self.dut_exe = f'DUT={self.dut} make -C {os.path.join(self.work_dir, "../../sim/vivado/")} -f Makefile'
        else:
            # TODO: __model__ ?
            print("No simulator selected for '{__model__}'.")
            raise SystemExit(1)

    def build(self, isa_yaml, platform_yaml):

        # load the isa yaml as a dictionary in python.
        ispec = utils.load_yaml(isa_yaml)['hart0']

        # Capture the XLEN value by picking the max value in 'supported_xlen' field of isa YAML.
        # This will be useful in setting integer value in the compiler string (if not already hardcoded);
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')

        # For DUT start building the '--isa' argument.
        # The self.isa is DUT specific and may not be useful for all DUTs.
        self.isa = 'rv' + self.xlen
        for ext in ['I', 'M', 'C', 'F', 'D']:
            if ext in ispec["ISA"]:
                self.isa += ext.lower()

        # Note the march is not hardwired here, because it will change for each test.
        # Similarly the output elf name and compile macros will be assigned later in the runTests function.
        self.compile_exe = f'riscv{self.xlen}-unknown-elf-gcc'
        self.objcopy_exe = f'riscv{self.xlen}-unknown-elf-objcopy'
        self.objdump_exe = f'riscv{self.xlen}-unknown-elf-objdump'
        self.symbols_exe = f'riscv{self.xlen}-unknown-elf-nm'

    def runTests(self, testList):

        # TUDO: figure out why there is an extra character in the name.
        name = self.name[:-1]

        # Delete Makefile if it already exists.
        if os.path.exists(self.work_dir+ "/Makefile." + name):
                os.remove(self.work_dir+ "/Makefile." + name)
        # create an instance the makeUtil class that we will use to create targets.
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + name))

        # Set the make command that will be used.
        # The num_jobs parameter was set in the __init__ function earlier
        make.makeCommand = 'make -k -j' + self.num_jobs

        # We will iterate over each entry in the testList.
        # Each entry node will be referred to by the variable testname.
        for testname in testList:

            # For each testname we get all its fields (as described by the testList format).
            testentry = testList[testname]

            # We capture the path to the assembly file of this test.
            test = testentry['test_path']

            # Capture the directory where the artifacts of this test will be dumped/created.
            # RISCOF is going to look into this directory for the signature files.
            test_dir = testentry['work_dir']

            # Name of the elf file after compilation of the test.
            elf = os.path.join(test_dir, 'dut.elf')
            dis = os.path.join(test_dir, 'dut.disass')
            bin = os.path.join(test_dir, 'dut.bin')
            sym = os.path.join(test_dir, 'dut.symbols')
            log = os.path.join(test_dir, 'dut.log')
            sig = os.path.join(test_dir, name + ".signature")

            # Construct the command line for compiling testcase source assembly into an elf file.
            compile_cmd = self.compile_exe + (
                f' -mabi={'lp64' if (self.xlen == 64) else 'ilp32'}'
                f' -march={testentry['isa'].lower()}'
                f' -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles'
		f' -g'
                f' -T {self.pluginpath}/env/link.ld'
                f' -I {self.pluginpath}/env/'
                f' -I {self.archtest_env}'
                f' {test} -o {elf}'
                f' -D{" -D".join(testentry['macros'])}'
            )

            # Command for converting elf file into a binary/hex file for loading into HDL testbench memory.
            # Uncomment either the binary or hex version, depending on your.
            objcopy_cmd = self.objcopy_exe + f' -O binary {elf} {bin}'
            #objcopy_cmd = self.objcopy_exe + f' -O binary {elf} {elf}.hex'

            # Disassemble the ELF file for debugging purposes
            objdump_cmd = self.objdump_exe + (
                f' -M no-aliases -M numeric'
                f' -D {elf} > {dis}'
            )

            # extract listed symbols
            symbols_list = ['begin_signature', 'end_signature', 'tohost', 'fromhost']
            # construct dictionary of listed symbols
            symbols_cmd = []
            # get symbol list from elf file
            cmd = self.symbols_exe + f' {elf} > {sym}'
            symbols_cmd.append(cmd)

            # Simulation define macros.
            simulate_defines_dict = {}
            if self.debug:
                simulate_defines_dict.update({'TRACE_SPIKE': None})

            # Convert define macro dictionary into CLI
            # TODO: properly handle define macros without value
            if   self.simulator == 'questa':
                simulate_defines = ' '.join([f'-defineall {key}={val}' for key, val in simulate_defines_dict.items()])
            elif self.simulator == 'verilator':
                simulate_defines = ' '.join([f'-D{key}={val}'          for key, val in simulate_defines_dict.items()])
            elif self.simulator == 'vivado':
                simulate_defines = ' '.join([f'-d {key}={val}'         for key, val in simulate_defines_dict.items()])

            # Construct Verilog plusargs dictionary containing file paths.
            simulate_plusargs_dict = {
                'TEST_DIR': test_dir+'/'
            }

            # provide ELF symbols as plusargs
            for symbol in symbols_list:
                simulate_plusargs_dict.update({symbol: f'`grep -w {symbol} {sym} | cut -c 1-8`'})

            # Other DUT testbench specific Verilog plusargs can be added here.
            simulate_plusargs_dict.update({})

            # Convert Verilog plusargs dictionary into CLI
            if   self.simulator in ('questa', 'verilator'):
                simulate_plusargs = ' '.join([f'+{key}={val}' for key, val in simulate_plusargs_dict.items()])
            elif self.simulator == 'vivado':
                simulate_plusargs = ' '.join([f'-testplusarg {key}={val}' for key, val in simulate_plusargs_dict.items()])

	        # If the user wants to disable running the tests and only compile the tests,
            # then the "else" clause is executed below assigning the sim command to simple no action echo statement.
            if self.target_run:
                # set up the simulation command. Template is for spike. Please change.
                simulate_cmd = self.dut_exe + (
                    f' RISCOF_DEFINES="{simulate_defines}"'
                    f' RISCOF_PLUSARGS="{simulate_plusargs}"'
                )
            else:
                simulate_cmd = 'echo "NO RUN"'

            # Concatenate all commands that need to be executed within a make-target.
            execute = []
            execute.append(compile_cmd)
            execute.append(objcopy_cmd)
            execute.append(objdump_cmd)
            execute +=     symbols_cmd
            execute.append(simulate_cmd)

            # Create a target.
            # The makeutil will create a target with the name "TARGET<num>" where
            # num starts from 0 and increments automatically for each new target that is added.
            make.add_target('\n'.join(execute))

        # If you would like to exit the framework once the makefile generation is complete uncomment the following line.
        # Note this will prevent any signature checking or report generation.
        #raise SystemExit

        # Once the make-targets are done and the makefile has been created,
        # run all the targets in parallel using the make command set above.
        make.execute_all(self.work_dir)

        # If target runs are not required then we simply exit as this point after running all the makefile targets.
        if not self.target_run:
            raise SystemExit(0)

