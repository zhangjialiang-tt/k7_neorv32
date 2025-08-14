# Script arguments: project_name part_name block_design_name bd_tcl_script
if {$argc < 4} {
  puts "ERROR: Incorrect number of arguments."
  puts "Usage: vivado -mode batch -source build_prj.tcl -tclargs <project_name> <part_name> <block_design_name> <bd_tcl_script>"
  exit 1
}

set _xil_proj_name_ [lindex $argv 0]
set _xil_part_name_ [lindex $argv 1]
set _xil_bd_name_ [lindex $argv 2]
set _xil_bd_tcl_script_ [lindex $argv 3]

puts "INFO: Project Name from Makefile: ${_xil_proj_name_}"
puts "INFO: Part Name from Makefile: ${_xil_part_name_}"
puts "INFO: Block Design Name from Makefile: ${_xil_bd_name_}"
puts "INFO: Block Design Script from Makefile: ${_xil_bd_tcl_script_}"

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}


# Create project
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part ${_xil_part_name_}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value "${_xil_part_name_}" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "9" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "9" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "9" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "9" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "9" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "9" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "9" -objects $obj
set_property -name "xpm_libraries" -value "XPM_FIFO XPM_MEMORY" -objects $obj

# Add user-specified IP repository path and update catalog
set_property ip_repo_paths ${origin_dir}/ip/uisrc [current_project]
update_ip_catalog

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

