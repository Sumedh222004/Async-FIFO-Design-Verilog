`timescale 1ns/1ps
module rptr_empty #(
    parameter ADDRSIZE            = 4,
    parameter ALMOST_EMPTY_THRESH = 2
)(
    output reg              empty,
    output reg              almost_empty,
    output [ADDRSIZE-1:0]   rd_addr,
    output reg [ADDRSIZE:0] rptr,
    output [ADDRSIZE:0]     rd_fill_count,
    input  [ADDRSIZE:0]     sync_wptr,
    input                   rd_en,
    input                   rd_clk,
    input                   rd_rst_n
);
    reg  [ADDRSIZE:0] rbin;
    wire [ADDRSIZE:0] rbin_next  = rbin + (rd_en & ~empty);
    wire [ADDRSIZE:0] rgray_next = rbin_next ^ (rbin_next >> 1);

    assign rd_addr = rbin[ADDRSIZE-1:0];

    always @(posedge rd_clk or negedge rd_rst_n)
        if (!rd_rst_n) {rbin, rptr} <= 0;
        else           {rbin, rptr} <= {rbin_next, rgray_next};

    wire rempty_val = (rgray_next == sync_wptr);
    always @(posedge rd_clk or negedge rd_rst_n)
        if (!rd_rst_n) empty <= 1;
        else           empty <= rempty_val;

    // Gray -> Binary for sync_wptr
    wire [ADDRSIZE:0] sync_wbin;
    genvar g;
    generate for (g=ADDRSIZE; g>=0; g=g-1) begin : g2b
        if (g==ADDRSIZE) assign sync_wbin[g] = sync_wptr[g];
        else             assign sync_wbin[g] = sync_wbin[g+1] ^ sync_wptr[g];
    end endgenerate

    // Fill count = write pointer - read pointer
    wire [ADDRSIZE:0] fill_r = sync_wbin - rbin;
    assign rd_fill_count = fill_r;

    // ALMOST_EMPTY: fill <= threshold
    always @(posedge rd_clk or negedge rd_rst_n)
        if (!rd_rst_n) almost_empty <= 1;
        else           almost_empty <= (fill_r <= ALMOST_EMPTY_THRESH);

endmodule