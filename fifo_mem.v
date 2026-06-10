`timescale 1ns/1ps
// ============================================================
// fifo_mem.v  -  Parameterized Dual-port FIFO Memory
// Supports any depth (power of 2) and any data width
// Write : synchronous on wr_clk posedge
// Read  : asynchronous (combinational)
// ============================================================
module fifo_mem #(
    parameter DATASIZE = 8,
    parameter ADDRSIZE = 4    // depth = 2^ADDRSIZE
)(
    output [DATASIZE-1:0] rd_data,
    input  [DATASIZE-1:0] wr_data,
    input  [ADDRSIZE-1:0] wr_addr,
    input  [ADDRSIZE-1:0] rd_addr,
    input                 wr_en,
    input                 full,
    input                 wr_clk
);
    localparam DEPTH = 1 << ADDRSIZE;
    reg [DATASIZE-1:0] mem [0:DEPTH-1];

    always @(posedge wr_clk)
        if (wr_en && !full)
            mem[wr_addr] <= wr_data;

    assign rd_data = mem[rd_addr];

endmodule