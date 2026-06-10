`timescale 1ns/1ps
// ============================================================
// async_fifo_top.v  -  Enhanced Parameterized Async FIFO v2
//
// Parameters:
//   DATASIZE          : data width          (default 8)
//   ADDRSIZE          : address bits        (default 4 -> depth 16)
//   ALMOST_FULL_THRESH : almost_full threshold  (default 2)
//   ALMOST_EMPTY_THRESH: almost_empty threshold (default 2)
//
// New ports vs v1:
//   almost_full   : asserts when free slots <= ALMOST_FULL_THRESH
//   almost_empty  : asserts when fill level <= ALMOST_EMPTY_THRESH
//   wr_fill_count : real-time fill level (write domain)
//   rd_fill_count : real-time fill level (read domain)
// ============================================================
module async_fifo_top #(
    parameter DATASIZE           = 8,
    parameter ADDRSIZE           = 4,
    parameter ALMOST_FULL_THRESH  = 2,
    parameter ALMOST_EMPTY_THRESH = 2
)(
    // Write domain
    input                   wr_clk,
    input                   wr_rst_n,
    input                   wr_en,
    input  [DATASIZE-1:0]   wr_data,
    output                  full,
    output                  almost_full,
    output [ADDRSIZE:0]     wr_fill_count,

    // Read domain
    input                   rd_clk,
    input                   rd_rst_n,
    input                   rd_en,
    output [DATASIZE-1:0]   rd_data,
    output                  empty,
    output                  almost_empty,
    output [ADDRSIZE:0]     rd_fill_count
);
    wire [ADDRSIZE-1:0] wr_addr, rd_addr;
    wire [ADDRSIZE:0]   wptr, rptr;
    wire [ADDRSIZE:0]   sync_wptr, sync_rptr;

    // 1. FIFO Memory
    fifo_mem #(DATASIZE, ADDRSIZE) u_fifo_mem (
        .rd_data (rd_data),
        .wr_data (wr_data),
        .wr_addr (wr_addr),
        .rd_addr (rd_addr),
        .wr_en   (wr_en),
        .full    (full),
        .wr_clk  (wr_clk)
    );

    // 2. Write pointer + FULL + ALMOST_FULL
    wptr_full #(ADDRSIZE, ALMOST_FULL_THRESH) u_wptr_full (
        .full          (full),
        .almost_full   (almost_full),
        .wr_addr       (wr_addr),
        .wptr          (wptr),
        .wr_fill_count (wr_fill_count),
        .sync_rptr     (sync_rptr),
        .wr_en         (wr_en),
        .wr_clk        (wr_clk),
        .wr_rst_n      (wr_rst_n)
    );

    // 3. Read pointer + EMPTY + ALMOST_EMPTY
    rptr_empty #(ADDRSIZE, ALMOST_EMPTY_THRESH) u_rptr_empty (
        .empty         (empty),
        .almost_empty  (almost_empty),
        .rd_addr       (rd_addr),
        .rptr          (rptr),
        .rd_fill_count (rd_fill_count),
        .sync_wptr     (sync_wptr),
        .rd_en         (rd_en),
        .rd_clk        (rd_clk),
        .rd_rst_n      (rd_rst_n)
    );

    // 4. Sync: wptr -> rd domain
    sync_ptr #(ADDRSIZE) u_sync_wptr (
        .sync_ptr (sync_wptr),
        .ptr_in   (wptr),
        .clk      (rd_clk),
        .rst_n    (rd_rst_n)
    );

    // 5. Sync: rptr -> wr domain
    sync_ptr #(ADDRSIZE) u_sync_rptr (
        .sync_ptr (sync_rptr),
        .ptr_in   (rptr),
        .clk      (wr_clk),
        .rst_n    (wr_rst_n)
    );

endmodule