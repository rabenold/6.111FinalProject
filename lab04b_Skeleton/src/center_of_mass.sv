`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  logic[31:0] totalMass;
  logic[31:0] totalX;
  logic[31:0] totalY;
  logic tabulate_pulse;
  logic tabulate_remember;

  logic divide_valid;
  logic error_x,error_y, busy_x, busy_y;
  logic [31:0] quotient_x, quotient_y;
  logic [31:0] remainder_x, remainder_y;
  logic x_valid, y_valid;

  logic output_x, output_y;

  divider xQuotient(
    .clk_in(clk_in), .rst_in(rst_in),
    .dividend_in(totalX), .divisor_in(totalMass),
    .data_valid_in(divide_valid), 
    .quotient_out(quotient_x), .data_valid_out(x_valid),
    .error_out(error_x), .busy_out(busy_x)
  );

  divider yQuotient(
    .clk_in(clk_in), .rst_in(rst_in),
    .dividend_in(totalY), .divisor_in(totalMass),
    .data_valid_in(divide_valid), 
    .quotient_out(quotient_y), .data_valid_out(y_valid), 
    .error_out(error_y), .busy_out(busy_y)
  );

  

  always_ff @( posedge clk_in ) begin
    if(rst_in) begin
      divide_valid <= 0;
      totalMass <= 0;
      totalX <= 0;
      totalY <= 0;
      tabulate_pulse <= 0;
      tabulate_remember <= 0;
      x_out <= 0;
      y_out <= 0;
    end else begin 

      if(y_valid)begin
        y_out <= quotient_y;
        output_y <= 1;
      end
      if(x_valid) begin
        x_out <= quotient_x;
        output_x <= 1;
      end

      if(valid_out)begin
        valid_out <= 0;
      end else if(output_x && output_y)begin
        output_x <= 0;
        output_y <=0;
        valid_out <=1;
      end



      tabulate_pulse <= tabulate_in && (~tabulate_remember);
      tabulate_remember <= tabulate_in;
      if(tabulate_pulse)begin
        divide_valid <= 1;
      end else if (divide_valid)begin
        divide_valid <=0;
        totalX <=0;
        totalY <=0;
        totalMass <=0;
      end else if(valid_in) begin
        totalMass <= totalMass + 1;
        totalX <= totalX + x_in;
        totalY <= totalY + y_in;
      end


    end
  end

endmodule

`default_nettype wire
