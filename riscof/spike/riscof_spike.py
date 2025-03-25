import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class spike(pluginTemplate):
    __model__ = "spike"
    __version__ = "0.1.0"

    def __init__(self, *args, **kwargs):
        """
        Process config.ini file and setup logging.
        """
        sclass = super().__init__(*args, **kwargs)

        config = kwargs.get('config')
        if config is None:
            logger.error(self.name + " config node is missing.")
            raise SystemExit(1)
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath = os.path.abspath(config['pluginpath'])
        self.isa_spec = os.path.abspath(config['ispec']) if 'ispec' in config else ''
        self.platform_spec = os.path.abspath(config['pspec']) if 'ispec' in config else ''
        self.make = config['make'] if 'make' in config else 'make'
        logger.debug(self.name + " plugin initialized using the following configuration:")
        self.config = config
        for entry in config:
            logger.debug(entry+' : '+config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        """
        Prepare toolchain, and model executables.
        Checking whether the executables are available is done in the build step,
        since this step lacks XLEN information from YAML files.
        """
        self.suite = suite
        self.work_dir = work_dir

        # NOTE: The following assumes you are using the riscv-gcc toolchain.
        #       If not please change appropriately.
        # prepare toolchain executables ({} to be replaced with XLEN)
        self.objdump_exe = 'riscv{}-unknown-elf-objdump'
        self.compile_exe = 'riscv{}-unknown-elf-gcc'

        # prepare toolchain command template
        self.objdump_cmd = self.objdump_exe + ' -D {} > {}'
        self.compile_cmd = self.compile_exe + (
            ' -march={}'
            ' -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles'
            ' -T ' + self.pluginpath + '/env/link.ld'
            ' -I ' + self.pluginpath + '/env/'
            ' -I ' + archtest_env
        )

        # prepare model executable
        self.ref_exe = os.path.join(self.config['PATH'] if 'PATH' in self.config else "","spike")

    def build(self, isa_yaml, platform_yaml):
        """
        Build is run only once before running for each test list.
        """
        # load ISA YAML file
        ispec = utils.load_yaml(isa_yaml)['hart0']

        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        # construct ISA string
        self.isa = 'rv' + self.xlen
        for ext in ['I', 'M', 'C', 'F', 'D']:
            self.isa += ext.lower()

        # NOTE: The following assumes you are using the riscv-gcc toolchain.
        #       If not please change appropriately.
        # extend compiler command with ABI (integer and floating-point calling convention)
        self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')

        # check if toolchain executables are available
        for tool in [self.compile_exe, self.objdump_exe]:
            tool_xlen = tool.format(self.xlen)
            if shutil.which(tool_xlen) is None:
                logger.error(tool_xlen + ": executable not found. Please check environment setup.")
                raise SystemExit(1)
            
        # check if the reference executable is available
        if shutil.which(self.ref_exe.format(self.xlen)) is None:
            logger.error(self.ref_exe.format(self.xlen) + ": executable not found. Please check environment setup.")
            raise SystemExit(1)
        
        # check if 'make' is available
        if shutil.which(self.make) is None:
            logger.error(self.make + ": executable not found. Please check environment setup.")
            raise SystemExit(1)

    def runTests(self, testList, cgf_file=None):
        # remove ':' from the end of the name
        name = self.name[:-1]
        if os.path.exists(self.work_dir+ "/Makefile." + name):
            os.remove(self.work_dir+ "/Makefile." + name)
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + name))
        make.makeCommand = self.make + ' -j' + self.num_jobs
        for file in testList:
            testentry = testList[file]
            test = testentry['test_path']
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/',1)[1][:-2]

            elf = 'ref.elf'

            execute = ''

            # prepare list of commands to execute
            cmd = "@cd " + testentry['work_dir']
            execute += f'{cmd};\\\n'

            # NOTE: The following assumes you are using the riscv-gcc toolchain.
            #       If not please change appropriately.
            # compile testcase assembly into an elf file
            cmd = self.compile_cmd.format(self.xlen, testentry['isa'].lower()) + (
                f' {test}'
                f' -o {elf}'
                f' -D{" -D".join(testentry['macros'])}'
            )
            execute += f'{cmd};\\\n'

            # dump disassembled elf file
            cmd = self.objdump_cmd.format(self.xlen, elf, 'ref.disass')
            execute += f'{cmd};\\\n'

            # run reference model
            cmd = self.ref_exe + f' --isa={self.isa} --log-commits --signature={name}.signature {elf} > {test_name}.log 2>&1'
            execute += f'{cmd};\\\n'


            make.add_target(execute)
        make.execute_all(self.work_dir)
