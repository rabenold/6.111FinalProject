`timescale 1ns/1ps
`default_nettype none
`define MKWAVEFORM 1

module hz_clk(
    input wire clk_100mhz,
    input wire rst,
    input wire [22:0] data_in,
    output logic out_10hz
);
//----------- tested and working per 10hz_sim -------
    reg [22:0] hz_ctr;

    always @(posedge clk_100mhz)begin
        if(rst)begin
            hz_ctr <= 0;
            out_10hz <= 0; 
        end else begin
            if(hz_ctr < 5000000)begin
                hz_ctr <= hz_ctr + 1;
            end else begin
                hz_ctr <= 0;
                out_10hz <= ~out_10hz; 
            end
        end 
    end 
endmodule 
`default_nettype wire 
