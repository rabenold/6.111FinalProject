`timescale 1ns / 1ps
`default_nettype none

module mirror(
  input wire clk_in,
  input wire [1:0] scale_in,
  input wire mirror_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [16:0] pixel_addr_out);
  logic [10:0] hcount_temp;
  logic [9:0] vcount_pip;

  always_ff @(posedge clk_in) begin
    vcount_pip <= vcount_in;
    if(scale_in==2'b0)begin
      hcount_temp <= mirror_in?(240-hcount_in):hcount_in;
      pixel_addr_out <= hcount_temp + 240*(vcount_pip);
    end else if (scale_in==2'b01)begin
      hcount_temp <= mirror_in?(480-hcount_in):hcount_in;
      pixel_addr_out <= (hcount_temp/2) + 240*((vcount_pip)/2);
    end else begin
      //great bug!
      hcount_temp <= mirror_in?(640-hcount_in):hcount_in;
      pixel_addr_out <= ((hcount_temp>>3) + (hcount_temp>>2)) + 240*((vcount_pip>>3) + (vcount_pip>>2));
    end
  end

endmodule

`default_nettype none
