`default_nettype none
`timescale 1ps/1ps

module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
) (
    input   wire wreq, wclk, wrst_n,
    input   wire rreq, rclk, rrst_n,
    input   wire [DSIZE-1:0] wdata,
    output  wire [DSIZE-1:0] rdata,  // Explicit wire declaration
    output  reg wfull,
    output  reg rempty
);

// Internal signals
reg     [ASIZE:0] wq2_rptr, wq1_rptr, rptr;
reg     [ASIZE:0] rq2_wptr, rq1_wptr, wptr;
reg     [ASIZE:0] rbin, wbin;
wire    rempty_val;              // Explicit wire
wire    [ASIZE:0] rptr_nxt;     // Explicit wire
wire    [ASIZE-1:0] raddr;      // Explicit wire
wire    [ASIZE:0] rbin_nxt;     // Explicit wire
wire    [ASIZE-1:0] waddr;      // Explicit wire
wire    [ASIZE:0] wbin_nxt;     // Explicit wire
wire    [ASIZE:0] wptr_nxt;     // Explicit wire
wire    wfull_val;               // Explicit wire

// Synchronize read pointer to write clock domain
always @(posedge wclk or negedge wrst_n) begin
    if(!wrst_n)
        {wq2_rptr, wq1_rptr} <= 0;
    else
        {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
end

// Synchronize write pointer to read clock domain
always @(posedge rclk or negedge rrst_n) begin
    if(!rrst_n)
        {rq2_wptr, rq1_wptr} <= 0;
    else
        {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
end

// Generate rempty condition
assign rempty_val = (rptr_nxt == rq2_wptr);

always @(posedge rclk or negedge rrst_n) begin
    if(!rrst_n)
        rempty <= 1'b1;  // FIFO empty on reset
    else
        rempty <= rempty_val;
end

// Read address & pointer management
assign rbin_nxt = rbin + (rreq & ~rempty);

always @(posedge rclk or negedge rrst_n) 
    if (!rrst_n)
        rbin <= 0;
    else 
        rbin <= rbin_nxt;

assign raddr = rbin[ASIZE-1:0];
assign rptr_nxt = rbin_nxt ^ (rbin_nxt >> 1);  // Binary to Gray

always @(posedge rclk or negedge rrst_n)
    if (!rrst_n)
        rptr <= 0;
    else 
        rptr <= rptr_nxt;

// Write address & pointer management
assign wbin_nxt = wbin + (wreq & !wfull);

always @(posedge wclk or negedge wrst_n)
    if(!wrst_n)
        wbin <= 0;
    else
        wbin <= wbin_nxt;

assign waddr = wbin[ASIZE-1:0];
assign wptr_nxt = wbin_nxt ^ (wbin_nxt >> 1);  // Binary to Gray

always @(posedge wclk or negedge wrst_n)
    if(!wrst_n)
        wptr <= 0;
    else
        wptr <= wptr_nxt;

// Generate wfull condition
assign wfull_val = (wq2_rptr == {~wptr[ASIZE:ASIZE-1], wptr[ASIZE-2:0]});

always @(posedge wclk or negedge wrst_n)
    if (!wrst_n)
        wfull <= 1'b0;
    else 
        wfull <= wfull_val;

// FIFO memory
localparam DEPTH = 1 << ASIZE;
reg [DSIZE-1:0] mem [0:DEPTH-1];

assign rdata = mem[raddr];  // Asynchronous read

always @(posedge wclk)
    if (wreq & !wfull)
        mem[waddr] <= wdata;  // Synchronous write

endmodule
