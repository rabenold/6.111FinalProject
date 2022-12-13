`timescale 1ns / 1ps
`default_nettype none

module threshold (
    input wire [6:0] pixel_in,
	input wire [1:0] thresh_mux,
    output logic pixel_out
    );

	always_comb begin
		if(thresh_mux==0)begin
			pixel_out = (pixel_in>25);
		end else if (thresh_mux==1) begin
			pixel_out = (pixel_in>51);
		end else if (thresh_mux==2) begin
			pixel_out = (pixel_in>77);
		end else if (thresh_mux==3) begin
			pixel_out = (pixel_in>102);
		end
	end


    
endmodule

`default_nettype wire