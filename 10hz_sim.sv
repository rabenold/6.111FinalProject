`define MKWAVEFORM 1
`default_nettype none
`timescale 1ns / 1ps
module hz_tester();

    logic clk_in;
    logic rst_in;
    logic hz_out;
    logic [22:0] data_in;
pulse_clk uut(.clk_100mhz(clk_in),
    .rst(rst_in),
    .data_in(data_in),
    .out_10hz(hz_out)
);

always begin
    #5;
    clk_in = !clk_in;    //100MHz clock
end 

initial begin
    $dumpfile("obj/10hz_ctr.vcd");
    $dumpvars(0,hz_tester);
    $display("Starting Sim");
    data_in  =0;
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0; 
    #100;
    rst_in = 1;
    #10;
    rst_in = 0;

    for (integer i = 0; i <5000000; i = i+1)begin
        data_in = data_in + 1; 
        #10;
    end


    for (integer i = 0; i <5000000; i = i+1)begin
        data_in = data_in + 1; 
        #10;
    end

    for (integer i = 0; i <5000000; i = i+1)begin
        data_in = data_in + 1; 
        #10;
    end

    for (integer i = 0; i <5000000; i = i+1)begin
        data_in = data_in + 1; 
        #10;
    end
    for (integer i = 0; i <5000000; i = i+1)begin
        data_in = data_in + 1; 
        #10;
    end
    #1000;
    $display("Finishing Sim");
    $finish;
end 
endmodule 
`default_nettype wire






