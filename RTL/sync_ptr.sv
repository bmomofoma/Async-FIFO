// Reusable 2-stage flip-flop synchronizer to safely pass a Gray pointer across a clock boundary.
module sync_ptr #(
    parameter int ADDR_WIDTH = 3
)(
    input  logic                  dest_clk,     // Destination domain clock (the domain we are jumping into)
    input  logic                  rst_n,        // Asynchronous active-low reset
    input  logic [ADDR_WIDTH:0]   ptr_in,       // Incoming Gray pointer from the source clock domain
    output logic [ADDR_WIDTH:0]   ptr_out       // Fully synchronized Gray pointer safe for flag checks
);

    logic [ADDR_WIDTH:0] sync_reg0;
    logic [ADDR_WIDTH:0] sync_reg1;

    always_ff @( posedge dest_clk or negedge rst_n ) begin : sync_ptr_block
        if (!rst_n) begin
            sync_reg0 <= '0;
            sync_reg1 <= '0;
        end
        else begin
            sync_reg0 <= ptr_in;    // samples raw input
            sync_reg1 <= sync_reg0; // filters out metastability
        end
    end

    // Continuous assignments belong outside procedural block boundaries
    assign ptr_out = sync_reg1;

endmodule