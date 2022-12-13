`timescale 1ns / 1ps
`default_nettype none

module ditherConv (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [6:0] pixel_out
    );

    parameter MIDPOINT = 64;
    parameter MAX_VAL = 127;
    parameter WIDTH = 7;

    logic[10:0] line1_read;
    // logic[10:0] line2_read;

    logic[10:0] line1_writeOut;
    // logic[10:0] line2_writeOut;

    logic[2:0][10:0] hcount_pipe;
    logic [1:0][9:0] vcount_pipe;
    logic [1:0] valid_pipe;
    logic [1:0][10:0] pixel_pipe;

    xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) line(
    .addra(hcount_pipe[0]),     // Address bus, width determined from RAM_DEPTH
    .dina(11'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(line1_read),      // RAM output data, width determined from RAM_WIDTH

    .addrb(hcount_pipe[2]),     // Address bus, width determined from RAM_DEPTH
    .dinb(bottom_Offsets[0]),       // RAM input data, width determined from RAM_WIDTH
    .web(1),         // Write enable
    .enb(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rstb(rst_in),       // Output reset (does not affect memory contents)
    .regceb(1'b1),   // Output register enable
    .doutb(line1_writeOut)      // RAM output data, width determined from RAM_WIDTH
    );

    // xilinx_true_dual_port_read_first_1_clock_raiverilog -g2012 -o foo.out sim/foo_tb.sv src/foo.svm #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) line2(
    // .addra(hcount_in+1),     // Address bus, width determined from RAM_DEPTH
    // .dina(0),       // RAM input data, width determined from RAM_WIDTH
    // .clka(clk_in),       // Clock
    // .wea(1'b0),         // Write enable
    // .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    // .rsta(rst_in),       // Output reset (does not affect memory contents)
    // .regcea(1'b1),   // Output register enable
    // .douta(line1_read),      // RAM output data, width determined from RAM_WIDTH

    // .addrb(hcount_in-1),     // Address bus, width determined from RAM_DEPTH
    // .dinb(bottom_Offsets[0]),       // RAM input data, width determined from RAM_WIDTH
    // .web(1'b1),         // Write enable
    // .enb(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    // .rstb(rst_in),       // Output reset (does not affect memory contents)
    // .regceb(1'b1),   // Output register enable
    // .doutb(line1_writeOut)      // RAM output data, width determined from RAM_WIDTH
    // );
   
    // Your code here!
    logic signed [10:0] final_error;
    logic signed [10:0] errorOffset;

    logic signed [10:0] nextOffset;
    logic signed [2:0][10:0] bottom_Offsets = 0;
    logic signed [10:0] current_pixel;

    assign final_error = errorOffset+nextOffset+current_pixel;
    assign errorOffset = $signed(line1_read);

    always_ff @(posedge clk_in) begin
        if(rst_in)begin
            nextOffset <=0;
            bottom_Offsets <=0;
            current_pixel <=0;
            
            pixel_pipe <=0;
            hcount_pipe <=0;
            vcount_pipe <=0;
            valid_pipe <=0;
        end else if (data_valid_in) begin

            current_pixel<= pixel_pipe[0];

            pixel_pipe <= {data_in,pixel_pipe[1]};
            hcount_pipe <= {hcount_pipe[1:0], hcount_in};
            vcount_pipe <= {vcount_in, vcount_pipe[1]};
            valid_pipe <= {data_valid_in, valid_pipe[1]};

            if(current_pixel+errorOffset+nextOffset < MIDPOINT)begin
                pixel_out <= 0;

                nextOffset <= (final_error*7)>>>4;
                bottom_Offsets[0] <= bottom_Offsets[1] + ((final_error*3)>>>4);
                bottom_Offsets[1] <= bottom_Offsets[2] + ((final_error*5)>>>4);
                bottom_Offsets[2] <= ((final_error)>>>4);
            end else begin
                pixel_out <=MAX_VAL;

                nextOffset <= ((final_error-MAX_VAL)*7)>>>4;
                bottom_Offsets[0] <= bottom_Offsets[1] + (((final_error-MAX_VAL)*3)>>>4);
                bottom_Offsets[1] <= bottom_Offsets[2] + (((final_error-MAX_VAL)*5)>>>4);
                bottom_Offsets[2] <= ((final_error-MAX_VAL)>>>4);
            end
        end
    end

    assign data_valid_out = valid_pipe[0];
    assign hcount_out = hcount_pipe[1];
    assign vcount_out = vcount_pipe[0];
endmodule

`default_nettype wire