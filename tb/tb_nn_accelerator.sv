`timescale 1ns/1ps
`include "../rtl/defs.svh"

module tb;
    logic clk;
    logic rstn;

    logic start;
    logic [15:0] vector_len;
    logic [15:0] neuron_count;

    logic in_valid;
    logic signed [`DATA_WIDTH-1:0] in_data;
    logic in_ready;

    logic wt_valid;
    logic signed [`DATA_WIDTH-1:0] wt_data;
    logic wt_ready;

    logic out_valid;
    logic signed [`ACC_WIDTH-1:0] out_data;
    logic out_ready;

    nn_accelerator dut (
        .clk(clk), .rstn(rstn), .start(start), .vector_len(vector_len), .neuron_count(neuron_count),
        .in_valid(in_valid), .in_data(in_data), .in_ready(in_ready),
        .wt_valid(wt_valid), .wt_data(wt_data), .wt_ready(wt_ready),
        .out_valid(out_valid), .out_data(out_data), .out_ready(out_ready)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // test stimulus
    initial begin
        rstn = 0;
        start = 0;
        in_valid = 0;
        wt_valid = 0;
        out_ready = 1;
        vector_len = 8;
        neuron_count = 4;

        #100;
        rstn = 1;
        #20;

        // create input vector and weights
        int i,j;
        logic signed [`DATA_WIDTH-1:0] in_vec [0:7];
        logic signed [`DATA_WIDTH-1:0] weights [0:3][0:7];

        // small deterministic test
        for (i=0;i<vector_len;i=i+1) begin
            in_vec[i] = $signed(16'(i+1)); // 1,2,3,...
        end
        for (j=0;j<neuron_count;j=j+1) begin
            for (i=0;i<vector_len;i=i+1) begin
                weights[j][i] = $signed(16'( (j+1) * (i+1) ));
            end
        end

        // start sequence: present input vector during LOAD phase
        start = 1;
        #10;
        start = 0;

        // feed inputs
        i = 0;
        while (i < vector_len) begin
            if (in_ready) begin
                in_valid = 1;
                in_data = in_vec[i];
                #10;
                in_valid = 0;
                i = i + 1;
                #10;
            end else #10;
        end

        // now feed weights and let compute run
        for (j=0;j<neuron_count;j=j+1) begin
            i = 0;
            while (i < vector_len) begin
                if (wt_ready) begin
                    wt_valid = 1;
                    wt_data = weights[j][i];
                    #10;
                    wt_valid = 0;
                    i = i + 1;
                end else #10;
            end

            // wait for output
            wait (out_valid == 1);
            $display("Neuron %0d result = %0d", j, out_data);
            #20;
        end

        #100;
        $finish;
    end

endmodule