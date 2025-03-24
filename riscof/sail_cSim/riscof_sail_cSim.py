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
from riscv_isac.isac import isac

logger = logging.getLogger()

class sail_cSim(pluginTemplate):
    __model__ = "sail_c_simulator"
    __version__ = "0.5.0"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)

        config = kwargs.get('config')
        if config is None:
            logger.error("Config node for" + self.__model__ + " is missing.")
            raise SystemExit(1)
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath = os.path.abspath(config['pluginpath'])
        self.ref_exe = { '32' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_rv32d"),
                         '64' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_rv64d")}
        self.isa_spec = os.path.abspath(config['ispec']) if 'ispec' in config else ''
        self.platform_spec = os.path.abspath(config['pspec']) if 'ispec' in config else ''
        self.make = config['make'] if 'make' in config else 'make'
        logger.debug(self.__model__ + " plugin initialised using the following configuration.")
        for entry in config:
            logger.debug(entry+' : '+config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.suite = suite
        self.work_dir = work_dir
        # NOTE: The following assumes you are using the riscv-gcc toolchain.
        #       If not please change appropriately.
        # prepare toolchain executables
        self.objdump = 'riscv{0}-unknown-elf-objdump'
        self.compile = 'riscv{0}-unknown-elf-gcc'
        # prepare toolchain command template
        self.objdump_cmd = self.objdump + '-D {1} > {2};'
        self.compile_cmd = self.compile +
            ' -march={1}' +
            ' -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles' +
            ' -T ' + self.pluginpath + '/env/link.ld' +
            ' -I ' + self.pluginpath + '/env/' +
            ' -I ' + archtest_env

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)['hart0']
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        # construct ISA string
        self.isa = 'rv' + self.xlen
        for ext in ['I', 'M', 'C', 'F', 'F', 'D']:
            self.isa += ext.lower()
        # NOTE: The following assumes you are using the riscv-gcc toolchain.
        #       If not please change appropriately.
        # extend compiler command with ABI (integer and floating-point calling convention)
        mabi = 'lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 '
        self.compile_cmd = self.compile_cmd+' -mabi='+mabi
        # check if toolchain executables are available
        for tool in [self.compile, self.objdump]
            tool_xlen = tool.format(self.xlen)
            if shutil.which(tool_xlen) is None:
                logger.error(tool_xlen + ": executable not found. Please check environment setup.")
                raise SystemExit(1)
        # check if the reference executable is available
        if shutil.which(self.ref_exe[self.xlen]) is None:
            logger.error(self.ref_exe[self.xlen] + ": executable not found. Please check environment setup.")
            raise SystemExit(1)
        # check if 'make' is available
        if shutil.which(self.make) is None:
            logger.error(self.make + ": executable not found. Please check environment setup.")
            raise SystemExit(1)

    def runTests(self, testList, cgf_file=None):
        if os.path.exists(self.work_dir+ "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir+ "/Makefile." + self.name[:-1])
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = self.make + ' -j' + self.num_jobs
        for file in testList:
            testentry = testList[file]
            test = testentry['test_path']
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/',1)[1][:-2]

            elf = 'ref.elf'

            execute = "@cd "+testentry['work_dir']+";"

            cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen) + ' ' + test + ' -o ' + elf
            compile_cmd = cmd + ' -D' + " -D".join(testentry['macros'])
            execute+=compile_cmd+";"

            execute += self.objdump_cmd.format(self.xlen, elf, 'ref.disass')
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

            execute += self.ref_exe[self.xlen] + ' --test-signature={0} {1} > {2}.log 2>&1;'.format(sig_file, elf, test_name)

            cov_str = ' '
            for label in testentry['coverage_labels']:
                cov_str+=' -l '+label

            if cgf_file is not None:
                coverage_cmd = 'riscv_isac --verbose info coverage -d \
                        -t {0}.log --parser-name c_sail -o coverage.rpt  \
                        --sig-label begin_signature  end_signature \
                        --test-label rvtest_code_begin rvtest_code_end \
                        -e ref.elf -c {1} -x{2} {3};'.format(\
                        test_name, ' -c '.join(cgf_file), self.xlen, cov_str)
            else:
                coverage_cmd = ''


            execute+=coverage_cmd

            make.add_target(execute)
        make.execute_all(self.work_dir)
