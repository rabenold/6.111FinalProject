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
    parameter WIDTH = 10;
    xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) pixel1(
    .addra(hcount_in),     // Address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(data_valid_in & write_vals[3]),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(output_pipe[0]),      // RAM output data, width determined from RAM_WIDTH
    .addrb(hcount_in),     // Address bus, width determined from RAM_DEPTH
    .dinb(pixel_data_in),       // RAM input data, width determined from RAM_WIDTH
    .web(data_valid_in & write_vals[3]),         // Write enable
    .enb(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rstb(rst_in),       // Output reset (does not affect memory contents)
    .regceb(1'b1),   // Output register enable
    .doutb(output_pipe[0])      // RAM output data, width determined from RAM_WIDTH
    );
   
    // Your code here!
    logic signed [10:0] errorOffset;
    logic signed [10:0] nextOffset;

    logic signed [2:0][10:0] bottom_Offsets;

    logic signed [10:0] current_pixel;



    // kernels #(.K_SELECT(K_SELECT)) filtKernel(.rst_in(rst_in),
    // .coeffs(coeffs), .shift(shift), .offset(offset));
    logic[1:0] [10:0] hcount_pipe;
    logic[1:0] [9:0] vcount_pipe;
    logic signed [15:0] r_top, g_top, b_top, r_mid, g_mid, b_mid, r_bot, g_bot, b_bot;

    always @(*) begin
        b_top = ($signed({1'b0, mat[0][0][4:0]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1][4:0]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2][4:0]}) * $signed(coeffs[0][2]));
        g_top = ($signed({1'b0, mat[0][0][10:5]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1][10:5]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2][10:5]}) * $signed(coeffs[0][2]));
        r_top = ($signed({1'b0, mat[0][0][15:11]}) * $signed(coeffs[0][0])) + ($signed({1'b0, mat[0][1][15:11]}) * $signed(coeffs[0][1])) + ($signed({1'b0, mat[0][2][15:11]}) * $signed(coeffs[0][2]));
        
        b_mid = ($signed({1'b0, mat[1][0][4:0]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1][4:0]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2][4:0]}) * $signed(coeffs[1][2]));
        g_mid = ($signed({1'b0, mat[1][0][10:5]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1][10:5]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2][10:5]}) * $signed(coeffs[1][2]));
        r_mid = ($signed({1'b0, mat[1][0][15:11]}) * $signed(coeffs[1][0])) + ($signed({1'b0, mat[1][1][15:11]}) * $signed(coeffs[1][1])) + ($signed({1'b0, mat[1][2][15:11]}) * $signed(coeffs[1][2]));
        
        b_bot = ($signed({1'b0, mat[2][0][4:0]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1][4:0]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2][4:0]}) * $signed(coeffs[2][2]));
        g_bot = ($signed({1'b0, mat[2][0][10:5]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1][10:5]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2][10:5]}) * $signed(coeffs[2][2]));
        r_bot = ($signed({1'b0, mat[2][0][15:11]}) * $signed(coeffs[2][0])) + ($signed({1'b0, mat[2][1][15:11]}) * $signed(coeffs[2][1])) + ($signed({1'b0, mat[2][2][15:11]}) * $signed(coeffs[2][2]));
        
        
    end

    always_ff @(posedge clk_in) begin
        if(rst_in)begin

        end else begin
            if(current_pixel+errorOffset+nextOffset < MIDPOINT)begin

            end else begin
                
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