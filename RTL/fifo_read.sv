// Tracks the read pointer addresses and evaluates the real-time capacity empty status flag.
module fifo_read #(
    parameter int ADDR_WIDTH = 3
)(
    input  logic                  clk_rd,             // Read domain clock
    input  logic                  rst_n,              // Asynchronous active-low reset
    input  logic                  cs,                 // Chip select
    input  logic                  rd_en,              // Read enable from consumer
    output logic                  empty,              // Status flag to consumer
    output logic [ADDR_WIDTH-1:0] raddr,              // Address sent to fifo_mem
    output logic [ADDR_WIDTH:0]   read_pointer,       // Gray pointer sent to write domain
    input  logic [ADDR_WIDTH:0]   write_pointer_sync  
);

    logic [ADDR_WIDTH:0] rd_ptr;

    // Read pointer logic
    always_ff @( posedge clk_rd or negedge rst_n ) begin : read_counter
        if(!rst_n) begin
            rd_ptr <= '0;
        end
        else if (rd_en && cs && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    assign raddr = rd_ptr[ADDR_WIDTH-1:0];
    assign read_pointer = rd_ptr ^ (rd_ptr >> 1);
    
    // Empty occurs when the local Gray read pointer matches the synchronized Gray write pointer
    assign empty = (read_pointer == write_pointer_sync);

endmodule