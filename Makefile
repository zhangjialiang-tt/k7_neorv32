# Makefile for Vivado Project Management

# --- Variables ---
# Project Name (must match the one in build_prj.tcl or be passed as an argument)

# Select different TCL scripts based on project name
# a200_base corresponds to Black Gold development board
# k7_base corresponds to Little Panda development board
# mlk_base corresponds to Mi Lian Ke development board (not implemented)
#! Note: Do not add spaces after variable names
PROJECT_NAME ?= k7_dma
# Vivado Part
PART_NAME ?= xc7k325tffg676-2
BLOCK_DESIGN_NAME ?= design_1
# Vivado Executable (adjust if necessary)
VIVADO := vivado

# Directories
SCRIPT_DIR := ./tcl
PROJECT_DIR := ./${PROJECT_NAME}
BUILD_PRJ_TCL := ${SCRIPT_DIR}/build_prj.tcl
BUILD_BD_TCL := ${SCRIPT_DIR}/build_bd.tcl
MMI_TCL := ${SCRIPT_DIR}/run_mmi.tcl
PROGRAM_MCS_TCL := ${SCRIPT_DIR}/program_mcs.tcl

# Output files
BITSTREAM := ${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/top.bit
XSA_FILE := ${PROJECT_DIR}/${PROJECT_NAME}.xsa
# MCS file related variables
MCS_FILE := ${PROJECT_DIR}/${PROJECT_NAME}.mcs
CREATE_MCS_SCRIPT := ${SCRIPT_DIR}/run_mcs.tcl
MEMORY_INTERFACE ?= SPIx4
MEMORY_SIZE ?= 16

# Vitis/SDK Variables
VITIS_WORKSPACE_DIR := ./vitis_workspace
VITIS_WORKSPACE_DIR_2 := ./vitis_workspace_bootloader
VITIS_PLATFORM_NAME := ${PROJECT_NAME}_pfm
VITIS_PLATFORM_NAME_2 := Bootloader_pfm
VITIS_APP_NAME := hello_world
ELF_FILE := ${VITIS_WORKSPACE_DIR}/${VITIS_APP_NAME}/Debug/${VITIS_APP_NAME}.elf
SREC_FILE := ${VITIS_WORKSPACE_DIR}/${VITIS_APP_NAME}_system/_ide/flash/${VITIS_APP_NAME}.elf.srec
BIF_FILE := ${VITIS_WORKSPACE_DIR}/${VITIS_APP_NAME}_system/_ide/flash/bootimage.bif
BIN_FILE := ${VITIS_WORKSPACE_DIR}/${VITIS_APP_NAME}_system/_ide/flash/BOOT.bin
BIF_FILE2 := ${VITIS_WORKSPACE_DIR_2}/Bootloader_system/_ide/flash/bootimage.bif
BIN_FILE2 := ${VITIS_WORKSPACE_DIR_2}/Bootloader_system/_ide/flash/BOOT.bin

# Check operating system
OS_NAME := $(shell uname -s)
# Print OS_NAME
$(info OS_NAME is $(OS_NAME))

ifeq ($(OS),Windows_NT)
	XSCT := C:\\Software\\Xilinx\\Vitis\\2021.1\\bin\\xsct.bat
	VITIS_CMD := C:\Software\Xilinx\Vitis\2021.1\bin\vitis.bat
	MB_OBJCOPY := C:\Software\Xilinx\Vivado\2021.1\gnu\microblaze\nt\bin\mb-objcopy.exe
else ifeq ($(OS_NAME),Linux)
	XSCT := /opt/Xilinx/Vitis/2021.1/bin/xsct
	VITIS_CMD := /opt/Xilinx/Vitis/2021.1/bin/vitis
	MB_OBJCOPY := /opt/Xilinx/Vivado/2021.1/gnu/microblaze/lin/bin/mb-objcopy
else
    $(error Unsupported operating system)
endif

# XSCT := xsct
TEMPLATE := {Hello World}#{Hello World}#{lwIP Echo Server}

# --- Merge bit and bootloader into download.bit ---
BOOTLOADER_ELF := firmware/Bootloader.elf
DOWNLOAD_BIT := firmware/download.bit

# BOOTLOADER_ELF := ${VITIS_WORKSPACE_DIR_2}/Bootloader/Debug/Bootloader.elf
BOOTLOADER_BIT := ${VITIS_WORKSPACE_DIR_2}/Bootloader/_ide/bitstream/${PROJECT_NAME}.bit
MMI_FILE := ${PROJECT_DIR}/${PROJECT_NAME}.runs/memory.mmi
MERGE_PROC := u_microblaze/u_risv_soc/design_1_i/microblaze_0

# --- Program ELF and merged bit file to Flash ---
FLASH_ELF := ${ELF_FILE}
FLASH_BIT := ${DOWNLOAD_BIT}
FLASH_TOOL := program_flash
FLASH_CABLE := xilinx_tcf
FLASH_URL := TCP:127.0.0.1:3121
# k7_base development board
# FLASH_TYPE := mx25l25645g-spi-x1_x2_x4
# PTRW022 main board
FLASH_TYPE := mx25l25645g-spi-x1_x2_x4
FLASH_ELF_OFFSET := 0x00800000
FLASH_BIT_OFFSET := 0
# Phony targets
.PHONY: all build_hw synth impl bitstream export_hw program create_sw_platform create_app_project build_sw download_all run_sw clean open_project vivado open_vitis_ide help program_bit program_elf erase_flash print_cpu_cores

# --- Targets ---

# Default target
all: bitstream

# Create the Vivado project structure using the Tcl script
build_hw: ${PROJECT_DIR}/${PROJECT_NAME}.xpr

${PROJECT_DIR}/${PROJECT_NAME}.xpr:
	@echo "INFO: Creating Vivado project '${PROJECT_NAME}' with part '${PART_NAME}'..."
	${VIVADO} -mode batch -source ${BUILD_PRJ_TCL} -tclargs ${PROJECT_NAME} ${PART_NAME} ${BLOCK_DESIGN_NAME}
	@echo "INFO: Project creation script finished."

# Run Synthesis
synth: build_hw ${PROJECT_DIR}/${PROJECT_NAME}.runs/synth_1/top.dcp

${PROJECT_DIR}/${PROJECT_NAME}.runs/synth_1/top.dcp: ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	@echo "INFO: Launching Synthesis..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/run_synth.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${PROJECT_NAME}
	@echo "INFO: Synthesis finished."

# Run Implementation
impl: synth ${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/top_routed.dcp

${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/top_routed.dcp: ${PROJECT_DIR}/${PROJECT_NAME}.runs/synth_1/top.dcp
	@echo "INFO: Launching Implementation..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/run_impl.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${PROJECT_NAME}
	@echo "INFO: Implementation finished."

# Generate Bitstream
bitstream: impl ${BITSTREAM}

${BITSTREAM}: ${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/top_routed.dcp
	@echo "INFO: Generating Bitstream..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/run_bitstream.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${PROJECT_NAME}
	@echo "INFO: Bitstream generation finished."
bit: bitstream

# Reset synthesis and implementation runs
reset_runs:
	@echo "INFO: Resetting synthesis and implementation runs..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/reset_runs.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	@echo "INFO: Reset finished."

# Delete synthesis and implementation runs
delete_runs:
	@echo "INFO: Deleting synthesis and implementation runs..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/delete_runs.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	@echo "INFO: Delete finished."

# Export Hardware (XSA) for Vitis/SDK
export_hw: 
	@echo "INFO: Exporting hardware (XSA)..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/export_hw.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${PROJECT_NAME} ${PROJECT_DIR}/${PROJECT_NAME}.xsa
	@echo "INFO: Hardware export (XSA) finished."

# Create Vitis Software Platform
create_sw_platform:
	@echo "INFO: Creating Vitis software platform '${VITIS_PLATFORM_NAME}'..."
	@mkdir -p ${VITIS_WORKSPACE_DIR}
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR}; platform create -name ${VITIS_PLATFORM_NAME} -hw ${XSA_FILE}; platform active ${VITIS_PLATFORM_NAME}; domain create -name standalone_microblaze_0 -os standalone -proc microblaze_0; domain active standalone_microblaze_0; platform generate; platform write; exit"
	@echo "INFO: Vitis software platform creation finished."

# Create Vitis Application Project
create_app_project:
	@echo "INFO: Creating Vitis application project '${VITIS_APP_NAME}'..."
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR}; platform active ${VITIS_PLATFORM_NAME}; app create -name ${VITIS_APP_NAME} -template ${TEMPLATE} -platform ${VITIS_PLATFORM_NAME} -domain {standalone_microblaze_0}; exit"
#	@echo "INFO: Replacing with local source files..."
#	@echo "INFO: Removing existing files in application src..."
#	rm -rf "${VITIS_WORKSPACE_DIR}/${VITIS_APP_NAME}/src"/*
#	@echo "INFO: Copying demo source files to application..."
#	cp -r ./demo/src/* "${VITIS_WORKSPACE_DIR}/${VITIS_APP_NAME}/src/"
#	@echo "INFO: Source files replacement complete."
	@echo "INFO: Vitis application project creation finished."

# Build Vitis Software Application
build_sw: export_hw create_sw_platform create_app_project
	@echo "INFO: Building Vitis software application '${VITIS_APP_NAME}'..."
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR}; platform active ${VITIS_PLATFORM_NAME}; app build -name ${VITIS_APP_NAME}; exit"
	@echo "INFO: Vitis software application build finished."

# Generate MCS file
gen_mcs:
	${VIVADO} -mode batch -source ${CREATE_MCS_SCRIPT} -tclargs \
		--bitstream_file ${BITSTREAM} \
		--output_file ${MCS_FILE} \
		--interface ${MEMORY_INTERFACE} \
		--memory_size ${MEMORY_SIZE} \
		--force yes
download_mcs: gen_mcs
	@echo "INFO: Programming MCS file to Flash..."
	${VIVADO} -mode batch -source ${PROGRAM_MCS_TCL} -tclargs ${MCS_FILE} ${FLASH_TYPE} ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	@echo "INFO: MCS file programming finished."

# Run software on target (usually after programming FPGA or for debugging)
run_sw: build_sw
	@echo "INFO: Running software on target (using XSCT)..."
	@echo "INFO: Ensure JTAG is connected and hardware server is running."
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR}; connect; targets -set -filter {name =~ \"*MicroBlaze #0*\"}; dow ${ELF_FILE}; con; exit"
	@echo "INFO: Software run command finished."

# --- Bootloader example generation ---
mmi_info:
	${VIVADO} -mode batch -source ${MMI_TCL} -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${PROJECT_DIR}/${PROJECT_NAME}.runs

bootloader:mmi_info
	@echo "INFO: Please ensure the XSA file has been generated."
	# Create bootloader platform and app, and initial build
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR_2}; platform create -name ${VITIS_PLATFORM_NAME_2} -hw ${XSA_FILE}; platform active ${VITIS_PLATFORM_NAME_2}; domain create -name standalone_microblaze_0 -os standalone -proc microblaze_0; domain active standalone_microblaze_0;  bsp setlib -name xilffs xilisf; platform generate; platform write; exit"
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR_2}; platform active ${VITIS_PLATFORM_NAME_2}; app create -name Bootloader -template {SREC SPI Bootloader} -platform ${VITIS_PLATFORM_NAME_2} -domain {standalone_microblaze_0}; app build -name Bootloader; exit"
	@echo "INFO: Initial Bootloader project creation and build finished."

	@echo "INFO: Replacing with local source files for Bootloader..."
	@echo "INFO: Removing existing files in Bootloader src..."
	rm -rf "${VITIS_WORKSPACE_DIR_2}/Bootloader/src"/*
	@echo "INFO: Copying demo source files to Bootloader application..."
	cp -r ./demo/bootloader/* "${VITIS_WORKSPACE_DIR_2}/Bootloader/src/"
	@echo "INFO: Source files replacement complete for Bootloader."

	@echo "INFO: Re-compiling Bootloader after source replacement..."
	${XSCT} -eval "setws ${VITIS_WORKSPACE_DIR_2}; platform active ${VITIS_PLATFORM_NAME_2}; app build -name Bootloader; exit"
	@echo "INFO: Bootloader re-compilation finished."
	@echo "INFO: Vitis Bootloader project fully set up and compiled."
boot: bootloader

merge_bootloader: ${DOWNLOAD_BIT}

${DOWNLOAD_BIT}: mmi_info
	@echo "INFO: Merging bit file and Bootloader ELF into download.bit..."
	cp ${ELF_FILE} firmware
	updatemem -force -meminfo ${MMI_FILE} -bit ${BITSTREAM} -data ${BOOTLOADER_ELF} -proc ${MERGE_PROC} -out ${DOWNLOAD_BIT}
	@echo "INFO: download.bit generation completed."

# --- New target: Generate BIF file using XSCT Tcl script ---
gen_bif:
	@echo "INFO: Generating BIF file via XSCT..."
	${XSCT} -eval "source ${SCRIPT_DIR}/gen_bif.tcl; gen_bif ${SREC_FILE} ${BIF_FILE}"
	${XSCT} -eval "source ${SCRIPT_DIR}/gen_bif.tcl; gen_bif ${DOWNLOAD_BIT} ${BIF_FILE2}"
	@echo "INFO: BIF file generation completed."
flash_elf_bit:gen_bif
	${MB_OBJCOPY} -O srec ${ELF_FILE} ${SREC_FILE}
	bootgen -arch fpga -image ${BIF_FILE} -w -o ${BIN_FILE} -interface spi
	@echo "INFO: Programming user ELF file to Flash first..."
	${FLASH_TOOL} -f ${BIN_FILE} -offset ${FLASH_ELF_OFFSET} -flash_type ${FLASH_TYPE} -blank_check -verify

	@echo "INFO: Programming merged bit file to Flash next..."
	bootgen -arch fpga -image ${BIF_FILE2} -w -o ${BIN_FILE2} -interface spi
	${FLASH_TOOL} -f ${BIN_FILE2} -offset ${FLASH_BIT_OFFSET} -flash_type ${FLASH_TYPE}
	@echo "INFO: Flash programming completed."

program:
	@echo "INFO: Programming FPGA with bitstream and loading ELF (if applicable)..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/program_fpga.tcl -tclargs ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${BITSTREAM}
	@echo "INFO: FPGA programming script finished."

program_fast:
	@echo "INFO: Programming FPGA with bitstream (fast method)..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/program_fpga_fast.tcl -tclargs ${BITSTREAM}
	@echo "INFO: FPGA programming script finished."

# --- Erase Flash ---
erase_flash:
	@echo "INFO: Erasing Flash..."
	# program_flash requires a file to identify FPGA on JTAG chain, using project's bit file here
	# If bit file doesn't exist, this command will fail. Please run 'make bitstream' first
	${FLASH_TOOL} -f ${BITSTREAM} -flash_type ${FLASH_TYPE} -erase_all
	@echo "INFO: Flash erase completed."

# Open Vivado GUI
open_project:
	@echo "INFO: Opening Vivado GUI for project ${PROJECT_NAME}..."
	${VIVADO} ${PROJECT_DIR}/${PROJECT_NAME}.xpr
vivado: open_project
v: vivado

# Open Vitis IDE
open_vitis_ide:
	@echo "INFO: Opening Vitis IDE for workspace ${VITIS_WORKSPACE_DIR}..."
	@echo "INFO: Ensure the Vitis application project has been created (make create_app_project)."
	${VITIS_CMD} -workspace ${VITIS_WORKSPACE_DIR}
vitis: open_vitis_ide
vi: vitis

# New target to print CPU core count
print_cpu_cores:
	@echo "INFO: Detecting CPU core count..."
	${VIVADO} -mode batch -source ${SCRIPT_DIR}/get_cpu_core.tcl
	@echo "INFO: CPU core count detection finished."


# Clean generated files
clean:
	@echo "INFO: Cleaning project directory..."
	rm -rf ${PROJECT_DIR}
	rm -rf ${VITIS_WORKSPACE_DIR}
	rm -rf ${VITIS_WORKSPACE_DIR_2}
	rm -rf vivado*.log vivado*.jou .Xil *.xsa *.log *.jou *.str
	@echo "INFO: Cleaning IP directory..."
	python ip/clean_ip.py
	@echo "INFO: Clean finished."

unpack:
	rm -rf .git 
	7z x -y git.tar.gz
	7z x -y git.tar
	rm git.tar.gz git.tar
pack:
	python git_changed_files.py --package --all-files

# Help target
help:
	@echo "Makefile for Vivado Project Management"
	@echo ""
	@echo "Usage:"
	@echo "  make all                - 创建 Vivado 工程，并依次执行综合、实现、生成比特流"
	@echo "  make build_hw           - 创建/重新创建 Vivado 工程"
	@echo "  make synth              - 运行综合"
	@echo "  make impl               - 运行实现 (依赖于综合)"
	@echo "  make bitstream 或 make bit - 生成比特流 (.bit) 文件 (依赖于实现)"
	@echo "  make export_hw 或 make hw - 导出硬件平台 (.xsa) 文件 (依赖于比特流)"
	@echo "  make create_sw_platform - 基于 XSA 创建 Vitis 平台工程 (依赖于 XSA)"
	@echo "  make create_app_project - 创建 Vitis 应用工程并从 demo/src 拷贝源码 (依赖于平台)"
	@echo "  make build_sw 或 make sw  - 编译 Vitis 应用工程，生成 .elf 文件 (依赖于应用工程)"
	@echo "  make all_sw             - 完整硬件+软件流程 (all -> export_hw -> create_sw_platform -> create_app_project -> build_sw)"
	@echo "  make backup_sw          - 将 Vitis 工作区的源码备份回 demo/src"
	@echo "  make program            - 通过 JTAG 下载比特流到 FPGA"
	@echo "  make run_sw             - 通过 JTAG 运行 .elf 文件 (需先 program FPGA)"
	@echo "  make gen_mcs            - 生成 .mcs 格式的 Flash 烧写文件 (包含 bit 和 elf)"
	@echo "  make download_mcs       - 通过 JTAG 烧写 .mcs 文件到 Flash"
	@echo "  make bootloader 或 make boot - 创建并编译 Bootloader 工程"
	@echo "  make merge_bootloader   - 合并 bit 文件和 bootloader.elf，生成 download.bit (用于固化 Bootloader)"
	@echo "  make flash_elf_bit      - 一键烧写 download.bit 和用户程序到 Flash (自动处理 .bif 和 .bin) - 该方式目前不可用"
	@echo "  make download_all       - (推荐) 分别烧写用户程序和合并后的 download.bit 到 Flash"
	@echo "  make erase_flash        - 擦除整个 Flash 存储器 (危险操作)"
	@echo "  make open_project 或 make v - 使用 GUI 模式打开 Vivado 工程"
	@echo "  make open_vitis_ide 或 make vi - 使用 GUI 模式打开 Vitis 工作区"
	@echo "  make print_cpu_cores    - 打印 Vivado 可用的 CPU 核心数"
	@echo "  make help               - 显示此帮助信息"
	@echo ""
	@echo "可覆盖变量:"
	@echo "  PROJECT_NAME (默认: PTRW022)"
	@echo "  PART_NAME (默认: xc7a200tfbg484-2)"
	@echo "  BLOCK_DESIGN_NAME (默认: design_1)"
	@echo "  MEMORY_INTERFACE (默认: SPIx4)"
	@echo "  MEMORY_SIZE (默认: 16)"
	@echo "  VIVADO (默认: vivado)"
	@echo ""