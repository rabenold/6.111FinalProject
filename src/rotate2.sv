//now runs on 65 MHz:
module rotate2 (
  input wire clk_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire data_valid_in,
  input wire [15:0] pixel_in,
  output logic [15:0] pixel_out,
  output logic [16:0] pixel_addr_out,
  output logic data_valid_out
  );

  logic valid_pipe;
  logic [15:0] pixel_pipe;
  logic [16:0] prod1;
  logic [9:0] vcount_pipe;

  always_ff @(posedge clk_in) begin
    //valid_pipe <= valid_pixel_in;
    valid_pipe <= data_valid_in;
    vcount_pipe <= vcount_in;
    pixel_pipe <= pixel_in;
    data_valid_out <= valid_pipe;
    prod1 <= (319-hcount_in)*240;
    pixel_addr_out<= prod1 + vcount_pipe;
    pixel_out <= pixel_pipe;
  end
endmodule
