# Requirements

The default script is using ModelSim (version from Altera/Intel) for simulation.

## Ubuntu 18.04, `Quartus-lite-18.0.0.614-linux.tar`

I had some problems with the installer crashing at the end of the install process,
but apparently the tools were installed.

Some instructions:
http://www.bitsnbites.eu/installing-intelaltera-quartus-in-ubuntu-17-10/

After installing ModelSim, a symbolink link must be created:
```
cd $HOME/intelFPGA_lite/18.0/modelsim_ase
ln -s linux linux_rh60
```

