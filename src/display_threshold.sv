`default_nettype none
`timescale 1ns / 1ps


module display_threshold (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire left_in,
    input wire right_in,
    input wire [11:0] frame_buff_in,

    output logic pixel_out, //either black or white
    output logic [1:0] select_out
);

    logic [10:0] arrow_x;
    logic [9:0] arrow_y;
    logic [15:0] arrow_pixel;
    logic [15:0] arrow_pixel_out;

    up_arrow_sprite #(.WIDTH(100), .HEIGHT(100)) arrow (.pixel_clk_in(clk_in), .rst_in(rst_in), .x_in(arrow_x), .hcount_in(hcount_in), .y_in(arrow_y), .vcount_in(vcount_in), .pixel_out(arrow_pixel_out));
  
    always_comb begin
      if (right_in) begin
          if (select_out == 2'b11) begin
              select_out = 2'b00;
          end else begin       
              select_out = select_out + 1;
          end
      end 
      if (left_in) begin
          if (select_out == 2'b00) begin
              select_out = 2'b11;
          end else begin       
              select_out = select_out - 1;
          end
      end 
      case (select_out)
          2'b00: begin
              arrow_x = 78;
              arrow_y = 560;
          end
          2'b01: begin
              arrow_x = 334;
              arrow_y = 560;
          end
          2'b10: begin
              arrow_x = 590;
              arrow_y = 560;
          end
          2'b11: begin
              arrow_x = 846;
              arrow_y = 560;
          end
      endcase
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            select_out <= 0;
            arrow_x <= 78;
            arrow_y <= 560;
        end
        else begin
            if (hcount_in >= 8 && hcount_in < 248 && vcount_in >= 200 && vcount_in < 520) begin //box 1
                pixel_out <= (frame_buff_in < 800) ? 0 : 1;
            end
            else if (hcount_in >= 264 && hcount_in < 504 && vcount_in >= 200 && vcount_in < 520) begin //box 2
                pixel_out <= (frame_buff_in < 1600) ? 0 : 1;
            end
            else if (hcount_in >= 520 && hcount_in < 760 && vcount_in >= 200 && vcount_in < 520) begin //box 3
                pixel_out <= (frame_buff_in < 2400) ? 0 : 1;
            end
            else if (hcount_in >= 776 && hcount_in < 1016 && vcount_in >= 200 && vcount_in < 520) begin //box 4
                pixel_out <= (frame_buff_in < 3200) ? 0 : 1;
            end

            // draw black everywhere else 
            else begin
                pixel_out <= 0;
            end
        end
    end


endmodule


`default_nettype wire