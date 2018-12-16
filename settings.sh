# default OVP location
export OVP_HOME=$HOME/Workplace/Imperas.20180716

# OVP environment setup
. $OVP_HOME/bin/setup.sh
setupImperas -m32 $OVP_HOME
. $OVP_HOME/bin/switchRuntime.sh
switchRuntimeImperas