# Add HDL source files from src directory and its subdirectories, referencing original paths
add_files -fileset sources_1 -norecurse [list \
 [file normalize "${origin_dir}/rtl/top.v"] \
 [file normalize "${origin_dir}/rtl/common/DC_FIFO.v"] \
 [file normalize "${origin_dir}/rtl/common/capture_edge.v"] \
 [file normalize "${origin_dir}/rtl/common/gen_test.v"] \
 [file normalize "${origin_dir}/rtl/common/led_blink.v"] \
 [file normalize "${origin_dir}/rtl/common/data_avl_delay.vhd"] \
 [file normalize "${origin_dir}/rtl/common/sync_reset.v"] \
 [file normalize "${origin_dir}/rtl/common/signal_delay.v"] \
 [file normalize "${origin_dir}/rtl/common/sync_3ff.v"] \
 [file normalize "${origin_dir}/rtl/common/cmd.v"]\
 [file normalize "${origin_dir}/rtl/common/key/debounce_v2.v"]\
 [file normalize "${origin_dir}/rtl/common/guideir_ptic/divider/divider_guideir.v"]\
 [file normalize "${origin_dir}/rtl/common/guideir_ptic/divider/divider_wrapper.v"]\
 [file normalize "${origin_dir}/rtl/common/mult/parallel_ppl_mult_v1.20.v"]\
 [file normalize "${origin_dir}/rtl/common/BRAM/ramDualPort.v"]\
 [file normalize "${origin_dir}/rtl/common/BRAM/true_dual_port_ram.v"]\
 [file normalize "${origin_dir}/rtl/common/key/clk_divider.sv"]\
 [file normalize "${origin_dir}/rtl/common/key/edge_detect.sv"]\
 [file normalize "${origin_dir}/rtl/common/data_avl_delay.vhd"]\
 [file normalize "${origin_dir}/rtl/common/BRAM/lpm_dual_clk_port_ram.vhd"]\
 [file normalize "${origin_dir}/rtl/common/mult/multi_mxn.vhd"]\
 [file normalize "${origin_dir}/rtl/lib/verilog-axi/axi_dma.v"] \
 [file normalize "${origin_dir}/rtl/lib/verilog-axi/axi_dma_rd.v"] \
 [file normalize "${origin_dir}/rtl/lib/verilog-axi/axi_dma_wr.v"] \
 [file normalize "${origin_dir}/rtl/lib/verilog-axis/arbiter.v"] \
 [file normalize "${origin_dir}/rtl/lib/verilog-axis/priority_encoder.v"] \
 [file normalize "${origin_dir}/rtl/axi_video_bridge/axi_video_bridge.v"] \
 [file normalize "${origin_dir}/rtl/axi_video_bridge/axis_rd_path_new.v"] \
 [file normalize "${origin_dir}/rtl/axi_video_bridge/axis_wr_path_new.v"] \
 [file normalize "${origin_dir}/rtl/uivtc/rect.v"] \
 [file normalize "${origin_dir}/rtl/uivtc/uivtc.v"] \
 [file normalize "${origin_dir}/rtl/uitpg/uitpg.v"] \
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_package.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_application_image.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_bootloader_image.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_boot_rom.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_bus.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cache.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cfs.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_clint.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_fifo.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_decompressor.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_frontend.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_control.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_hwtrig.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_counters.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_regfile.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_shifter.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_muldiv.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_bitmanip.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_fpu.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_cfu.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_cond.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_cp_crypto.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_alu.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_lsu.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu_pmp.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_cpu.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_debug_auth.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_debug_dm.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_debug_dtm.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_dma.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_dmem.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_gpio.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_gptmr.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_imem.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_neoled.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_onewire.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_pwm.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_sdi.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_slink.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_spi.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_sys.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_sysinfo.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_xbus.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_wdt.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_uart.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_twi.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_twd.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_trng.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_tracer.vhd"]\
 [file normalize "${origin_dir}/ip/neorv32/core/neorv32_top.vhd"]\
]
# Define the list of custom XCI files to be added
# 注意这里列表直接包含的是XCI文件的路径，而不是整个IP目录
set custom_xci_files [list \
    "[file normalize "${origin_dir}/ip/uihdmitx_1/uihdmitx_1.xci"]"\
]

# Add only the XCI files to the 'sources_1' fileset
puts "INFO: Adding custom XCI files to the 'sources_1' fileset..."
# -norecurse 在这里仍然适用，因为它只是添加指定的文件
add_files -fileset sources_1 -norecurse $custom_xci_files

# Vivado会自动识别这些XCI文件为IP。
# 现在，明确地获取这些XCI文件对象，并生成它们的输出产品。
puts "INFO: Generating output products for individual XCI files..."
foreach xci_path $custom_xci_files {
    set normalized_xci_path [file normalize $xci_path]
    
    # 获取文件集中的XCI文件对象
    # 注意：在add_files之后，这些XCI文件对象应该已经存在于fileset中
    set xci_obj [get_files -of_objects [get_filesets sources_1] $normalized_xci_path]

    if {[llength $xci_obj] > 0} {
        puts "    Generating target for IP: [file tail $normalized_xci_path]"
        if {[catch {generate_target all $xci_obj} result]} {
            puts "    ERROR: Failed to generate output products for [file tail $normalized_xci_path]: $result"
            # 这里的错误处理可以根据需要决定是否退出脚本
        } else {
            puts "    Successfully generated output products for [file tail $normalized_xci_path]."
        }
    } else {
        # 理论上，如果add_files成功，这里不应该发生
        puts "    WARNING: Could not find file object for XCI: $normalized_xci_path after adding. Skipping target generation."
    }
}

set file "$origin_dir/ip/neorv32/core/neorv32_package.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_application_image.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_bootloader_image.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_boot_rom.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_bus.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cache.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cfs.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_clint.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_fifo.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_decompressor.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_frontend.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_control.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_hwtrig.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_counters.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_regfile.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_shifter.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_muldiv.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_bitmanip.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_fpu.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_cfu.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_cond.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_cp_crypto.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_alu.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_lsu.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu_pmp.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_cpu.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_debug_auth.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_debug_dm.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_debug_dtm.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_dma.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_dmem.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_gpio.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_gptmr.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_imem.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_neoled.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_onewire.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_pwm.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_sdi.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_slink.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_spi.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_sys.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_sysinfo.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_xbus.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_wdt.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_uart.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_twi.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_twd.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_trng.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_tracer.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj

set file "$origin_dir/ip/neorv32/core/neorv32_top.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL" -objects $file_obj
set_property -name "library" -value "neorv32" -objects $file_obj
# Add MIG project files if needed (usually handled by XCI)
add_files -fileset sources_1 -norecurse [list \
 [file normalize "${origin_dir}/ip/design_1_mig_7series_0_0/mig_b.prj" ]\
 [file normalize "${origin_dir}/ip/design_1_mig_7series_0_0/mig_a.prj" ]\
]

# Set 'sources_1' fileset file properties for local files
set file "design_1_mig_7series_0_0/mig_b.prj"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "scoped_to_cells" -value "design_1_mig_7series_0_0" -objects $file_obj

set file "design_1_mig_7series_0_0/mig_a.prj"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "scoped_to_cells" -value "design_1_mig_7series_0_0" -objects $file_obj


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "top" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Automatically add all xdc files in the constrs directory
set xdc_files [glob -nocomplain -directory "$origin_dir/constrs" *.xdc]
foreach xdc_file $xdc_files {
  set file "[file normalize $xdc_file]"
  add_files -fileset constrs_1 [list $file]
  set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*/[file tail $file]"]]
  set_property -name "file_type" -value "XDC" -objects $file_obj
}

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_part" -value "${_xil_part_name_}" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "top" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
# Empty (no sources present)

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]


