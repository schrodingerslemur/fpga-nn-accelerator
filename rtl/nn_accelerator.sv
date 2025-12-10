`include "defs.svh"

module nn_accelerator(
    input logic clk,
    input logic rstn,

    // Control interface
    input logic start,
    input logic [15:0] vector_len, // number of elements in input vector
    input logic [15:0] neuron_count, // number of output neurons

    // Streaming interfaces
    // Input vector stream (one vector, length = vector_len)
    input logic in_valid,
    input logic signed [`DATA_WIDTH-1:0] in_data,
    output logic in_ready,

    // Weights stream (weights are presented neuron-by-neuron; for M neurons each has vector_len weights)
    input logic wt_valid,
    input logic signed [`DATA_WIDTH-1:0] wt_data,
    output logic wt_ready,

    // Output stream
    output logic out_valid,
    output logic signed [`ACC_WIDTH-1:0] out_data,
    input logic out_ready
);

    // internal state
    typedef enum logic [1:0] {IDLE, LOAD, COMPUTE, DRAIN} state_e;
    state_e state, next_state;

    logic [15:0] len_cnt;
    logic [15:0] neuron_cnt;

    // small RAM to hold current input vector (for simplicity kept in regs)
    logic signed [`DATA_WIDTH-1:0] input_ram [0:65535];
    // weight latch for current weight element
    logic signed [`DATA_WIDTH-1:0] weight_lat;

    // control signals to macc
    logic macc_valid;
    logic signed [`DATA_WIDTH-1:0] macc_a;
    logic signed [`DATA_WIDTH-1:0] macc_b;
    logic macc_clear;
    logic signed [`ACC_WIDTH-1:0] macc_acc;
    logic macc_ready;

    // output register
    logic [`ACC_WIDTH-1:0] out_reg;


    // state machine
    always_comb begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD;
            end
            LOAD: begin
                if (len_cnt == vector_len && neuron_cnt == 0)
                    next_state = COMPUTE;
            end
            COMPUTE: begin
                if (neuron_cnt == neuron_count && len_cnt == vector_len)
                    next_state = DRAIN;
            end
            DRAIN: begin
                next_state = IDLE;
            end
        endcase
    end

    // simple counters and interfaces
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
            len_cnt <= 0;
            neuron_cnt <= 0;
            macc_valid <= 0;
            macc_a <= '0;
            macc_b <= '0;
            macc_clear <= 1'b0;
            out_reg <= '0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    len_cnt <= 0;
                    neuron_cnt <= 0;
                end
                LOAD: begin
                    // accept input stream into input_ram
                    if (in_valid) begin
                        input_ram[len_cnt] <= in_data;
                        len_cnt <= len_cnt + 1;
                    end
                end
                COMPUTE: begin
                    // For each neuron: iterate over i in 0..vector_len-1
                    if (len_cnt < vector_len) begin
                        // present multiply inputs to macc
                        macc_valid <= 1'b1;
                        macc_a <= input_ram[len_cnt];
                        // weights are expected to be supplied on wt_data stream
                        if (wt_valid) begin
                            macc_b <= wt_data;
                            len_cnt <= len_cnt + 1;
                        end
                    end else begin
                        // end of neuron vector
                        macc_valid <= 1'b0;
                        // latch output
                        out_reg <= macc_acc;
                        // prepare for next neuron
                        len_cnt <= 0;
                        neuron_cnt <= neuron_cnt + 1;
                    end
                end
                DRAIN: begin
                    // no-op; outputs are available
                end
            endcase
        end
    end

    // connect ready signals
    assign in_ready = (state == LOAD);
    assign wt_ready = (state == COMPUTE && macc_valid);

    assign out_valid = (state == COMPUTE && macc_valid == 0 && (neuron_cnt > 0 || out_reg != 0));
    assign out_data  = out_reg;

    // instantiate macc
    macc u_macc(
        .clk(clk), .rstn(rstn), .in_valid(macc_valid),
        .a(macc_a), .b(macc_b), .acc_clear(1'b0),
        .out_ready(macc_ready), .acc(macc_acc)
    );

endmodule