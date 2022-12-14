`timescale 1ns / 1ps
`default_nettype none

module waveFilt (
    input wire clk_in,
    input wire rst_in,
    input wire [6:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [6:0] pixel_out
    );

    parameter HEIGHT = 320;
    parameter HALF_HEIGHT = 160;

    assign pixel_out = data_in;
    assign data_valid_out = data_valid_in;
    assign hcount_out = hcount_in;

    logic signed[9:0] polyTop;
    logic signed [9:0] polyMid;
    logic signed [9:0] polyBot;
    logic signed [9:0] hcount_sign;
    logic signed [9:0] finalOffset;

    assign hcount_sign = $signed({1'b0, hcount_in[8:0]});

    // assign polyMid = (hcount_sign-120)
    always_comb begin 
        if (data_valid_in)begin
            polyTop = (hcount_sign - 320)>>>3;
            polyMid = (hcount_sign - 160)>>>4;
            polyBot = (-hcount_sign)>>>3;

            if(hcount_in>160)begin
                finalOffset = polyMid * polyTop + $signed({1'b0, vcount_in});
            end else begin 
                finalOffset = polyMid * polyBot + $signed({1'b0, vcount_in});
            end

            if(finalOffset > 240) begin
                vcount_out = finalOffset - 240;
            end else if(finalOffset > 0) begin
                vcount_out = finalOffset;
            end else begin 
                vcount_out = finalOffset + 240;
            end
            // if(hcount_in > 120)begin
            // end else begin

            // end
        end else begin
            vcount_out = 0;
        end
    end



    
endmodule

`default_nettype wire