# Adding sources referenced in BDs, if not already added


# Source the build_bd.tcl script passed from Makefile.
puts "INFO: Sourcing Block Design Tcl script: ${_xil_bd_tcl_script_}"

if {[catch {source ${_xil_bd_tcl_script_}} result]} {
  puts "ERROR: Failed to source ${_xil_bd_tcl_script_}: $result"
  exit 1
}

set bd_file_path "./${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1/bd/${_xil_bd_name_}/${_xil_bd_name_}.bd"

if {![file exists $bd_file_path]} {
  puts "ERROR: Block design file not found after sourcing build_bd.tcl: $bd_file_path"
  # Attempt to find it with a more generic path if the project structure is slightly different
  set alt_bd_file_path [get_files -quiet ${_xil_bd_name_}.bd]
  if {$alt_bd_file_path eq ""} {
    puts "ERROR: Could not find ${_xil_bd_name_}.bd anywhere."
    exit 1
  } else {
    puts "INFO: Found BD file at: $alt_bd_file_path"
    set bd_file_path $alt_bd_file_path
  }
}

set_property REGISTERED_WITH_MANAGER "1" [get_files $bd_file_path]
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files $bd_file_path]

update_compile_order -fileset sources_1
reset_target all [get_files $bd_file_path]
export_ip_user_files -of_objects  [get_files  $bd_file_path] -sync -no_script -force -quiet
delete_ip_run [get_files -of_objects [get_fileset sources_1] $bd_file_path]

# Generate output products for all IPs in the block design
puts "INFO: Generating output products for all IPs in ${_xil_bd_name_}.bd..."
if {[catch {generate_target all [get_files $bd_file_path]} result]} {
  puts "ERROR: Failed to generate IP output products for ${_xil_bd_name_}.bd: $result"
  # Consider exiting if IP generation fails critically
  # exit 1 
} else {
  puts "INFO: Successfully generated IP output products for ${_xil_bd_name_}.bd or they are up-to-date."
}

#call make_wrapper to create wrapper files
puts "INFO: Creating wrapper for ${_xil_bd_name_}.bd"
set wrapper_path [make_wrapper -fileset sources_1 -files [get_files $bd_file_path] -top]
add_files -norecurse -fileset sources_1 $wrapper_path


set idrFlowPropertiesConstraints ""
catch {
 set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
 set_param runs.disableIDRFlowPropertyConstraints 1
}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part ${_xil_part_name_} -flow {Vivado Synthesis 2021} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2021" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj

# }
set obj [get_runs synth_1]
set_property -name "part" -value "${_xil_part_name_}" -objects $obj
set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part ${_xil_part_name_} -flow {Vivado Implementation 2021} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2021" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Implementation Default Reports} $obj
set_property set_report_strategy_name 0 $obj
set obj [get_runs impl_1]
set_property -name "part" -value "${_xil_part_name_}" -objects $obj
set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]
catch {
 if { $idrFlowPropertiesConstraints != {} } {
   set_param runs.disableIDRFlowPropertyConstraints $idrFlowPropertiesConstraints
 }
}

puts "INFO: Project created:${_xil_proj_name_}"
