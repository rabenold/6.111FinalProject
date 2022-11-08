`timescale 1ns / 1ps
`default_nettype none

module buffer_tb;
  logic clk;
  logic rst;

  logic [10:0] hcount_in, hcount_out;
  logic [9:0] vcount_in, vcount_out;
  logic data_valid_in, data_valid_out;
  logic [15:0] pixel_data_in;
  logic [2:0][15:0] line_buffer_out;
  logic [15:0] pixel1;
  logic [15:0] pixel2;
  logic [15:0] pixel3;
  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  buffer uut (
    .clk_in(clk),
    .rst_in(rst),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .pixel_data_in(pixel_data_in),
    .data_valid_in(data_valid_in),

    .line_buffer_out(line_buffer_out),
    .hcount_out(hcount_out),
    .vcount_out(vcount_out),
    .data_valid_out(data_valid_out));

  assign pixel1 = line_buffer_out[0];
  assign pixel2 = line_buffer_out[1];
  assign pixel3 = line_buffer_out[2];
  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("buffer.vcd");
    $dumpvars(0, buffer_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    //ALL PIXELS ARE THE SAME (ABC)
    data_valid_in = 1;
    pixel_data_in = 16'hABC;
    for (int i = 0; i<2; i++) begin
      for(int y = 0; y< 10; y++)begin
        vcount_in = y;
        for(int x = 0; x<10; x++)begin
          hcount_in = x;
          #10;
        end
      end
    end
    data_valid_in = 0;

    // LINEARLY INCREASING
    #50;
    data_valid_in = 1;
    pixel_data_in = 16'h0;
    for (int i = 0; i<2; i++) begin
      for(int y = 0; y< 10; y++)begin
        vcount_in = y;
        for(int x = 0; x<10; x++)begin
          pixel_data_in = pixel_data_in +1;
          hcount_in = x;
          #10;
        end
      end
    end
    data_valid_in = 0;

    //WITH VALID CHANGES
    #50;
    data_valid_in = 1;
    pixel_data_in = 16'h0;
    for (int i = 0; i<2; i++) begin
      for(int y = 0; y< 350; y++)begin
        vcount_in = y;
        for(int x = 0; x<400; x++)begin
          pixel_data_in = pixel_data_in +1;
          hcount_in = x;
          data_valid_in = (x<320 && y<350);
          #10;
        end
      end
    end
    data_valid_in = 0;

    $display("Finishing Sim");
    $finish;
  end
endmodule //buffer_tb

`default_nettype wire