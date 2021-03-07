
#vcom /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src/unimacro/BRAM_SINGLE_MACRO.vhd
vlib unisim
vcom -work unisim /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src/unisims/unisim_VCOMP.vhd
vcom -work unisim /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src/unisims/unisim_VPKG.vhd
vcom -work unisim /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src/unisims/primitive/RAMB16_S1.vhd
vlib unimacro
vcom -work unimacro /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src/unimacro/unimacro_VCOMP.vhd
vlib work
vcom  -suppress 1339 -O1 -2008 src/top.vhdl src/dpram.vhdl src/charcopy.vhdl src/fontrom.vhdl \
	src/vga.vhdl sim/test.vhdl sim/package_timing.vhd \
	sim/package_utility.vhd sim/async_1Mx16.vhd src/charmap.vhdl src/linedraw.vhdl src/testrom.vhdl



vsim work.top_tb
#add wave -radix hex -r /top_tb/uut/*
add wave -radix hex -r /top_tb/uut/read_data_s
add wave -radix hex -r /top_tb/uut/read_addr_s
add wave -group cpu -radix hex -r /top_tb/uut/curx_s
add wave -group cpu -radix hex -r /top_tb/uut/cury_s
add wave -group cpu -radix hex -r /top_tb/uut/render/state
add wave -group cpu -radix hex -r /top_tb/uut/render_we_s
add wave -group cpu -radix hex -r /top_tb/uut/render_write_data_s
add wave -group cpu -radix hex -r /top_tb/uut/dpaddr
add wave -group cpu -radix hex -r /top_tb/uut/rambank0_active_s
add wave -group linedraw -radix hex -r /top_tb/uut/linedrawi/*
add wave -group linedraw -radix hex -r /top_tb/uut/linedrawi/draw/*
add wave -group charcopy -radix hex -r /top_tb/uut/charcopyi/*
add wave -group vga -radix hex -r /top_tb/uut/vgai/*
add wave -group sram -radix hex -r /top_tb/uut/sram_oe
add wave -group sram -radix hex -r /top_tb/uut/sram_we
add wave -group sram -radix hex -r /top_tb/uut/sram_addr
add wave -group sram -radix hex -r /top_tb/uut/sram_data
#add wave -group vga -r /top_tb/uut/vgai/*
#add wave -group linedraw -radix hex -r /top_tb/uut/render/visible
#add wave -group charcopy -radix hex -r /top_tb/uut/charcopyi/copy/state
#add wave -group charcopy -radix hex -r /top_tb/uut/charcopyi/copy/ramdata
#add wave -group charcopy -radix ascii -r /top_tb/uut/charcopyi/char_i
run 120ms

mem save -o mem0.mem -f mti -data hex -addr hex -wordsperline 640 /top_tb/sram/line__100/mem_array