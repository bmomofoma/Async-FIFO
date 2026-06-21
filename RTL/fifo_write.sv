// Tracks the write pointer addresses and evaluates the real-time capacity full status flag.
module fifo_write #(
    parameter int ADDR_WIDTH = 3
)(
    input  logic                  clk_wr,             // Write domain clock
    input  logic                  rst_n,              // Asynchronous active-low reset
    input  logic                  cs,                 // Chip select
    input  logic                  wr_en,              // Write enable from producer
    output logic                  full,               // Fixed: Moved to output port list
    output logic [ADDR_WIDTH-1:0] waddr,              // Address sent to fifo_mem
    output logic [ADDR_WIDTH:0]   write_pointer,      // Gray pointer sent to read domain
    input  logic [ADDR_WIDTH:0]   read_pointer_sync   
);

    logic [ADDR_WIDTH:0] wr_ptr;

    // Pure binary counter for internal tracking
    always_ff @( posedge clk_wr or negedge rst_n ) begin : write_counter
        if (!rst_n) begin
            wr_ptr <= '0;
        end
        else if (wr_en && cs && !full) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Combinational assignments handle the RAM index and Gray conversion automatically
    assign waddr = wr_ptr[ADDR_WIDTH-1:0];
    assign write_pointer = wr_ptr ^ (wr_ptr >> 1);
    assign full = (write_pointer[ADDR_WIDTH]   != read_pointer_sync[ADDR_WIDTH])   && 
                    (write_pointer[ADDR_WIDTH-1] != read_pointer_sync[ADDR_WIDTH-1]) && 
                    (write_pointer[ADDR_WIDTH-2:0] == read_pointer_sync[ADDR_WIDTH-2:0]);
        
endmodule