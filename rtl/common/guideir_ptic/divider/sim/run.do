# ========================< 清空软件残留信息 >==============================

#1.exit modelsim simulation
quit -sim

#2.clear messages
.main clear

#3.delete the existing work dir
if [file exists work] {vdel -all}

# =========================< 建立工程并仿真 >===============================

#4.建立新的工程库
vlib work

#5.映射逻辑库到物理目录
vmap work work

set ROOT ../../
set IDE_PATH $ROOT/../ide/rtl
set NUC_PATH $ROOT/../tv_correction/rtl
set RTL_PATH $ROOT/rtl
set FILTER_PATH $ROOT/../../BasicModule/image_filter
set IP_PATH $ROOT/../../BasicModule/Efinity_basic_lib/ip
set MATH_PATH $IP_PATH/../../math_lib
set COMMAN_PATH $ROOT/../../BasicModule/Efinity_basic_lib/common
set BASIC_MODULE_PATH $ROOT/../../BasicModule/Efinity_basic_lib/basic_module
set MEMORY_PATH $ROOT/../../BasicModule/Efinity_basic_lib/memory

#6.编译仿真文件
vlog -work work ./tb_simple.v
vlog -work work ../divider_wrapper.v
vlog -work work ../divider_guideir.v
# vlog -work work ../Goldschmidt_Integer_Divider_Parallel_FF.v
# vlog -work work ../../Efinity_basic_lib/ip/efx_multiplier/parallel_ppl_mult_v1.20.v

#7.start simulation
vsim -t ns -voptargs=+acc work.tb_simple

# =====================< 状态机名称,不用请删除 >=============================

# 结构体设置
# virtual type { 
# 		{ 4'd0 S0 } 
# 		{ 4'd1 S1}
# 		{ 4'd2 S2}
# 		{ 4'd3 S3}
# 		{ 4'd4 S4}
# 		{ 4'd5 S5}
# 		{ 4'd6 S6}
# 		{ 4'd7 S7}
# 		{ 4'd8 S8}
# 		{ 4'd9 S9}
# 		{ 4'd10 S10}
# 	} state_type1;
# virtual function {(state_type1)/tb_simple/divide_Newton_inst/state} fsm_state2
# add wave -color pink /tb_simple/divide_Newton_inst/fsm_state2
# ============================< 加载波形 >=================================
# 8.toggle leaf names
config wave -signalnamewidth 1

#9.add waves
add wave -divider "top"
add wave -group tb        	 -radix unsigned tb_simple/*
add wave -group dut      -radix unsigned tb_simple/divider_wrapper_inst/*
add wave -group dut2      -radix unsigned tb_simple/divider_wrapper2_inst/*

#9.run
# run 11ms
run 32us
# run 12000us