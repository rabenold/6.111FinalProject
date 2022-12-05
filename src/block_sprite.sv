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