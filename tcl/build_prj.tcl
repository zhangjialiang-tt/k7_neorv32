# Optimized Vivado Project Build Script
# Arguments: project_name part_name block_design_name bd_tcl_script
# Usage: vivado -mode batch -source build_prj_optimized.tcl -tclargs <project_name> <part_name> <block_design_name> <bd_tcl_script>

# Parse command line arguments
if {$argc < 4} {
    puts "ERROR: Incorrect number of arguments."
    puts "Usage: vivado -mode batch -source build_prj_optimized.tcl -tclargs <project_name> <part_name> <block_design_name> <bd_tcl_script>"
    exit 1
}

set _xil_proj_name_ [lindex $argv 0]
set _xil_part_name_ [lindex $argv 1]
set _xil_bd_name_ [lindex $argv 2]
set _xil_bd_tcl_script_ [lindex $argv 3]

# Configuration parameters
set origin_dir "."
if {[info exists ::origin_dir_loc]} {
    set origin_dir $::origin_dir_loc
}

# Logging function
proc log_info {message} {
    puts "INFO: $message"
}

proc log_error {message} {
    puts "ERROR: $message"
}

proc log_warning {message} {
    puts "WARNING: $message"
}

# File processing procedures
proc normalize_and_add_files {file_paths fileset_name} {
    set normalized_paths {}
    foreach file_path $file_paths {
        lappend normalized_paths [file normalize $file_path]
    }
    add_files -fileset $fileset_name -norecurse $normalized_paths
    return $normalized_paths
}

proc set_vhdl_properties {file_path library_name fileset_name} {
    set normalized_path [file normalize $file_path]
    set file_obj [get_files -of_objects [get_filesets $fileset_name] [list "*$normalized_path"]]
    if {[llength $file_obj] > 0} {
        set_property -name "file_type" -value "VHDL" -objects $file_obj
        set_property -name "library" -value $library_name -objects $file_obj
    }
}

proc generate_ip_targets {xci_files} {
    foreach xci_path $xci_files {
        set xci_obj [get_files -of_objects [get_filesets sources_1] $xci_path]
        if {[llength $xci_obj] > 0} {
            log_info "Generating target for IP: [file tail $xci_path]"
            if {[catch {generate_target all $xci_obj} result]} {
                log_error "Failed to generate output products for [file tail $xci_path]: $result"
            } else {
                log_info "Successfully generated output products for [file tail $xci_path]"
            }
        }
    }
}

# Main script execution
log_info "Starting optimized project creation for: $_xil_proj_name_"
log_info "Part Name: $_xil_part_name_"
log_info "Block Design Name: $_xil_bd_name_"
log_info "Block Design Script: $_xil_bd_tcl_script_"

# Create project
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part ${_xil_part_name_}
set proj_dir [get_property directory [current_project]]

# Set project properties efficiently
set obj [current_project]
set project_properties {
    "default_lib" "xil_defaultlib"
    "enable_vhdl_2008" "1"
    "ip_cache_permissions" "read write"
    "mem.enable_memory_map_generation" "1"
    "revised_directory_structure" "1"
    "simulator_language" "Mixed"
    "webtalk.activehdl_export_sim" "9"
    "webtalk.ies_export_sim" "9"
    "webtalk.modelsim_export_sim" "9"
    "webtalk.questa_export_sim" "9"
    "webtalk.riviera_export_sim" "9"
    "webtalk.vcs_export_sim" "9"
    "webtalk.xsim_export_sim" "9"
    "xpm_libraries" "XPM_FIFO XPM_MEMORY"
}

foreach {prop_name prop_value} $project_properties {
    set_property -name $prop_name -value $prop_value -objects $obj
}

# Set dynamic properties
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "part" -value "${_xil_part_name_}" -objects $obj

# Configure IP repository
set_property ip_repo_paths ${origin_dir}/ip/uisrc [current_project]
update_ip_catalog

# Create filesets only if they do not already exist (to support re-entry / nested sourcing)
if {[llength [get_filesets -quiet sources_1]] == 0} {
    create_fileset -srcset sources_1
}
if {[llength [get_filesets -quiet constrs_1]] == 0} {
    create_fileset -constrset constrs_1
}
if {[llength [get_filesets -quiet sim_1]] == 0} {
    create_fileset -simset sim_1
}

