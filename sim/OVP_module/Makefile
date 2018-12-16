ifndef IMPERAS_HOME
  IMPERAS_ERROR := $(error "IMPERAS_HOME not defined, please setup Imperas/OVP environment")
endif
IMPERAS_HOME := $(shell getpath.exe "$(IMPERAS_HOME)")
NOVLNV?=1
include $(IMPERAS_HOME)/ImperasLib/buildutils/Makefile.module

