Report on early experience with Tang Nano 9k (Gowin EDA and open source tools).
I have now been experimenting with the board for about a month.

## Open source tools

The main resources here would be PicoRV32 and learnFPGA.
Official projects from [Sipeed](GITHUB) using Gowin EDA are based on PicoRV32
and many tutorials using open source tools are based on code from learnFPGA (FemtoRV32).
Lack of reports categorized warnings/errors synthesis logic utilization, timing, FPGA IO. STA?

### learnFPGA

The learnFPGA tutorial is an excellent resource using Yosys, Apicula and nextpnr.

While I listed more CONS than PROS, this is more the result of me
focusing on details where it comes to issues and the big picture where it comes to advantages.

PROS:
- easy to use, just follow the instructions step by step,
- the instructions are focused on editing a few files, so you don't get lost in the environment,
- the open source tools are reasonably fast, and they seem to do their job,
- I actually got to see LEDs blinking, not just waveforms.

CONS:
- does not follow some modern HDL coding practices:
  - multiple module implementations inside a single file,
  - use of `include` for combining sources from multiple files instead of listing them in a build script,
  - rather extensive use of macros, while unavoidable in some cases, they make the code difficult to read,
  - use of `defparam` which is considered for deprecation in future versions of the SystemVerilog standard,
  - lack of timing diagrams for the system bus (I still don't know how exactly is the handshake supposed to work, so I can't make a proper assessment of its throughput).

Most examples worked, but at least for some LED blinking stopped after a few changes.
I still have to check (look at simulation waveforms) whether this is expected, a bug in the RTL/firmware, or a problem with the tools.

### SystemVerilog using Yosys-Slang

I had some success compiling my SystemVerilog code.
I think it is great, although I already have a bug to report (WIP, won't forget).

Now I am struggling with compiling code containing black boxes (PLL, RAM16SDP*, BRAM blocks, ...).
I have some idea what I am supposed to do, and it seems to work if the `yosys-slang` plugin is not used,
but I have not found script examples to copy from yet.

Using the PSRAM memory is convoluted (thanks Gowin) and it will be harder to get it to work than I expected.
I also worry about timing constraints, I have seen developers complaining about it not working at higher frequencies.

## Gowin EDA

There are a few extra steps needed (`LD_LIBRARY_PATH`, font library) to run the tool on Ubuntu 24.04.
Beginners might give up before getting through those, but this is just about making instructions easier to find.

```
sudo mv /opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/lib/libfreetype.so.6 /opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/lib/libfreetype.so.6.bkp
LD_LIBRARY_PATH=/opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/lib/ /opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/bin/gw_ide
```

It took me some time to figure out how to tell Gowin EDA to compile my sources using SystemVerilog 2017, and then where the setting is actually stored.

The Gowin EDA tool seems to have significantly lower logic utilization then Yosys, about 45%.
But it also consumed 2 times the BRAM resources needed (Yosys did this correctly).
I did not debug this yet, I did not see the same issue when I increased the size of the RAM.

The timing report seems to use a default clock of 50MHz, while my timing constraint file seems to have been parsed, but it is at least partially ignored.
This issue corrected itself after some time I do not know what specifically I changed.
I also have this kind of issue with open source tools.

### Gowin EDA version control (Git)

The following files specific to the Gowin EDA project should be under version control:
- `PROJECT/PROJECT.gprj` (list of source files),
- `PROJECT/impl/PROJECT_process_config.json` (project configuration, SystemVerilog/VHDL standard version, include paths, ...),
- `PROJECT/src/PROJECT.cst` (pinout and pin properties like voltage and current),
- `PROJECT/src/PROJECT.sdc` (timing constraints, ...),
- HDL source file can be outside the project.

There are differences with how Gowin IDE and Yosys/... handle `*.cst` and `*.sdc` files,
so it might make sense not to use the same files for both projects.

