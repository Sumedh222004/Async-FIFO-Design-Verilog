# ==============================================================
# async_fifo.xdc - Vivado Constraints for Async FIFO
# Target: Artix-7 xc7a35tcpg236-1
# ==============================================================

create_clock -period 100.000 -name wr_clk [get_ports wr_clk]
create_clock -period 20.000 -name rd_clk [get_ports rd_clk]

set_clock_groups -asynchronous -group [get_clocks wr_clk] -group [get_clocks rd_clk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets rd_clk_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets wr_clk_IBUF]

set_input_delay -clock wr_clk -max 5.000 [get_ports {{wr_data[*]} wr_en wr_rst_n}]
set_input_delay -clock wr_clk -min 1.000 [get_ports {{wr_data[*]} wr_en wr_rst_n}]
set_input_delay -clock rd_clk -max 2.000 [get_ports {rd_en rd_rst_n}]
set_input_delay -clock rd_clk -min 0.500 [get_ports {rd_en rd_rst_n}]
set_output_delay -clock wr_clk -max 5.000 [get_ports full]
set_output_delay -clock rd_clk -max 2.000 [get_ports {{rd_data[*]} empty}]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
