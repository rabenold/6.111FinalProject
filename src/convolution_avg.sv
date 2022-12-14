`timescale 1ns / 1ps
`default_nettype none

module convolution_avg (
    input wire clk_in,
    input wire rst_in,
    input wire [2:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic pixel_out
    );

    
    // logic signed [3:0] total;
    logic [2:0][2:0] mat;

    logic[1:0] valid_pipe;
    logic[1:0] [10:0] hcount_pipe;
    logic[1:0] [9:0] vcount_pipe;
    logic signed [2:0] top_sum, mid_sum, bot_sum;
    always @(*) begin
        top_sum = mat[0][0]+mat[0][1]+mat[0][2];
        mid_sum = mat[1][0]+mat[1][1]+mat[1][2];
        bot_sum = mat[2][0]+mat[2][1]+mat[2][2];
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
            
            if((top_sum+mid_sum+bot_sum)>4) begin
                pixel_out <= 1;
            end else begin
                pixel_out <=0;
            end

        end
    end

    assign data_valid_out = valid_pipe[1];
    assign hcount_out = hcount_pipe[1];
    assign vcount_out = vcount_pipe[1];
endmodule

`default_nettype wire
