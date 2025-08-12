# ========================< 清空软件残留信息 >==============================

#1.exit modelsim simulation
quit -sim

#2.clear messages
# .main clear

#3.delete the existing work dir
if [file exists work] {vdel -all}

# =========================< 建立工程并仿真 >===============================

#4.建立新的工程库
vlib work

#5.映射逻辑库到物理目录
vmap work work

set ROOT ../../../../../
# set GHE ../../../../AlgorithmModule/ghe_v4
# set LWDR ../../../../AlgorithmModule/lwdr
# set IDE ../../../../AlgorithmModule/ide
# set IDE_PATH $IDE/rtl
# set RTL_PATH $GHE/rtl
# set SIM_PATH $GHE/sim
set COMMAN_PATH $ROOT/BasicModule/Efinity_basic_lib/common
set BASIC_MODULE_PATH $ROOT/BasicModule/Efinity_basic_lib/basic_module
set MEMORY_PATH $ROOT/BasicModule/Efinity_basic_lib/memory
set IP_PATH $ROOT/BasicModule/Efinity_basic_lib/ip
set MATH_PATH $IP_PATH/../../guideir_ptic
set FILTER_PATH $ROOT/BasicModule/image_filter
set GUIDEIR $ROOT/BasicModule/guideir_ptic
# C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\BasicModule\guideir_ptic\divider_shift

