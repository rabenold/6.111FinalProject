`timescale 1ns/1ps
`default_nettype none
`define MKWAVEFORM 1

module pulse_clk(
    input wire clk_100mhz,
    input wire rst,
    input wire [22:0] data_in,
    output logic out_10hz
);
//----------- tested and working per 10hz_sim -------
    reg [22:0] hz_ctr;


    logic [1:0] step_ctr;
    logic q1;
    logic q2;
    logic q3;
    logic q4;

    always @(posedge clk_100mhz)begin
        if(rst)begin
            hz_ctr <= 0;
            out_10hz <= 0; 
    
            step_ctr <= 0;
            q1 <= 0;
            q2 <= 0;
            q3 <= 0;
            q4 <= 0;
            hz_ctr <= 0;

        end else begin
            if(hz_ctr < 5000000)begin
                hz_ctr <= hz_ctr + 1;
            end else begin
                hz_ctr <= 0;
                out_10hz <= ~out_10hz; 
            end
        end 
    end 

//----------- this also works in sim ------    
    always_ff @(posedge out_10hz) begin
        case(step_ctr)
            2'b00: begin
                q1 <= 1;
                q2 <= 0;
                q3 <= 1;
                q4 <= 0;
                step_ctr <= step_ctr + 1;
                end 
            2'b01: begin
                q1 <= 0;
                q2 <= 1;
                q3 <= 1;
                q4 <= 0;
                step_ctr <= step_ctr + 1;
                end 
            2'b10: begin
                q1 <= 0;
                q2 <= 1;
                q3 <= 0;
                q4 <= 1;
                step_ctr <= step_ctr + 1;
                end 
            2'b11: begin
                q1 <= 1;
                q2 <= 0;
                q3 <= 0;
                q4 <= 1; 
                step_ctr <= 0;
                end 
        endcase 
   end

endmodule 
`default_nettype wire 
