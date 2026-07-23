## This file is a general .sdc for the Tang Nano 9k

## Clock signal
#create_clock -period 37.037 -name clk -waveform {0.000 18.5185} [get_ports XTAL_IN];  #  27.0 MHz on board XTAL
#create_clock -period 37.037 -name clk [get_ports XTAL_IN];  #  27.0 MHz on board XTAL
create_clock -period 100 -name XTAL_IN [get_ports XTAL_IN];  #  27.0 MHz on board XTAL


#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];
#create_clock -period 100.000 -name clk -waveform {0.000 50.000} [get_ports CLK100MHZ];  #  10.0 MHz
#create_clock -period  40.000 -name clk -waveform {0.000 20.000} [get_ports CLK100MHZ];  #  25.0 MHz
#create_clock -period  30.000 -name clk -waveform {0.000 15.000} [get_ports CLK100MHZ];  #  33.3 MHz
#create_clock -period  25.000 -name clk -waveform {0.000 12.500} [get_ports CLK100MHZ];  #  40.0 MHz
#create_clock -period  20.000 -name clk -waveform {0.000 10.000} [get_ports CLK100MHZ];  #  50.0 MHz
#create_clock -period  18.000 -name clk -waveform {0.000  9.000} [get_ports CLK100MHZ];  #  55.5 MHz
#create_clock -period  16.000 -name clk -waveform {0.000  8.000} [get_ports CLK100MHZ];  #  62.5 MHz (with NO extra adders)
#create_clock -period  15.000 -name clk -waveform {0.000  7.500} [get_ports CLK100MHZ];  #  66.6 MHz
#create_clock -period  12.500 -name clk -waveform {0.000  6.250} [get_ports CLK100MHZ];  #  80.0 MHz
#create_clock -period  12.000 -name clk -waveform {0.000  6.000} [get_ports CLK100MHZ];  #  83.3 MHz
#create_clock -period  10.000 -name clk -waveform {0.000  5.000} [get_ports CLK100MHZ];  # 100.0 MHz
