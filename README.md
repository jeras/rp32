# Short

```bash

```

```bash
export VERILATOR_ROOT=/home/ijeras/VLSI/verilator
cd sim
make -f Makefile.verilator lint
make -f Makefile.verilator
```

# Requirements

The default script is using ModelSim (version from Altera/Intel) for simulation.

## Verilator

```Bash
export SYSTEMC_INCLUDE=/opt/systemc-2.3.2/include/
export SYSTEMC_LIBDIR=/opt/systemc-2.3.2/lib-linux64/
```


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

# OVP simulator

[www.OVPworld.org](http://www.OVPworld.org) only provides a 32 bit version of OVPsim.
So 32 bit support must be installed on 64 bit systems.

```shell
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libc6-i386
sudo apt-get install lib32stdc++6
sudo apt-get install lib32z1 lib32ncurses5 lib32bz2-1.0
sudo apt-get install gcc-multilib g++-multilib
```

To be able to download OVPsim, an account must be first created on OVPworld.org.
Apparently all OVPsim [download](http://www.ovpworld.org/dlp/) links
point to the same installer file.

Follow instructions in `Imperas_Installation_and_Getting_Started.pdf`.

The downloaded `OVPsim.*.exe` executable must have the executable flag set,
before beeing executed.

```shell
$ chmod +x OVPsim.20180716.0.Linux32.exe
$ sudo ./OVPsim.20180716.0.Linux32.exe
```

Type `yes` to accept the license,
and then `no` to be able to install into an alternative location.
This instructions are written for the the `/opt/OVPsim-20181114/` install path.

Environment variables must be set. Add the following lines to `settings.sh`.

```shell
export OVP_HOME=$HOME/Workplace/Imperas.20181114
. $OVP_HOME/bin/setup.sh
setupImperas -m32 $OVP_HOME
. $OVP_HOME/bin/switchRuntime.sh
switchRuntimeImperas
```


https://wiki.ubuntu.com/DebootstrapChroot
https://github.com/shoes/shoes3/wiki/Setup-an-schroot-build-environment
http://logan.tw/posts/2018/02/24/manage-chroot-environments-with-schroot/

```shell
# apt install debootstrap schroot
# vi /etc/schroot/chroot.d/bionic32
$ mkdir $HOME/Workplace/bionic32
sudo debootstrap --variant=buildd --arch i386 bionic $HOME/Workplace/bionic32 http://archive.ubuntu.com/ubuntu/
schroot -c bionic32 -u root
```

```
cat <<EOT >> /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ bionic main restricted
deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ bionic universe
deb http://archive.ubuntu.com/ubuntu/ bionic-updates universe
deb http://archive.ubuntu.com/ubuntu/ bionic multiverse
deb http://archive.ubuntu.com/ubuntu/ bionic-updates multiverse
deb http://security.ubuntu.com/ubuntu bionic-security main restricted
deb http://security.ubuntu.com/ubuntu bionic-security universe
deb http://security.ubuntu.com/ubuntu bionic-security multiverse
EOT
apt update
apt upgrade
apt install software-properties-common
add-apt-repository ppa:aelmahmoudy/ppa
add-apt-repository ppa:iztok.jeras/ppa
apt install gcc g++ verilator libsystemc-dev

```

```ini
[bionic32]
description=Ubuntu 18.04 (Bionic Beaver) 32-bit
directory=$HOME/Workplace/bionic32
personality=linux32
root-users=$USER
type=directory
users=$USER
```
