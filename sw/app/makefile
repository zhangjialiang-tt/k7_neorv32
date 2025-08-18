# Example Application Makefile for Custom HAL

# Add your application C sources here
APP_SRC = main.c

# Add your custom HAL C sources here
APP_SRC += hal.c

# Add your application include folders (if any, besides the current directory)
# APP_INC += -I ./my_include_dir

# Add your application assembly sources (if any)
# APP_SRC += my_asm.S

# Add your application object files (if any, pre-compiled)
# APP_OBJ += my_precompiled_obj.o

# Add your assembly include folders (if any, besides the current directory)
# ASM_INC += -I ./my_asm_include_dir

# Optimization level
EFFORT ?= -Os

# CPU architecture and ABI
# The default is rv32i_zicsr_zifencei (integer-only ISA)
# If your application uses floating-point, you might need to change this.
# MARCH = rv32imc_zicsr_zifencei # Example for FPU
MARCH = rv32i_zicsr_zifencei
MABI = ilp32

# User flags for additional configuration
# Example: Using the standard NEORV32 UART0 for stdio
USER_FLAGS += -DNEORV32_UART0_STANDARD_BAUD=19200
# Example: Enable automatic context save/restore for interrupts (RTE)
# USER_FLAGS += -DNEORV32_RTE_ENABLE

# Include the main NEORV32 makefile
# This is the heart of the build system.
# Make sure NEORV32_HOME points to the root of your NEORV32 project.
# By default, it looks 3 levels up from the current directory (../../..).
# If that's not correct, redefine it here or via the command line.
# NEORV32_HOME = /path/to/your/neorv32
NEORV32_HOME ?= ../..
include $(NEORV32_HOME)/sw/common/common.mk