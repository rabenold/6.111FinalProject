`timescale 1ns / 1ps
`default_nettype none

module kernels #(
  parameter K_SELECT=0)(
  input wire rst_in,
  output logic signed [2:0][2:0][7:0] coeffs,
  output logic signed [7:0] shift,
  output logic signed [7:0] offset);

  always_comb begin
    case (K_SELECT)
      0: begin // Identity
        coeffs[0][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[0][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[0][2] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][1] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[1][2] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][2] = rst_in ? 8'sd0 : 8'sd0;
        shift = rst_in ? 8'sd0 : 8'sd0;
        offset = rst_in ? 8'sd0 : 8'sd0;
      end

      1: begin // Gaussian Blur
        coeffs[0][0] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[0][1] = rst_in ? 8'sd0 : 8'sd2;
        coeffs[0][2] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[1][0] = rst_in ? 8'sd0 : 8'sd2;
        coeffs[1][1] = rst_in ? 8'sd0 : 8'sd4;
        coeffs[1][2] = rst_in ? 8'sd0 : 8'sd2;
        coeffs[2][0] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[2][1] = rst_in ? 8'sd0 : 8'sd2;
        coeffs[2][2] = rst_in ? 8'sd0 : 8'sd1;
        shift = rst_in ? 8'sd0 : 8'sd4;
        offset = rst_in ? 8'sd0 : 8'sd0; 
      end 

      2: begin // Sharpen
        coeffs[0][0] = rst_in ? 8'sd0 :  8'sd0;
        coeffs[0][1] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[0][2] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][0] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[1][1] = rst_in ? 8'sd0 :  8'sd5;
        coeffs[1][2] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[2][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][1] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[2][2] = rst_in ? 8'sd0 : 8'sd0;
        shift = rst_in ? 8'sd0 : 8'sd0;
        offset = rst_in ? 8'sd0 : 8'sd16;
      end

      3: begin // Ridge Detection
        coeffs[0][0] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[0][1] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[0][2] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[1][0] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[1][1] = rst_in ? 8'sd0 :  8'sd8;
        coeffs[1][2] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[2][0] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[2][1] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[2][2] = rst_in ? 8'sd0 : -8'sd1;
        shift = rst_in ? 8'sd0 : 8'sd0;
        offset = rst_in ? 8'sd0 : 8'sd16;
      end

      4: begin // Sobel X Edge Detection
        coeffs[0][0] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[0][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[0][2] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[1][0] = rst_in ? 8'sd0 : 8'sd2;
        coeffs[1][1] = rst_in ? 8'sd0 :  8'sd0;
        coeffs[1][2] = rst_in ? 8'sd0 : -8'sd2;
        coeffs[2][0] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[2][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][2] = rst_in ? 8'sd0 : -8'sd1;
        shift = rst_in ? 8'sd0 : 8'sd0;
        offset = rst_in ? 8'sd0 : 8'sd0;
      end

      5: begin // Sobel Y Edge Detection
        coeffs[0][0] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[0][1] = rst_in ? 8'sd0 : -8'sd2;
        coeffs[0][2] = rst_in ? 8'sd0 : -8'sd1;
        coeffs[1][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][2] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][0] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[2][1] = rst_in ? 8'sd0 : 8'sd2;
        coeffs[2][2] = rst_in ? 8'sd0 : 8'sd1;
        shift = rst_in ? 8'sd0 : 8'sd0;
        offset = rst_in ? 8'sd0 : 8'sd0;
      end
      default: begin //Identity kernel
        coeffs[0][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[0][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[0][2] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[1][1] = rst_in ? 8'sd0 : 8'sd1;
        coeffs[1][2] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][0] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][1] = rst_in ? 8'sd0 : 8'sd0;
        coeffs[2][2] = rst_in ? 8'sd0 : 8'sd0;
        shift = rst_in ? 8'sd0 : 8'sd0;
        offset = rst_in ? 8'sd0 : 8'sd0;
      end
    endcase
  end
endmodule

`default_nettype wire