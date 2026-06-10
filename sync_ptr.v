`timescale 1ns/1ps
// ============================================================
// sync_ptr.v  -  2-Flop Synchronizer for CDC pointer crossing
// Instantiated twice:
//   wptr (wr domain) -> rd_clk -> sync_wptr (rd domain)
//   rptr (rd domain) -> wr_clk -> sync_rptr (wr domain)
// ============================================================
module sync_ptr #(
    parameter ADDRSIZE = 4
)(
    output reg [ADDRSIZE:0] sync_ptr,
    input      [ADDRSIZE:0] ptr_in,
    input                   clk,
    input                   rst_n
);
    reg [ADDRSIZE:0] q1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {sync_ptr, q1} <= 0;
        else
            {sync_ptr, q1} <= {q1, ptr_in};
    end

endmodule