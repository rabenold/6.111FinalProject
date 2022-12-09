`timescale 1ns / 1ps
`default_nettype none


module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    input wire [6:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [2:0][6:0] line_buffer_out, //output pixels of data (blah make this packed)
    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  logic bram0w, bram1w, bram2w, bram3w;
  logic [3:0] bram_to_write;
  assign bram_to_write = {bram0w, bram1w, bram2w, bram3w};

  logic [6:0] bram0_din, bram1_din, bram2_din, bram3_din;
  logic [6:0] bram0_dout, bram1_dout, bram2_dout, bram3_dout;
  logic [6:0] bram0_dout_b, bram1_dout_b, bram2_dout_b, bram3_dout_b;

  logic new_line;

  // pipelining
  logic data_valid_pipe [2:0];
  logic [10:0] hcount_pipe [2:0];
  always_ff @(posedge clk_in) begin
    data_valid_pipe[0] <= data_valid_in;
    hcount_pipe[0] <= hcount_in;
    data_valid_pipe[1] <= data_valid_pipe[0];
    hcount_pipe[1] <= hcount_pipe[0];
    data_valid_pipe[2] <= data_valid_pipe[1];
    hcount_pipe[2] <= hcount_pipe[1];
  end

  // only use a
  xilinx_true_dual_port_read_first_1_clock_ram  
    #(.RAM_WIDTH(7), .RAM_DEPTH(320), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE(""))
    bram0 (
      .addra(hcount_in),
      .addrb(9'b0),
      .dina(bram0_din),
      .dinb(16'b0),
      .clka(clk_in),
      .wea(bram0w),
      .web(1'b0),
      .ena(1'b1),
      .enb(1'b0),
      .rsta(rst_in),
      .rstb(1'b0),
      .regcea(1'b1),
      .regceb(1'b0),
      .douta(bram0_dout),
      .doutb(bram0_dout_b)
    );

  xilinx_true_dual_port_read_first_1_clock_ram  
    #(.RAM_WIDTH(7), .RAM_DEPTH(320), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE(""))
    bram1 (
      .addra(hcount_in),
      .addrb(9'b0),
      .dina(bram1_din),
      .dinb(16'b0),
      .clka(clk_in),
      .wea(bram1w),
      .web(1'b0),
      .ena(1'b1),
      .enb(1'b0),
      .rsta(rst_in),
      .rstb(1'b0),
      .regcea(1'b1),
      .regceb(1'b0),
      .douta(bram1_dout),
      .doutb(bram1_dout_b)
    );

  xilinx_true_dual_port_read_first_1_clock_ram  
    #(.RAM_WIDTH(7), .RAM_DEPTH(320), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE(""))
    bram2 (
      .addra(hcount_in),
      .addrb(9'b0),
      .dina(bram2_din),
      .dinb(16'b0),
      .clka(clk_in),
      .wea(bram2w),
      .web(1'b0),
      .ena(1'b1),
      .enb(1'b0),
      .rsta(rst_in),
      .rstb(1'b0),
      .regcea(1'b1),
      .regceb(1'b0),
      .douta(bram2_dout),
      .doutb(bram2_dout_b)
    );
  
  xilinx_true_dual_port_read_first_1_clock_ram  
    #(.RAM_WIDTH(7), .RAM_DEPTH(320), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE(""))
    bram3 (
      .addra(hcount_in),
      .addrb(9'b0),
      .dina(bram3_din),
      .dinb(16'b0),
      .clka(clk_in),
      .wea(bram3w), 
      .web(1'b0),
      .ena(1'b1),
      .enb(1'b0),
      .rsta(rst_in),
      .rstb(1'b0),
      .regcea(1'b1),
      .regceb(1'b0),
      .douta(bram3_dout),
      .doutb(bram3_dout_b)
    );

  always_comb begin
    if (hcount_in == 0 & data_valid_in) begin
        new_line = 1;
      end
      else begin
        new_line = 0;
      end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      bram0w <= 0;
      bram1w <= 0;
      bram2w <= 0;
      bram3w <= 1;
    end
    else begin
      data_valid_out <= data_valid_pipe[2];
      hcount_out <= hcount_pipe[2];
      case (vcount_in)
        0: vcount_out <= 238;
        1: vcount_out <= 239;
        default: vcount_out <= vcount_in - 2;
      endcase
      if (data_valid_in) begin
        // save pixel, buffer lines, then switch bram to lru here 
        case (bram_to_write)
          4'b0001: begin
            bram3_din <= pixel_data_in;
            line_buffer_out[0] <= bram2_dout;
            line_buffer_out[1] <= bram1_dout;
            line_buffer_out[2] <= bram0_dout;
            if (new_line) begin
              bram0w <= 1;
              bram3w <= 0;
            end
          end
          4'b0010: begin
            bram2_din <= pixel_data_in;
            line_buffer_out[0] <= bram1_dout;
            line_buffer_out[1] <= bram0_dout;
            line_buffer_out[2] <= bram3_dout;
            if (new_line) begin
              bram3w <= 1;
              bram2w <= 0;
            end
          end
          4'b0100: begin
            bram1_din <= pixel_data_in;
            line_buffer_out[0] <= bram0_dout;
            line_buffer_out[1] <= bram3_dout;
            line_buffer_out[2] <= bram2_dout;
            if (new_line) begin
              bram2w <= 1;
              bram1w <= 0;
            end
          end
          4'b1000: begin
            bram0_din <= pixel_data_in;
            line_buffer_out[0] <= bram3_dout;
            line_buffer_out[1] <= bram2_dout;
            line_buffer_out[2] <= bram1_dout;
            if (new_line) begin
              bram1w <= 1;
              bram0w <= 0;
            end
          end
        endcase
      end
    end
  end
endmodule


`default_nettype wire
