`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire cpu_resetn,


  output logic [7:0] jc,
  output logic [7:0] jd,
  output logic [15:0] led
  );


  logic pixel_value_in; 
  logic ready_next_pixel;

  logic [3:0] jc_out;
  logic [3:0] jd_out;
  logic [15:0] led_out;


  assign pixel_value_in = sw[2]; 

  plotter_control plotter_control( 
    .clk_100mhz(clk_100mhz),
    .sw(sw),
    .cpu_resetn(cpu_resetn),
    .pixel_value_in(pixel_value_in),

    .jc_out(jc_out),
    .jd_out(jd_out),
    .led_out(led_out)
  );


assign jc[1] = jc_out[0];
assign jc[5] = jc_out[1];
assign jc[2] = jc_out[2];
assign jc[6] = jc_out[3];

assign jd[1] = jd_out[0];
assign jd[5] = jd_out[1];
assign jd[2] = jd_out[2];
assign jd[6] = jd_out[3];

assign led[15:0] = led_out;




endmodule
`default_nettype wire 
