// Parameterized dual-port RAM array allowing simultaneous, independent read and write operations.
module fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 8,
    parameter int ADDR_WIDTH = 3
)(
    input  logic                    clk_wr,
    input  logic                    cs,
    input  logic                    wr_en,
    input  logic                    full,
    input  logic [ADDR_WIDTH-1:0]   waddr,
    input  logic [DATA_WIDTH-1:0]   data_in,
    
    input  logic [ADDR_WIDTH-1:0]   raddr,
    output logic [DATA_WIDTH-1:0]   data_out
);

    // 2-dimensional memory array
    logic [DATA_WIDTH - 1:0] mem [FIFO_DEPTH - 1:0];

    // Clocked write
    always_ff @( posedge clk_wr ) begin 
            if (cs && wr_en && !full) begin
                mem[waddr] <= data_in;
            end
    end

    // combinational read - Countinously drives out data to read port to prevent clock cycle delay
    assign data_out = mem[raddr];


endmodule
