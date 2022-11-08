module vga_mux (
  input wire [3:0] sel_in, //regular video
  input wire [11:0] camera_pixel_in,
  input wire [3:0] camera_y_in,
  input wire [3:0] channel_in,
  input wire thresholded_pixel_in,
  input wire [11:0] com_sprite_pixel_in,
  input wire crosshair_in,
  output logic [11:0] pixel_out
);

  /*
  00: normal camera out
  01: channel image (in grayscale)
  10: (thresholded channel image b/w)
  11: y channel with magenta mask

  upper bits:
  00: nothing:
  01: crosshair
  10: sprite on top
  11: nothing (magenta test color)
  */
  logic [1:0] mask_video_thresh; //
  assign mask_video_thresh = sel_in[1:0];

  logic [11:0] l_1;
  always_comb begin
    case (mask_video_thresh)
      2'b00: l_1 = camera_pixel_in;
      2'b01: l_1 = {channel_in, channel_in, channel_in};
      2'b10: l_1 = (thresholded_pixel_in !=0)?12'hFFF:12'h000;
      2'b11: l_1 = (thresholded_pixel_in != 0) ? 12'hA26 : {camera_y_in,camera_y_in,camera_y_in};
    endcase
  end

  logic [1:0] options;
  assign options = sel_in[3:2];
  logic [11:0] l_2;
  always_comb begin
    case (options)
      2'b00: l_2 = l_1;
      2'b01: l_2 = crosshair_in? 12'h0F0:l_1;
      2'b10: l_2 = (com_sprite_pixel_in >0)?com_sprite_pixel_in:l_1;
      2'b11: l_2 = 12'hA26; //test color
    endcase
  end
  assign pixel_out = l_2;
endmodule
