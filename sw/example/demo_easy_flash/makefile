MARCH = rv32i_zicsr_zifencei
EFFORT = -Os
USER_FLAGS += -ggdb -gdwarf-3
USER_FLAGS += -Wl,--defsym,__neorv32_rom_size=128k
USER_FLAGS += -Wl,--defsym,__neorv32_ram_size=32k

APP_SRC = main.c
APP_SRC += easyflash/src/easyflash.c
APP_SRC += easyflash/src/ef_env.c
APP_SRC += easyflash/src/ef_utils.c
APP_SRC += easyflash/src/ef_log.c
APP_SRC += easyflash/port/ef_port.c
APP_SRC += spi_flash/source/spi_flash_hal.c

APP_INC += -I ./easyflash/inc
APP_INC += -I ./easyflash/plugins/types/inc
APP_INC += -I ./spi_flash/include

NEORV32_HOME ?= ../../..
include $(NEORV32_HOME)/sw/common/common.mk