`timescale 1ns / 1ps
`default_nettype none


module start_screen_tb;

  logic clk;
  logic rst;

  logic sw_state;
  logic [10:0] hcount_in;
  logic [9:0] vcount_in;
  logic [3:0] cam_img;
  logic btnc_pressed;
  logic [11:0] pixel_out;
  logic state_1_over;

  start_screen uut (
    .clk_in(clk),
    .rst_in(rst),
    .sw_state(sw_state),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .cam_img(cam_img),
    .btnc_pressed(btnc_pressed),
    .pixel_out(pixel_out),
    .state_1_over(state_1_over)
  );

  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("start_screen.vcd");
    $dumpvars(0, start_screen_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    $display("Test 1: switching states");
    sw_state = 0;
    hcount_in = 0;
    vcount_in = 0;
    #10;
    hcount_in = 100;
    vcount_in = 150;
    sw_state = 1;
    #10;
    btnc_pressed = 1;
    #10;
    btnc_pressed = 0;
    #40;


    $display("Finishing Sim");
    $finish;
  end
endmodule // display_filters_tb

`default_nettype wire