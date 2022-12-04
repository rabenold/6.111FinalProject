
`timescale 1ns / 1ps
`default_nettype none

module start_screen 
    (input wire rst,
    input wire clk,
    input wire sw_state,
    input wire [10:0] hcount,
    input wire [9:0] vcount,
    input wire [3:0] cam_img, 
    input wire btnc_pressed,
    output logic [11:0] pixel_out,
    output logic state_1_over);

    logic [11:0] pixel_out_drs;
    logic [11:0] pixel_out_name;

   logic [11:0] pixel_out_puck2;
   logic [11:0] pixel_out_puck;
  block_sprite #(.WIDTH(800),.HEIGHT(128),.COLOR(12'hFFFF)) block_puck
      (.x_in(100),
       .hcount_in(hcount),
       .y_in(50),
       .vcount_in(vcount),
       .pixel_out(pixel_out_puck));

  block_sprite #(.WIDTH(200),.HEIGHT(200),.COLOR(12'hFFFF)) block_puck1
      (.x_in(600),
       .hcount_in(hcount),
       .y_in(300),
       .vcount_in(vcount),
       .pixel_out(pixel_out_puck2));

   logic btnc_was_pressed;
//   image_sprite img_dir (.pixel_clk_in(clk),
//    .rst_in(rst),
//    .x_in(600),
//    .hcount_in(hcount),
//    .y_in(300),
//    .vcount_in(vcount),
//    .pixel_out(pixel_out_puck2));

//mage_sprite img_name (.pixel_clk_in(clk_65mhz),
//     .rst_in(sys_rst),
//     .x_in(100),
//     .hcount_in(hcount),
//     .y_in(100),
//     .vcount_in(vcount),
//     .pixel_out(pixel_out_puck));
    

    always_ff @(posedge clk)begin
        if(rst)begin
            pixel_out<=1'b0;
            btnc_was_pressed <= 0;
        end 

        else begin
            btnc_was_pressed <= btnc_pressed && sw_state ? 1 : btnc_was_pressed;
            if(!btnc_was_pressed)
                pixel_out <= sw_state ? (pixel_out_puck | pixel_out_puck2 | cam_img) : (pixel_out_puck | cam_img);
            else pixel_out <=12'b0; 
        end
   end 
   assign state_1_over = btnc_was_pressed;
endmodule 

`default_nettype wire