# Define source file groups for better organization
# Note: origin_dir is already an absolute/normalized base (Vivado launches with workspace as CWD),
# so do NOT embed "${origin_dir}" literally inside the strings (which caused paths like ".../${origin_dir}/rtl/top.v")
set rtl_files [list \
    [file join $origin_dir rtl top.v] \
    [file join $origin_dir rtl common DC_FIFO.v] \
    [file join $origin_dir rtl common capture_edge.v] \
    [file join $origin_dir rtl common gen_test.v] \
    [file join $origin_dir rtl common led_blink.v] \
    [file join $origin_dir rtl common data_avl_delay.vhd] \
    [file join $origin_dir rtl common sync_reset.v] \
    [file join $origin_dir rtl common signal_delay.v] \
    [file join $origin_dir rtl common sync_3ff.v] \
    [file join $origin_dir rtl common cmd.v] \
    [file join $origin_dir rtl common key debounce_v2.v] \
    [file join $origin_dir rtl common guideir_ptic divider divider_guideir.v] \
    [file join $origin_dir rtl common guideir_ptic divider divider_wrapper.v] \
    [file join $origin_dir rtl common mult parallel_ppl_mult_v1.20.v] \
    [file join $origin_dir rtl common BRAM ramDualPort.v] \
    [file join $origin_dir rtl common BRAM true_dual_port_ram.v] \
    [file join $origin_dir rtl common key clk_divider.sv] \
    [file join $origin_dir rtl common key edge_detect.sv] \
    [file join $origin_dir rtl common BRAM lpm_dual_clk_port_ram.vhd] \
    [file join $origin_dir rtl common mult multi_mxn.vhd] \
]

set axi_files [list \
    [file join $origin_dir rtl lib verilog-axi axi_dma.v] \
    [file join $origin_dir rtl lib verilog-axi axi_dma_rd.v] \
    [file join $origin_dir rtl lib verilog-axi axi_dma_wr.v] \
    [file join $origin_dir rtl lib verilog-axis arbiter.v] \
    [file join $origin_dir rtl lib verilog-axis priority_encoder.v] \
    [file join $origin_dir rtl axi_video_bridge axi_video_bridge.v] \
    [file join $origin_dir rtl axi_video_bridge axis_rd_path_new.v] \
    [file join $origin_dir rtl axi_video_bridge axis_wr_path_new.v] \
]

set vtc_files [list \
    [file join $origin_dir rtl uivtc rect.v] \
    [file join $origin_dir rtl uivtc uivtc.v] \
    [file join $origin_dir rtl uitpg uitpg.v] \
]

# Add RTL files efficiently
set all_rtl_files [concat $rtl_files $axi_files $vtc_files]
normalize_and_add_files $all_rtl_files sources_1

# Define and add NEORV32 core files (use file join to avoid nested "${origin_dir}" text)
set neorv32_core_files [list \
    [file join $origin_dir ip neorv32 core neorv32_package.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_sys.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_decompressor.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_frontend.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_control.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_hwtrig.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_prim.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_counters.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_regfile.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_shifter.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_muldiv.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_bitmanip.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_fpu.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_cfu.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_cond.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_cp_crypto.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_alu.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_lsu.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_pmp.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu_trace.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cpu.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cache.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_bus.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_dma.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_application_image.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_imem.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_dmem.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_xbus.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_bootloader_image.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_boot_rom.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_cfs.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_sdi.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_gpio.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_wdt.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_clint.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_uart.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_spi.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_twi.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_twd.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_pwm.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_trng.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_neoled.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_gptmr.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_onewire.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_slink.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_tracer.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_sysinfo.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_debug_dtm.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_debug_auth.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_debug_dm.vhd] \
    [file join $origin_dir ip neorv32 core neorv32_top.vhd] \
]

normalize_and_add_files $neorv32_core_files sources_1

# Set VHDL properties for NEORV32 files in batch
foreach file_path $neorv32_core_files {
    set_vhdl_properties $file_path "neorv32" sources_1
}

# Add custom IP XCI file
set custom_xci_files [list [file join $origin_dir ip uihdmitx_1 uihdmitx_1.xci]]
log_info "Adding custom XCI files to sources_1..."
normalize_and_add_files $custom_xci_files sources_1
generate_ip_targets $custom_xci_files

# Add MIG project files
set mig_files [list \
    [file join $origin_dir ip design_1_mig_7series_0_0 mig_b.prj] \
    [file join $origin_dir ip design_1_mig_7series_0_0 mig_a.prj] \
]
normalize_and_add_files $mig_files sources_1

# Set MIG file properties
foreach mig_file {"mig_b.prj" "mig_a.prj"} {
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$mig_file"]]
    if {[llength $file_obj] > 0} {
        set_property -name "scoped_to_cells" -value "design_1_mig_7series_0_0" -objects $file_obj
    }
}

# Set top module
set_property -name "top" -value "top" -objects [get_filesets sources_1]

