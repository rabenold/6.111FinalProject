`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [2:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    
    // Your code here!
    logic signed [2:0][2:0] [7:0] coeffs;
    logic signed [7:0] shift;
    logic signed [7:0] offset;

    kernels #(.K_SELECT(K_SELECT)) filtKernel(.rst_in(rst_in),
    .coeffs(coeffs), .shift(shift), .offset(offset));

    logic signed [13:0] total;
    logic [2:0][2:0][15:0] mat;
    logic signed [15:0] total_r, total_g, total_b;
    logic [4:0] r_out, b_out;
    logic [5:0] g_out;

    logic[1:0] valid_pipe;
    logic[1:0] [10:0] hcount_pipe;
    logic[1:0] [9:0] vcount_pipe;
    logic signed [15:0] r_top, g_top, b_top, r_mid, g_mid, b_mid, r_bot, g_bot, b_bot;
    always @(*) begin
        b_top = ($signed({1'b0, mat[0][0][4:0]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1][4:0]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2][4:0]}) * $signed(coeffs[0][2]));
        g_top = ($signed({1'b0, mat[0][0][10:5]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1][10:5]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2][10:5]}) * $signed(coeffs[0][2]));
        r_top = ($signed({1'b0, mat[0][0][15:11]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1][15:11]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2][15:11]}) * $signed(coeffs[0][2]));
        
        b_mid = ($signed({1'b0, mat[1][0][4:0]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1][4:0]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2][4:0]}) * $signed(coeffs[1][2]));
        g_mid = ($signed({1'b0, mat[1][0][10:5]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1][10:5]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2][10:5]}) * $signed(coeffs[1][2]));
        r_mid = ($signed({1'b0, mat[1][0][15:11]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1][15:11]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2][15:11]}) * $signed(coeffs[1][2]));
        
        b_bot = ($signed({1'b0, mat[2][0][4:0]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1][4:0]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2][4:0]}) * $signed(coeffs[2][2]));
        g_bot = ($signed({1'b0, mat[2][0][10:5]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1][10:5]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2][10:5]}) * $signed(coeffs[2][2]));
        r_bot = ($signed({1'b0, mat[2][0][15:11]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1][15:11]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2][15:11]}) * $signed(coeffs[2][2]));
        
        
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
            total_r <= r_top+r_mid+r_bot;
            total_b <= b_top+b_mid+b_bot;
            total_g <= g_top+g_mid+g_bot;
            r_out <= ((total_r) >>> shift)>0? ((total_r) >>> shift):0;
            g_out <= ((total_g) >>> shift)>0? ((total_g) >>> shift):0;
            b_out <= ((total_b) >>> shift)>0? ((total_b) >>> shift):0;
            
        end
    end

    assign line_out = {r_out,g_out,b_out};
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
