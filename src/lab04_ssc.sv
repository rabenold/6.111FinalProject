`timescale 1ns / 1ps
`default_nettype none

module lab04_ssc #(parameter COUNT_TO = 100000)
                                (   input wire         clk_in,
                                    input wire         rst_in,
                                    input wire [8:0]  val_in,
                                    output logic[6:0]   cat_out,
                                    output logic[7:0]   an_out
                                 );

  logic[7:0]      segment_state;
  logic[31:0]     segment_counter;
  logic [6:0]     led_out;

  logic [6:0] symbol_cat [1:0];
  always_comb begin
    case(val_in[2:0])
      3'b000: symbol_cat[0] = 7'b1010000; //r
      3'b001: symbol_cat[0] = 7'b1101111; //g
      3'b010: symbol_cat[0] = 7'b1111100; //b
      3'b011: symbol_cat[0] = 7'b0000000; //null
      3'b100: symbol_cat[0] = 7'b1101110; //y
      3'b101: symbol_cat[0] = 7'b1010000; //r (Cr)
      3'b110: symbol_cat[0] = 7'b1111100; //b (Cb)
      3'b111: symbol_cat[0] = 7'b0000000; //null
    endcase
  end

  always_comb begin
    case(val_in[2:0])
      3'b000: symbol_cat[1] = 7'b0000000; //r
      3'b001: symbol_cat[1] = 7'b0000000; //g
      3'b010: symbol_cat[1] = 7'b0000000; //b
      3'b011: symbol_cat[1] = 7'b0000000; //null
      3'b100: symbol_cat[1] = 7'b0000000; //y
      3'b101: symbol_cat[1] = 7'b0111001; //C (Cr)
      3'b110: symbol_cat[1] = 7'b0111001; //C (Cb)
      3'b111: symbol_cat[1] = 7'b0000000; //null
    endcase
  end

  assign cat_out = ~led_out;
  assign an_out = ~segment_state;

  always_comb begin
    case(segment_state)
      8'b0000_0001:   led_out = val_in[3]? 7'b0000110:7'b0111111;
      8'b0000_0010:   led_out = val_in[4]? 7'b0000110:7'b0111111;
      8'b0000_0100:   led_out = val_in[5]? 7'b0000110:7'b0111111;
      8'b0000_1000:   led_out = symbol_cat[0];
      8'b0001_0000:   led_out = symbol_cat[1];
      8'b0010_0000:   led_out = val_in[6]? 7'b0000110:7'b0111111;
      8'b0100_0000:   led_out = val_in[7]? 7'b0000110:7'b0111111;
      8'b1000_0000:   led_out = val_in[8]? 7'b0000110:7'b0111111;
      default:        led_out = 7'b0000000;
    endcase
  end
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO)begin
          segment_counter <= 32'd0;
          segment_state <= {segment_state[6:0],segment_state[7]};
      end else begin
          segment_counter <= segment_counter +1;
      end
    end
  end
endmodule //seven_segment_controller


`default_nettype wire
