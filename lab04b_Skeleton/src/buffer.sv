`timescale 1ns / 1ps
`default_nettype none


module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    input wire [15:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [2:0][15:0] line_buffer_out, //output pixels of data
    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  parameter WIDTH = 16;
  logic[15:0] WriteOutput;
  //logic [15:0] line_buffer_pipe [3:0];
  logic [1:0][10:0] hcount_pipe;
  logic [1:0][9:0] vcount_pipe;
  logic [3:0] [15:0] output_pipe;
  logic [4:0] write_vals;
  logic [1:0][4:0] write_pipe;
  logic [1:0] valid_pipe;
  xilinx_single_port_ram_read_first #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) pixel1(
    .addra(hcount_in),     // Address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(data_valid_in & write_vals[3]),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(output_pipe[0])      // RAM output data, width determined from RAM_WIDTH
  );
  xilinx_single_port_ram_read_first #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) pixel2(
    .addra(hcount_in),     // Address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(data_valid_in & write_vals[2]),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(output_pipe[1])      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) pixel3(
    .addra(hcount_in),     // Address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(data_valid_in & write_vals[1]),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(output_pipe[2])      // RAM output data, width determined from RAM_WIDTH
  );
  xilinx_single_port_ram_read_first #(.RAM_WIDTH(WIDTH), .RAM_DEPTH(320)) pixel4(
    .addra(hcount_in),     // Address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(data_valid_in & write_vals[0]),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(output_pipe[3])      // RAM output data, width determined from RAM_WIDTH
  );

  // Your code here!
  // logic[15:0] pixelPipeline [3:0];
  always_ff @( posedge clk_in ) begin
    if (rst_in) begin
      valid_pipe <= 0;
      write_vals <= 4'b1000;
      write_pipe <= 0;
    end else begin
      valid_pipe <= {valid_pipe[0],data_valid_in};
      write_pipe <= {write_pipe[0], write_vals};
      if(data_valid_in)begin
        hcount_pipe <= {hcount_pipe[0], hcount_in};
        vcount_pipe[1] <= vcount_pipe[0];
        
        if(vcount_in<2) begin
          vcount_pipe[0] <= vcount_in+240-2;
        end else begin
          vcount_pipe[0] <= vcount_in-2;
        end 
        if(vcount_pipe[1]!=vcount_pipe[0])begin
          write_vals <= {write_vals[0],write_vals[3:1]};
        end
      end

      case (write_pipe[1])
        4'b0001: begin
          line_buffer_out[0] <= output_pipe[2];
          line_buffer_out[1] <= output_pipe[1];
          line_buffer_out[2] <= output_pipe[0];
        end
        4'b0010: begin
          line_buffer_out[0] <= output_pipe[1];
          line_buffer_out[1] <= output_pipe[0];
          line_buffer_out[2] <= output_pipe[3];
        end
        4'b0100: begin
          line_buffer_out[0] <= output_pipe[0];
          line_buffer_out[1] <= output_pipe[3];
          line_buffer_out[2] <= output_pipe[2];
        end
        4'b1000: begin
          line_buffer_out[0] <= output_pipe[3];
          line_buffer_out[1] <= output_pipe[2];
          line_buffer_out[2] <= output_pipe[1];
        end
      endcase

    end  
  end
  assign data_valid_out = valid_pipe[1];
  assign hcount_out = hcount_pipe[1];
  assign vcount_out = vcount_pipe[1];

endmodule 


`default_nettype wire