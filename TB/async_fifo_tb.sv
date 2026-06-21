`timescale 1ns / 1ps

module async_fifo_tb;

    // Testbench Parameters
    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 8;

    // Clock Periods (100MHz write, 40MHz read)
    localparam time CLK_WR_PERIOD = 10ns; 
    localparam time CLK_RD_PERIOD = 25ns; 

    // Interface Interconnect Wires
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

    // Instantiate the async FIFO block
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
        // 1. Initialize all input control signals to a safe starting state
        rst_n   = 1'b0; // Active-low reset starts asserted
        cs      = 1'b1; // Keep chip selected
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        data_in = '0;

        // 2. Hold reset active for a few cycles, then release it
        #(CLK_WR_PERIOD * 4);
        rst_n = 1'b1;         // Release reset
        #(CLK_WR_PERIOD * 2); // Wait for the system to settle

        // --- WRITING DATA_IN (0x3C) ---
        
        // Step 1: Wait for a clean rising edge of the write clock
        @(posedge clk_wr);
        
        // Step 2: Assert your data and enable using non-blocking assignments (<=)
        wr_en   <= 1'b1;
        data_in <= 8'h3C;

        // Step 3: Wait exactly 1 clock cycle for the hardware to capture it
        @(posedge clk_wr);

        // Step 4: Turn off the write enable so you don't accidentally write twice
        wr_en   <= 1'b0;
        data_in <= 8'h00; 
        
        // ... (Step 4 of your write sequence finishes here) ...
        wr_en   <= 1'b0;
        data_in <= 8'h00; 

        // --- READING DATA_OUT ---

        // Step 5: Wait for the empty flag to drop low. 
        // (Remember, this takes a few clk_rd cycles due to the synchronizer pipeline!)
        while (empty == 1'b1) begin
            @(posedge clk_rd);
        end

        // Step 6: Assert read enable synchronous to the read clock
        rd_en <= 1'b1;

        // Step 7: Wait 1 clock cycle for data_out to update from the memory core
        @(posedge clk_rd);

        // Step 8: Deassert read enable so we don't keep reading garbage
        rd_en <= 1'b0;

        // Let simulation run a few more cycles to see the empty flag pop back up
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