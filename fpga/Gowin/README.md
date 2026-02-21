# Sipeed: Tang Nano 9K

https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html

Gowin GW1NR-9 FPGA

https://www.gowinsemi.com/en/support/database/1781/
https://dl.sipeed.com/shareURL/TANG/Nano%209K/6_Chip_Manual/EN

DataSheet
https://www.gowinsemi.com/upload/database_doc/1785/document/68f69723d7d7d.pdf
GW1N/GW1NR series of FPGA Products Schematic Manual
https://www.gowinsemi.com/upload/database_doc/1795/document/69457ab88bc5b.pdf

Gowin BSRAM & SSRAM
https://cdn.gowinsemi.com.cn/UG285E.pdf

## Gowin IDE

```
sudo mv //opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/lib/libfreetype.so.6 //opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/lib/libfreetype.so.6.bkp
```

```
LD_LIBRARY_PATH=/opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/lib/ /opt/Gowin/Gowin_V1.9.11.03_Education_Linux/IDE/bin/gw_ide
```

## PSRAM

Based on Sipeed datasheet, this devices were produced before version C existed.
LQ144P GW1NR-9 PSRAM 64M 16 bits

https://github.com/enjoy-digital/litex/blob/70b6dc93f658824de4d43a5e0904f2c415ea3ef4/litex/build/gowin/gowin.py#L92-L113
https://github.com/litex-hub/litex-boards/blob/master/litex_boards/targets/sipeed_tang_nano_9k.py#L89-L115
https://github.com/litex-hub/litex-boards/blob/master/litex_boards/platforms/sipeed_tang_nano_9k.py#L56-L62


https://www.reddit.com/r/GowinFPGA/comments/1kqzzs5/built_a_riscv_soc_on_a_tang_nano_9k_using_litex/
https://fabianalvarez.dev/posts/litex/first_steps/

https://github.com/SantaCRC/tutorials

https://github.com/zf3/psram-tang-nano-9k

https://github.com/calint/tang-nano-9k--riscv--cache-psram
