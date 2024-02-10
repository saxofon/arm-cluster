TOP := $(PWD)

BUILD := $(TOP)/build

all:
	echo $(TOP)

-include lib.mk/*.mk
