`include "defs.svh"

module macc(
    input logic clk,
    input logic rstn,
    input logic in_valid,
    input logic signed [`DATA_WIDTH-1:0] a,
    input logic signed [`DATA_WIDTH-1:0] b,
    input logic acc_clear,
    output logic out_ready,
    output logic signed [`ACC_WIDTH-1:0] acc
);

    logic signed [`ACC_WIDTH-1:0] acc_r;

    assign acc = acc_r;
    assign out_ready = in_valid; // combinationally ready when input valid

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            acc_r <= '0;
        end 
        else begin
            if (acc_clear)
                acc_r <= '0;
            else if (in_valid)
                acc_r <= acc_r + (a * b);
        end
    end
    
endmodule