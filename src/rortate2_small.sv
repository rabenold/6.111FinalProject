module rotate2_small (
  input wire clk_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire data_valid_in,
  input wire pixel_in,
  output logic pixel_out,
  output logic [16:0] pixel_addr_out,
  output logic data_valid_out
  );

  logic valid_pipe;
  logic pixel_pipe;
  logic [16:0] prod1;
  logic [9:0] vcount_pipe;

  always_ff @(posedge clk_in) begin
    pixel_pipe <= pixel_in;
    valid_pipe <= data_valid_in;
    vcount_pipe <= vcount_in;
    pixel_pipe <= pixel_in;
    data_valid_out <= valid_pipe;
    prod1 <= (106-hcount_in)*80;
    pixel_addr_out<= prod1 + vcount_pipe;
    pixel_out <= pixel_pipe;
  end
endmodule
