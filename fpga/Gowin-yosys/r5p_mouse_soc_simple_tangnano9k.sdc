## This file is a general .sdc for the Tang Nano 9k

## Clock signal
#create_clock -period 37.037 -name XTAL_IN -waveform {0.000 18.5185} [get_ports XTAL_IN];  #  27.0 MHz on board XTAL
create_clock -period 37.037 -name XTAL_IN [get_ports XTAL_IN];  #  27.0 MHz on board XTAL
