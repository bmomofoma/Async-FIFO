`timescale 1ns / 1ps

module async_fifo_tb;

    // Testbench Parameters
    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 8;

    // Clock Periods (100MHz write, 40MHz read)
    localparam time CLK_WR_PERIOD = 10ns; 
    localparam time CLK_RD_PERIOD = 25ns; 

    logic                    clk_wr;
    logic                    clk_rd;
    logic                    rst_n;
    logic                    cs;
    logic                    wr_en;
    logic                    rd_en;
    logic [DATA_WIDTH-1:0]   data_in;
    logic [DATA_WIDTH-1:0]   data_out;
    logic                    full;
    logic                    empty;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo (
        .clk_wr(clk_wr),
        .clk_rd(clk_rd),
        .rst_n(rst_n),
        .cs(cs),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Write Clock Generator Engine (100 MHz)
    initial begin
        clk_wr = 1'b0;
        forever #(CLK_WR_PERIOD / 2) clk_wr = ~clk_wr;
    end

    // Read Clock Generator Engine (40 MHz)
    initial begin
        clk_rd = 1'b0;
        forever #(CLK_RD_PERIOD / 2) clk_rd = ~clk_rd;
    end

    // TESTBENCH STIMULUS GENERATOR
    initial begin
        rst_n   = 1'b0; // Active-low reset starts asserted
        cs      = 1'b1; // Keep chip selected
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        data_in = '0;

        #(CLK_WR_PERIOD * 4);
        rst_n = 1'b1;        
        #(CLK_WR_PERIOD * 2); 

        @(posedge clk_wr);
        
        wr_en   <= 1'b1;
        data_in <= 8'h3C;

        @(posedge clk_wr);

        wr_en   <= 1'b0;
        data_in <= 8'h00; 
        
        wr_en   <= 1'b0;
        data_in <= 8'h00; 

        while (empty == 1'b1) begin
            @(posedge clk_rd);
        end
        rd_en <= 1'b1;

        @(posedge clk_rd);

        rd_en <= 1'b0;

        #(CLK_RD_PERIOD * 5);
        $display("Simulation successfully completed!");
        $finish;
    end

    // Create a VCD dump file so you can open up the waveforms in GTKWave
    initial begin
        $dumpfile("async_fifo_wave.vcd");
        $dumpvars(0, async_fifo_tb);
    end

endmodule
