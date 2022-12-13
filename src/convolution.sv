`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [2:0][6:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [6:0] line_out
    );

    
    // Your code here!
    logic signed [2:0][2:0] [7:0] coeffs;
    logic signed [7:0] shift;
    logic signed [7:0] offset;

    kernels #(.K_SELECT(K_SELECT)) filtKernel(.rst_in(rst_in),
    .coeffs(coeffs), .shift(shift), .offset(offset));

    logic signed [13:0] total;
    logic [2:0][2:0][6:0] mat;

    logic[1:0] valid_pipe;
    logic[1:0] [10:0] hcount_pipe;
    logic[1:0] [9:0] vcount_pipe;
    logic signed [10:0] top_sum, mid_sum, bot_sum;
    always @(*) begin
        top_sum = ($signed({1'b0, mat[0][0]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2]}) * $signed(coeffs[0][2]));
        
        mid_sum = ($signed({1'b0, mat[1][0]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2]}) * $signed(coeffs[1][2]));
        
        bot_sum = ($signed({1'b0, mat[2][0]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2]}) * $signed(coeffs[2][2]));
        
    end

    always_ff @(posedge clk_in) begin
        if(rst_in)begin
            mat <= 0;
        end else begin
            valid_pipe <= {valid_pipe[0],data_valid_in};
            if(data_valid_in) begin
                mat[2:1] <= mat [1:0];
                mat[0] <= data_in;
                hcount_pipe <={hcount_pipe[0],hcount_in};
                vcount_pipe <={vcount_pipe[0],vcount_in};

            end
            
            line_out <= ((top_sum+mid_sum+bot_sum) >>> shift)>=0? ((top_sum+mid_sum+bot_sum) >>> shift):0;

        end
    end

    assign data_valid_out = valid_pipe[1];
    assign hcount_out = hcount_pipe[1];
    assign vcount_out = vcount_pipe[1];
    // always_ff @(posedge clk_in) begin
    //   // Make sure to have your output be set with registered logic!
    //   // Otherwise you'll have timing violations.
    //   line_out <= {r, g, 1'b0, b};
    // end
endmodule

`default_nettype wire
