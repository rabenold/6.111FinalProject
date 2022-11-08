`timescale 1ns / 1ps
`default_nettype none

module scale_tb;
  //make logics for inputs and outputs!
  logic [1:0] scale_in;
  logic [10:0] hcount_in;
  logic [9:0] vcount_in;
  logic [15:0] frame_buff_in;
  logic [15:0] cam_out;

  scale uut (.scale_in(scale_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .frame_buff_in(frame_buff_in),
        .cam_out(cam_out));

  //initial block...this is our test simulation
  initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("scale.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,scale_tb); //store everything at the current level and below
    $display("Testing assorted values");
    for (int i = 0; i<1000; i = i + 50)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in =i+18;
        vcount_in = i/2;
        frame_buff_in = 16'b10101_001100_10001;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    $display("Testing horizontal cutoffs");
    for (int i = 238; i<242; i = i + 1)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in =i;
        vcount_in = 120;
        frame_buff_in = 16'b10101_001100_10001;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    for (int i = 478; i<482; i = i + 1)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in =i;
        vcount_in = 120;
        frame_buff_in = 16'b10101_001110_10001;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    for (int i = 638; i<642; i = i + 1)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in =i;
        vcount_in = 120;
        frame_buff_in = 16'b11101_001100_10001;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    $display("Testing vertical cutoffs");
    for (int i = 318; i<322; i = i + 1)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in = 19;
        vcount_in = i;
        frame_buff_in = 16'b10101_001100_10101;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    for (int i = 638; i<642; i = i + 1)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in = 19;
        vcount_in = i;
        frame_buff_in = 16'b10101_001110_10001;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    for (int i = 851; i<855; i = i + 1)begin
      for (int j = 0; j<3; j = j+1)begin
        scale_in = j;
        hcount_in = 19;
        vcount_in = i;
        frame_buff_in = 16'b11101_001100_10001;
        #10;
        $display("hcount=%4d vcount= %3d scale=%2b frame=%16b cam=%16b",hcount_in, vcount_in, scale_in, frame_buff_in, cam_out); //print nice message
      end
    end
    $display("Finishing Sim"); //print nice message
    $finish;

  end
endmodule //counter_tb

`default_nettype wire