#6.编译仿真文件
vlog -work work ./tb.v
vlog -work work ./frame_buffer/*.v
vlog -work work ./save_image.v
vlog -work work ../../rtl/debug/image_to_ddr.v
vlog -work work ../../rtl/debug/ddr_to_logic.v
vlog -work work ../../rtl/debug/gen_axi_reset.v
vlog -work work ../../rtl/video_fdma.v
vlog -work work ../../rtl/uiFDMA.v
# vlog -work work $IP_PATH/ram/dcfifo/Source/DC_FIFO.v
# vlog -work work $IP_PATH/axi/axi_interconnect_v1.0(release)/rtl/axi_interconnect.v
# vlog -work work $IP_PATH/axi/axi_interconnect_v1.0(release)/sim/tb/axi_ram_v1.0/axi_ram.v
# \ip\axi\axi_interconnect_v1.0(release)\sim\tb\axi_ram_v1.0\axi_ram.v
# vlog -work work $GHE/rtl/ghe_top.v
# vlog -work work $GHE/rtl/parameter_sync.v
# vlog -work work $GHE/rtl/tone_pretreatment/cal_image_mean.v
# vlog -work work $GHE/rtl/tone_pretreatment/pre_process_top.v
# vlog -work work $GHE/rtl/tone_pretreatment/smooth_offset.v
# vlog -work work $GHE/rtl/tone_pretreatment/parameter_smooth.v

# vlog -work work $GHE/rtl/all_hist/cal_lut_gray.v
# vlog -work work $GHE/rtl/all_hist/ghe_core.v
# vlog -work work $GHE/rtl/all_hist/ghe_hist.v
# vlog -work work $GHE/rtl/all_hist/update_th.v
# vlog -work work $GHE/rtl/all_hist/ghe_mapping.v
# vlog -work work $GHE/rtl/all_hist/hist_cal_control.v
# vlog -work work $GHE/rtl/all_hist/hist_core.v
# vcom -work work $GHE/rtl/all_hist/sram_hist_8192x19.vhd
# vlog -work work $GHE/rtl/all_hist/tone.v

# vlog -work work $GHE/rtl/gamma_correct/gamma_correction.v
# vlog -work work $GHE/rtl/bc_adjust/bright_contrast_adjust.v

# vlog -work work $GHE/rtl/heltm/ltm_hist.v
# vlog -work work $GHE/rtl/heltm/ltm_hist_core.v
# vlog -work work $GHE/rtl/heltm/block_cal_lut_gray.v
# vlog -work work $GHE/rtl/heltm/block_hist_cal_control.v
# vlog -work work $GHE/rtl/heltm/block_hist_core.v
# vlog -work work $GHE/rtl/heltm/block_hist_move.v
# vlog -work work $GHE/rtl/heltm/cal_maxmin.v
# vlog -work work $GHE/rtl/heltm/heltm_top.v
# # vlog -work work $GHE/rtl/heltm/image_statistics.v
# vlog -work work $GHE/rtl/heltm/final_lut_process.v
# vlog -work work $GHE/rtl/heltm/clahe_nearby.v
# vlog -work work $GHE/rtl/heltm/ltm_out_smooth.v

# vlog -work work $GHE/rtl/debug/debug.v
# vlog -work work $GHE/rtl/debug/ddr_to_logic.v
# vlog -work work $GHE/rtl/debug/gen_axi_reset.v
# vlog -work work $GHE/rtl/debug/image_to_ddr.v

# vlog -work work $GHE/rtl/ide/ide_restoration.v
# vlog -work work $GHE/rtl/ide/ide_separation.v
# vlog -work work $GHE/rtl/ide/delt_gauss_detail.v
# vlog -work work $GHE/rtl/ide/comput_var.v
# vlog -work work $GHE/rtl/ide/cal_weigh.v
# vlog -work work $GHE/rtl/ide/gray_filter.v
# vlog -work work $GHE/rtl/ide/single_port_rom.v
# vlog -work work $GHE/rtl/ide/restore_core.v
# vlog -work work $GHE/rtl/ide/sobel_var.v

# vlog -work work $LWDR/lwdr_top.v
# vlog -work work $LWDR/image_fusion.v
# vlog -work work $LWDR/fusion_ratio_coef.v
# vlog -work work $LWDR/nonlinear_map/*.v

vlog -work work $GUIDEIR/divider_shift/divider_shift.v
vlog -work work $GUIDEIR/fix_div/fix_div.v
vlog -work work $GUIDEIR/capture_edge/capture_edge.v

vcom -work work $BASIC_MODULE_PATH/line1toN/data_avl_delay.vhd
vcom -work work $BASIC_MODULE_PATH/ip_rtl/lpm_dual_clk_port_ram.vhd
vcom -work work $BASIC_MODULE_PATH/divisor_fix2_top.vhd
vcom -work work $BASIC_MODULE_PATH/divisor_fix2.vhd
vcom -work work $BASIC_MODULE_PATH/ip_rtl/multi_mxn.vhd
# vlog -work work $GHE/../tv_correction/rtl/scene_compensation/win_nxn.v
vlog -work work $GUIDEIR/sqrt/sqrt_pipelined.v
vlog -work work $GUIDEIR/divider/divider_wrapper.v
vlog -work work $GUIDEIR/divider/divider_guideir.v
vlog -work work $COMMAN_PATH/signal_delay.v
# vcom -work work $IDE_PATH/auto_agc/mix_auto_agc.vhd
# vcom -work work $IDE_PATH/auto_agc/mix_cal.vhd
# vcom -work work $IDE_PATH/auto_agc/plat_hist.vhd
# vcom -work work $IDE_PATH/auto_agc/plat_map.vhd
# vcom -work work $IDE_PATH/auto_agc/y16_range_change.vhd
# vcom -work work $IDE_PATH/auto_agc/y16toy8.vhd
# vcom -work work $IDE_PATH/auto_agc/bright_contrast.vhd
# vcom -work work $IDE_PATH/auto_agc/div2avl_ide.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/line_1toN.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/column1toN.vhd
vcom -work work $BASIC_MODULE_PATH/parallel_adder.vhd
vcom -work work $BASIC_MODULE_PATH/ip_rtl/multi_mxn.vhd
vcom -work work $BASIC_MODULE_PATH/ip_rtl/div_m_n.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/image_counter.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/parametered_mux.vhd
vcom -work work $BASIC_MODULE_PATH/ctl_signals_sync.vhd
vcom -work work $BASIC_MODULE_PATH/avl_gen.vhd
vlog -work work $BASIC_MODULE_PATH/gen_field_rst.v
vlog -work work $IP_PATH/efx_multiplier/parallel_ppl_mult_v1.20.v
vlog -work work $IP_PATH/ram/true_dual_port_ram/true_dual_port_ram.v
vlog -work work $IP_PATH/ram/dcfifo/Source/DC_FIFO.v
vlog -work work $IP_PATH/efx_divider/efx_divider.v
# vcom -work work $FILTER_PATH/gass_filter/gauss_filter.vhd
# vcom -work work $FILTER_PATH/gass_filter/ide_guass_auto.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/line_1toN.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/column1toN.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/data_avl_delay.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/image_counter.vhd
vcom -work work $BASIC_MODULE_PATH/line1toN/parametered_mux.vhd
vlog -work work $IP_PATH/efx_multiplier/parallel_ppl_mult_v1.20.v
vcom -work work $BASIC_MODULE_PATH/ip_rtl/lpm_dual_clk_port_ram.vhd
# vlog -work work $BASIC_MODULE_PATH/gen_field_rst.v
vlog -work work $IP_PATH/ram/true_dual_port_ram/true_dual_port_ram.v

#7.start simulation
vsim -t ns -voptargs=+acc work.tb

# =====================< 状态机名称,不用请删除 >=============================

# 结构体设置
# virtual type {
# 		{ 8'd0 IDLE }
# 		{ 8'd1 ST_STAGE0}
# 		{ 8'd2 ST_STAGE1}
# 		{ 8'd3 ST_STAGE2}
# 		{ 8'd4 ST_STAGE3}
# 		{ 8'd5 ST_STAGE4}
# 		{ 8'd6 ST_STAGE5}
# 		{ 8'd7 ST_STAGE6}
# 	} state_type1;
# virtual function {(state_type1)/tb/pre_process_top_inst/pre_get_hist_inst/hist_cal_control_inst/state_c} fsm_state
# add wave -color pink /tb/pre_process_top_inst/pre_get_hist_inst/hist_cal_control_inst/fsm_state


# ============================< 加载波形 >=================================
# 8.toggle leaf names
# write format wave wave.do
# do wave.do

config wave -signalnamewidth 1

#9.add waves
add wave -divider "tb"
add wave -group tb                          -radix unsigned tb/*
add wave -divider "top"
add wave -group tb                          -radix unsigned tb/u_axi_ram/*
add wave -group axi_interconnect            -radix unsigned tb/u_axi_interconnect/*
add wave -group image0_to_ddr               -radix unsigned tb/image0_to_ddr_inst/*
add wave -group video0_fdma                 -radix unsigned tb/video0_fdma_inst/*
# add wave -group gen_rst                 -radix unsigned tb/video0_fdma_inst/u_gen_rst/*
add wave -group uiFDMA0                 -radix unsigned tb/video0_fdma_inst/uiFDMA_inst/*
# add wave -group dvp_rd_data_fifo                 -radix unsigned tb/video0_fdma_inst/dvp_rd_data_fifo/*
# add wave -group video1_fdma                 -radix unsigned tb/video1_fdma_inst/*
# add wave -group uiFDMA1                 -radix unsigned tb/video1_fdma_inst/uiFDMA_inst/*
#9.run

# ghe tone
# run 72ms

# heltm-直方图
# run 86ms

# heltm-y8
# run 144ms

# ide-re
run 80ms

# use para sync-ide-re
# run 144ms

# temp
# run 71ms