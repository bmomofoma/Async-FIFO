// Top-level structural wrapper that wires up the memory core, tracking engines, and cross-domain synchronizers.
module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 8
)(
    input  logic                    clk_wr,   // Write domain clock
    input  logic                    clk_rd,   // Read domain clock
    input  logic                    rst_n,    // Asynchronous active-low reset
    input  logic                    cs,       // Chip select
    input  logic                    wr_en,    // Write enable strobe
    input  logic                    rd_en,    // Read enable strobe
    input  logic [DATA_WIDTH-1:0]   data_in,  // Parallel incoming write data
    output logic [DATA_WIDTH-1:0]   data_out, // Parallel outgoing read data
    output logic                    full,     // Full capacity status flag
    output logic                    empty     // Empty capacity status flag
);

    // 1. Calculate ADDR_WIDTH dynamically using $clog2(FIFO_DEPTH)
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // 2. Internal interconnect wires
    logic [ADDR_WIDTH-1:0] waddr;
    logic [ADDR_WIDTH-1:0] raddr;
    logic [ADDR_WIDTH:0]   write_pointer;      // Gray pointer from write_engine
    logic [ADDR_WIDTH:0]   read_pointer;       // Gray pointer from read_engine
    logic [ADDR_WIDTH:0]   write_pointer_sync; // Synchronized write pointer in rd domain
    logic [ADDR_WIDTH:0]   read_pointer_sync;  // Synchronized read pointer in wr domain

    // 3. Instantiate Dual-Port Memory Array Core
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_core (
        .clk_wr(clk_wr),
        .cs(cs),
        .wr_en(wr_en),
        .full(full),
        .waddr(waddr),
        .data_in(data_in),
        .raddr(raddr),
        .data_out(data_out)
    );

    // 4. Instantiate Write Domain Control Engine
    fifo_write #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_engine (
        .clk_wr(clk_wr),
        .rst_n(rst_n),
        .cs(cs),
        .wr_en(wr_en),
        .full(full),
        .waddr(waddr),
        .write_pointer(write_pointer),
        .read_pointer_sync(read_pointer_sync) 
    );

    // 5. Instantiate Read Domain Control Engine
    fifo_read #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_engine (
        .clk_rd(clk_rd),
        .rst_n(rst_n),
        .cs(cs),
        .rd_en(rd_en),
        .empty(empty),
        .raddr(raddr),
        .read_pointer(read_pointer),
        .write_pointer_sync(write_pointer_sync) 
    );

    // 6. Synchronize Write Pointer over to the Read Clock Domain
    sync_ptr #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_to_read_sync (
        .dest_clk(clk_rd),
        .rst_n(rst_n),
        .ptr_in(write_pointer),
        .ptr_out(write_pointer_sync)
    );

    // 7. Synchronize Read Pointer over to the Write Clock Domain
    sync_ptr #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_to_write_sync (
        .dest_clk(clk_wr),
        .rst_n(rst_n),
        .ptr_in(read_pointer),
        .ptr_out(read_pointer_sync)
    );

endmodule