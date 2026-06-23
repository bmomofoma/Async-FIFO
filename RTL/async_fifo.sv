// Top-level structural wrapper that wires up the memory core, tracking engines, and cross-domain synchronizers.
module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 8
)(
    input  logic                    clk_wr,  
    input  logic                    clk_rd,   
    input  logic                    rst_n,    
    input  logic                    cs,       
    input  logic                    wr_en,    
    input  logic                    rd_en,    
    input  logic [DATA_WIDTH-1:0]   data_in,  
    output logic [DATA_WIDTH-1:0]   data_out,
    output logic                    full,  
    output logic                    empty   
);

    // Calculate ADDR_WIDTH dynamically using $clog2(FIFO_DEPTH)
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);
    logic [ADDR_WIDTH-1:0] waddr;
    logic [ADDR_WIDTH-1:0] raddr;
    logic [ADDR_WIDTH:0]   write_pointer;      
    logic [ADDR_WIDTH:0]   read_pointer;     
    logic [ADDR_WIDTH:0]   write_pointer_sync; 
    logic [ADDR_WIDTH:0]   read_pointer_sync;  

    // Instantiate Dual-Port Memory Array Core
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

    // Instantiate Write Domain Control Engine
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

    // Instantiate Read Domain Control Engine
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

    // Synchronize Write Pointer over to the Read Clock Domain
    sync_ptr #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_to_read_sync (
        .dest_clk(clk_rd),
        .rst_n(rst_n),
        .ptr_in(write_pointer),
        .ptr_out(write_pointer_sync)
    );

    // Synchronize Read Pointer over to the Write Clock Domain
    sync_ptr #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_to_write_sync (
        .dest_clk(clk_wr),
        .rst_n(rst_n),
        .ptr_in(read_pointer),
        .ptr_out(read_pointer_sync)
    );

endmodule
