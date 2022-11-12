`timescale 1ns / 1ps
`default_nettype none

module ditherConv #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic pixel_out
    );

    parameter MIDPOINT = 128;
    parameter MAX_VAL = 255;
    parameter WIDTH = 10;

    logic[10:0] line1_read;
    // logic[10:0] line2_read;

    logic[10:0] line1_writeOut;
    // logic[10:0] line2_writeOut;
    xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) line1(
    .addra(hcount_pipe[1]),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(line1_read),      // RAM output data, width determined from RAM_WIDTH

    .addrb(hcount_pipe[0]),     // Address bus, width determined from RAM_DEPTH
    .dinb(bottom_Offsets[0]),       // RAM input data, width determined from RAM_WIDTH
    .web(1'b1),         // Write enable
    .enb(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rstb(rst_in),       // Output reset (does not affect memory contents)
    .regceb(1'b1),   // Output register enable
    .doutb(line1_writeOut)      // RAM output data, width determined from RAM_WIDTH
    );

    // xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) line2(
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
    logic signed [10:0] errorOffset;
    logic signed [10:0] nextOffset;
    logic signed [2:0][10:0] bottom_Offsets;
    logic signed [10:0] current_pixel;
    logic signed [10:0] final_error;
    logic signed [10:0] error_input;

    assign final_error = errorOffset+nextOffset+current_pixel;

    

    always_ff @(posedge clk_in) begin
        if(rst_in)begin

        end else if (data_valid_in) begin
            if(current_pixel+errorOffset+nextOffset < MIDPOINT)begin
                nextOffset <= (final_error*7)>>>4;
                bottom_Offsets[0] <= bottom_Offsets[1] + ((final_error*3)>>>4);
                bottom_Offsets[1] <= bottom_Offsets[2] + ((final_error*5)>>>4);
                bottom_Offsets[2] <= ((final_error)>>>4);
            end else begin
                nextOffset <= ((final_error-MAX_VAL)*7)>>>4;
                bottom_Offsets[0] <= bottom_Offsets[1] + (((final_error-MAX_VAL)*3)>>>4);
                bottom_Offsets[1] <= bottom_Offsets[2] + (((final_error-MAX_VAL)*5)>>>4);
                bottom_Offsets[2] <= ((final_error-MAX_VAL)>>>4);
            end
        end
    end

    assign line_out = {r_out,g_out,b_out};
    assign data_valid_out = valid_pipe[1];
    assign hcount_out = hcount_pipe[1];
    assign vcount_out = vcount_pipe[1];
    // always_ff @(posedge clk_in) begin
    //   // Make sure to have your output be set with registered logic!
    //   // Otherwise you'll have timing violations.
    //   line_out <= {r, g, 1'b0, b};
    // end
endmodule

`default_nettype wire