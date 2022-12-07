
`timescale 1ns / 1ps
`default_nettype none

module block_sprite #(
  parameter WIDTH=256, HEIGHT=256, COLOR=12'hFFF)(
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [11:0] pixel_out);

  logic in_sprite;
  assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
                      (vcount_in >= y_in && vcount_in < (y_in + HEIGHT)));

  assign pixel_out = in_sprite ? COLOR : 0;
endmodule

module start_screen (
    input wire rst_in,
    input wire clk_in,
    input wire sw_state,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire [3:0] cam_img, 
    input wire btnc_pressed,

    output logic [11:0] pixel_out,
    output logic state_1_over
    );

    logic [11:0] pixel_out_drs;
    logic [11:0] pixel_out_name;

    logic [11:0] pixel_out_puck;
    logic [11:0] pixel_out_puck2;
    logic [11:0] pixel_out_test;
    block_sprite #(.WIDTH(800),.HEIGHT(128),.COLOR(12'hFFF)) block_puck
        (.x_in(100),
        .hcount_in(hcount_in),
        .y_in(50),
        .vcount_in(vcount_in),
        .pixel_out(pixel_out_puck));

    block_sprite #(.WIDTH(200),.HEIGHT(200),.COLOR(12'hFFF)) block_puck1
        (.x_in(600),
        .hcount_in(hcount_in),
        .y_in(300),
        .vcount_in(vcount_in),
        .pixel_out(pixel_out_puck2));

    block_sprite #(.WIDTH(500),.HEIGHT(500),.COLOR(12'hB1C)) testing
        (.x_in(200),
        .hcount_in(hcount_in),
        .y_in(150),
        .vcount_in(vcount_in),
        .pixel_out(pixel_out_test));

//   image_sprite img_dir (.pixel_clk_in(clk),
//    .rst_in(rst),
//    .x_in(600),
//    .hcount_in(hcount),
//    .y_in(300),
//    .vcount_in(vcount),
//    .pixel_out(pixel_out_puck2));

//image_sprite img_name (.pixel_clk_in(clk_65mhz),
//     .rst_in(sys_rst),
//     .x_in(100),
//     .hcount_in(hcount),
//     .y_in(100),
//     .vcount_in(vcount),
//     .pixel_out(pixel_out_puck));
    
    parameter START = 0;
    parameter DISPLAY = 1;
    parameter THRESH = 2;
    logic [1:0] state;

    logic btnc_was_pressed;
    assign state_1_over = btnc_was_pressed;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pixel_out <= 0;
            btnc_was_pressed <= 0;
            state <= 0;
        end 
        else begin
            case (state)
                START: begin
                    btnc_was_pressed <= btnc_pressed && sw_state ? 1 : btnc_was_pressed;
                    if (!btnc_was_pressed) begin
                        pixel_out <= sw_state ? (pixel_out_puck | pixel_out_puck2) : (pixel_out_puck);
                    end
                    else begin
                        pixel_out <= 12'b0;
                    end
                    if (state_1_over) begin
                        state <= DISPLAY;
                    end 
                end
                DISPLAY: begin
                    pixel_out <= 12'hB1C;
                end
            endcase
        end
   end 
endmodule 

`default_nettype wire