# Add constraint files automatically
set xdc_files [glob -nocomplain -directory "$origin_dir/constrs" *.xdc]
foreach xdc_file $xdc_files {
    set normalized_xdc [file normalize $xdc_file]
    add_files -fileset constrs_1 [list $normalized_xdc]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*/[file tail $xdc_file]"]]
    if {[llength $file_obj] > 0} {
        set_property -name "file_type" -value "XDC" -objects $file_obj
    }
}

set_property -name "target_part" -value "${_xil_part_name_}" -objects [get_filesets constrs_1]

# Set simulation properties
set_property -name "top" -value "top" -objects [get_filesets sim_1]
set_property -name "top_lib" -value "xil_defaultlib" -objects [get_filesets sim_1]

# Source block design script
log_info "Sourcing Block Design Tcl script: ${_xil_bd_tcl_script_}"
if {[catch {source ${_xil_bd_tcl_script_}} result]} {
    log_error "Failed to source ${_xil_bd_tcl_script_}: $result"
    exit 1
}

# Locate and configure block design
set bd_file_path "./${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1/bd/${_xil_bd_name_}/${_xil_bd_name_}.bd"

if {![file exists $bd_file_path]} {
    log_error "Block design file not found: $bd_file_path"
    set alt_bd_file_path [get_files -quiet ${_xil_bd_name_}.bd]
    if {$alt_bd_file_path eq ""} {
        log_error "Could not find ${_xil_bd_name_}.bd anywhere"
        exit 1
    }
    log_info "Found BD file at: $alt_bd_file_path"
    set bd_file_path $alt_bd_file_path
}

# Configure block design properties
set_property REGISTERED_WITH_MANAGER "1" [get_files $bd_file_path]
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files $bd_file_path]

# Update compile order and generate targets
update_compile_order -fileset sources_1
reset_target all [get_files $bd_file_path]
export_ip_user_files -of_objects [get_files $bd_file_path] -sync -no_script -force -quiet
delete_ip_run [get_files -of_objects [get_fileset sources_1] $bd_file_path]

# Generate output products for block design
log_info "Generating output products for block design: ${_xil_bd_name_}.bd"
if {[catch {generate_target all [get_files $bd_file_path]} result]} {
    log_error "Failed to generate IP output products for ${_xil_bd_name_}.bd: $result"
} else {
    log_info "Successfully generated IP output products for ${_xil_bd_name_}.bd"
}

# Create wrapper for block design
log_info "Creating wrapper for ${_xil_bd_name_}.bd"
set wrapper_path [make_wrapper -fileset sources_1 -files [get_files $bd_file_path] -top]
add_files -norecurse -fileset sources_1 $wrapper_path

# Configure synthesis run
set idrFlowPropertiesConstraints ""
catch {
    set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
    set_param runs.disableIDRFlowPropertyConstraints 1
}

# Create or configure synthesis run
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part ${_xil_part_name_} -flow {Vivado Synthesis 2021} \
               -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
    set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
    set_property flow "Vivado Synthesis 2021" [get_runs synth_1]
}

# Configure synthesis properties
set synth_run [get_runs synth_1]
set_property set_report_strategy_name 1 $synth_run
set_property report_strategy {Vivado Synthesis Default Reports} $synth_run
set_property set_report_strategy_name 0 $synth_run
set_property -name "part" -value "${_xil_part_name_}" -objects $synth_run
set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $synth_run

# Create or configure implementation run
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part ${_xil_part_name_} -flow {Vivado Implementation 2021} \
               -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} \
               -constrset constrs_1 -parent_run synth_1
} else {
    set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
    set_property flow "Vivado Implementation 2021" [get_runs impl_1]
}

# Configure implementation properties
set impl_run [get_runs impl_1]
set_property set_report_strategy_name 1 $impl_run
set_property report_strategy {Vivado Implementation Default Reports} $impl_run
set_property set_report_strategy_name 0 $impl_run
set_property -name "part" -value "${_xil_part_name_}" -objects $impl_run
set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $impl_run
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $impl_run
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $impl_run

# Set current runs
current_run -synthesis $synth_run
current_run -implementation $impl_run

# Restore IDR flow properties
catch {
    if {$idrFlowPropertiesConstraints ne ""} {
        set_param runs.disableIDRFlowPropertyConstraints $idrFlowPropertiesConstraints
    }
}

log_info "Optimized project creation completed: ${_xil_proj_name_}"
log_info "Project structure improvements:"
log_info "- Organized file addition with grouped file sets"
log_info "- Batch VHDL property configuration"
log_info "- Improved error handling and logging"
log_info "- Modular procedure-based architecture"
log_info "- Performance optimizations for large file sets"