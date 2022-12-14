`default_nettype none
`timescale 1ns / 1ps


module addressing_threshold (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,

    output logic [16:0] address_1;
    output logic [16:0] address_2;
    output logic [16:0] address_3;
    output logic [16:0] address_4;
);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            //
        end
        else begin
            if (hcount_in == 8 && vcount_in == 200) begin
                address_1 <= 76799;
            end
            else if (hcount_in == 264 && vcount_in == 200) begin
                address_2 <= 76799;
            end
            else if (hcount_in == 520 && vcount_in == 200) begin
                address_3 <= 76799;
            end
            else if (hcount_in == 776 && vcount_in == 200) begin
                address_4 <= 76799;
            end

            else if (hcount_in >= 8 && hcount_in < 248 && vcount_in >= 200 && vcount_in < 520) begin 
                address_1 <= address_1 - 1;
            end
            else if (hcount_in >= 264 && hcount_in < 504 && vcount_in >= 200 && vcount_in < 520) begin 
                address_2 <= address_2 - 1;
            end
            else if (hcount_in >= 520 && hcount_in < 760 && vcount_in >= 200 && vcount_in < 520) begin 
                address_3 <= address_3 - 1;
            end
            else if (hcount_in >= 776 && hcount_in < 1016 && vcount_in >= 200 && vcount_in < 520) begin 
                address_4 <= address_4 - 1;
            end
        end
    end


endmodule


`default_nettype wire