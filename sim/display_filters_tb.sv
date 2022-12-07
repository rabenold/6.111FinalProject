`timescale 1ns / 1ps
`default_nettype none


module display_filters_tb;

  logic clk;
  logic rst;

  logic [10:0] hcount_in;
  logic [9:0] vcount_in;
  logic [15:0] pixel_data_in;
  logic left_in;
  logic right_in;
  logic [15:0] pixel_data_out;
  logic [2:0] select_out;

  display_filters uut (
    .clk_in(clk),
    .rst_in(rst),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .frame_buff_in(pixel_data_in),
    .left_in(left_in),
    .right_in(right_in),
    .pixel_out(pixel_data_out),
    .select_out(select_out)
  );

  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("display_filters.vcd");
    $dumpvars(0, display_filters_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    $display("Test 1: pixels in right spot");
    pixel_data_in = 16'b1000_0010_0001_0000; //random color pixel
    for (int i = 0; i < 768; i = i+1) begin
      vcount_in = i;
      for (int j = 0; j < 1024; j = j+1) begin
        hcount_in = j;
        #10;
      end
    end
    
    #20;

    $display("Test 2: selecting right");
    pixel_data_in = 16'b1000_0010_0001_0110; //random color pixel
    hcount_in = 100;
    vcount_in = 100;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;
    right_in = 1;
    #10;
    right_in = 0;
    #10;


    $display("Test 3: selecting left");
    pixel_data_in = 16'b1000_0010_0001_0110; //random color pixel
    hcount_in = 100;
    vcount_in = 100;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;
    left_in = 1;
    #10;
    left_in = 0;
    #10;

    $display("Finishing Sim");
    $finish;
  end
endmodule // display_filters_tb

`default_nettype wire