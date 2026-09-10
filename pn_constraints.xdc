#=================================================================================

#Xilinx Design Constraints (XDC) File for the Real Digital "Boolean Board"

#Target Device: xc7s50csga324

#=================================================================================

#Clock Signal - Connected to the board's 100MHz oscillator

set_property PACKAGE_PIN L16 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]
#This line can give error, but I didn't get it, still bitstream can be generated 

#Reset Signal - Connected to the Center Pushbutton (BTNC)

set_property PACKAGE_PIN R12 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

#Output Signal - Connected to the first user LED (LED0)

set_property PACKAGE_PIN P14 [get_ports pn_out]
set_property IOSTANDARD LVCMOS33 [get_ports pn_out]
