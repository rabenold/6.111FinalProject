`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);
  logic[10:0] hBound;
  logic[9:0] vBound;
  always_comb begin
    case (scale_in)
      2'b00: begin
        vBound = 320;
        hBound = 240;
      end
      2'b01: begin
        vBound = 640;
        hBound = 480;
      end
      2'b10, 2'b11: begin
        vBound = 853;
        hBound = 640;
      end
    endcase
  end
  assign cam_out = (hcount_in<hBound && vcount_in<vBound)? frame_buff_in : 0;
endmodule


`default_nettype wire
