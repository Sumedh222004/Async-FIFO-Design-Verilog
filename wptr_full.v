`timescale 1ns/1ps
module wptr_full #(
    parameter ADDRSIZE           = 4,
    parameter ALMOST_FULL_THRESH = 2
)(
    output reg              full,
    output reg              almost_full,
    output [ADDRSIZE-1:0]   wr_addr,
    output reg [ADDRSIZE:0] wptr,
    output [ADDRSIZE:0]     wr_fill_count,
    input  [ADDRSIZE:0]     sync_rptr,
    input                   wr_en,
    input                   wr_clk,
    input                   wr_rst_n
);
    localparam DEPTH = 1 << ADDRSIZE;
    reg  [ADDRSIZE:0] wbin;
    wire [ADDRSIZE:0] wbin_next  = wbin + (wr_en & ~full);
    wire [ADDRSIZE:0] wgray_next = wbin_next ^ (wbin_next >> 1);

    assign wr_addr = wbin[ADDRSIZE-1:0];

    always @(posedge wr_clk or negedge wr_rst_n)
        if (!wr_rst_n) {wbin, wptr} <= 0;
        else           {wbin, wptr} <= {wbin_next, wgray_next};

    // FULL: standard Gray-code comparison
    wire wfull_val = (wgray_next == {~sync_rptr[ADDRSIZE:ADDRSIZE-1],
                                      sync_rptr[ADDRSIZE-2:0]});
    always @(posedge wr_clk or negedge wr_rst_n)
        if (!wr_rst_n) full <= 0;
        else           full <= wfull_val;

    // Gray -> Binary for sync_rptr (to compute fill count)
    wire [ADDRSIZE:0] sync_rbin;
    genvar g;
    generate for (g=ADDRSIZE; g>=0; g=g-1) begin : g2b
        if (g==ADDRSIZE) assign sync_rbin[g] = sync_rptr[g];
        else             assign sync_rbin[g] = sync_rbin[g+1] ^ sync_rptr[g];
    end endgenerate

    // Fill count = write pointer - read pointer (wraps correctly in binary)
    wire [ADDRSIZE:0] fill_w = wbin - sync_rbin;
    assign wr_fill_count = fill_w;

    // ALMOST_FULL: (DEPTH - fill) <= threshold, only when not full
    wire [ADDRSIZE:0] free_w = DEPTH - fill_w;
    always @(posedge wr_clk or negedge wr_rst_n)
        if (!wr_rst_n) almost_full <= 0;
        else           almost_full <= (~wfull_val) && (free_w <= ALMOST_FULL_THRESH);

endmodule