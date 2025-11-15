# Application makefile.
# Use this makefile to configure all relevant CPU / compiler options.

# Override the default CPU ISA
MARCH = rv32i_zicsr_zifencei

# Override the default RISC-V GCC prefix
#RISCV_PREFIX ?= riscv-none-elf-

# Override default optimization goal
EFFORT = -Os

# Add extended debug symbols
USER_FLAGS += -ggdb -gdwarf-3

# Adjust processor IMEM size
USER_FLAGS += -Wl,--defsym,__neorv32_rom_size=128k

# Adjust processor DMEM size
USER_FLAGS += -Wl,--defsym,__neorv32_ram_size=32k

# Adjust maximum heap size
#USER_FLAGS += -Wl,--defsym,__neorv32_heap_size=1k

# Additional sources
APP_SRC = main.c
APP_INC += -I ../../lib_3rd/easylogger/inc
APP_SRC += ../../lib_3rd/easylogger/src/elog.c
APP_SRC += ../../lib_3rd/easylogger/src/elog_buf.c
APP_SRC += ../../lib_3rd/easylogger/src/elog_utils.c
APP_SRC += ../../lib_3rd/easylogger/port/elog_port.c

# Include the main NEORV32 makefile
# This is the heart of the build system.
# Make sure NEORV32_HOME points to the root of your NEORV32 project.
# By default, it looks 3 levels up from the current directory (../../..).
# If that's not correct, redefine it here or via the command line.
# NEORV32_HOME = /path/to/your/neorv32
NEORV32_HOME ?= ../../..
include $(NEORV32_HOME)/sw/common/common.mk