`default_nettype none
`timescale 1ns / 1ps


module select_filter_screen (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire left_in,
    input wire right_in,

    output logic [11:0] pixel_out,
    output logic [2:0] select_out
);

    logic use_up_arrow;
    logic [10:0] arrow_x;
    logic [9:0] arrow_y;
    logic [11:0] up_arrow_pixel_out;
    logic [11:0] down_arrow_pixel_out;
    logic [11:0] select_pixel_out;
    assign select_pixel_out = (use_up_arrow) ? up_arrow_pixel_out : down_arrow_pixel_out;

    up_arrow_sprite #(.WIDTH(100), .HEIGHT(100)) up_arrow 
        (.pixel_clk_in(clk_in), 
        .rst_in(rst_in), 
        .x_in(arrow_x), 
        .hcount_in(hcount_in), 
        .y_in(arrow_y), 
        .vcount_in(vcount_in), 
        .pixel_out(up_arrow_pixel_out)
        );

    down_arrow_sprite #(.WIDTH(100), .HEIGHT(100)) down_arrow 
        (.pixel_clk_in(clk_in), 
        .rst_in(rst_in), 
        .x_in(arrow_x), 
        .hcount_in(hcount_in), 
        .y_in(arrow_y), 
        .vcount_in(vcount_in), 
        .pixel_out(down_arrow_pixel_out)
        );

    // edge detection
    logic old_left;
    logic old_right;
    logic left_click;
    logic right_click;
    always_ff @(posedge clk_in) begin
        old_left <= left_in;
        old_right <= right_in;
    end
    assign left_click = left_in & ~old_left;
    assign right_click = right_in & ~old_right;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            select_out <= 0;
            use_up_arrow <= 1;
            arrow_x <= 120;
            arrow_y <= 334;
        end
        else begin
            case (select_out)
                3'b000: begin
                    use_up_arrow <= 1;
                    arrow_x <= 120;
                    arrow_y <= 334;
                end
                3'b001: begin
                    use_up_arrow <= 1;
                    arrow_x <= 460;
                    arrow_y <= 334;
                end
                3'b010: begin
                    use_up_arrow <= 1;
                    arrow_x <= 800;
                    arrow_y <= 334;
                end
                3'b011: begin
                    use_up_arrow <= 0;
                    arrow_x <= 120;
                    arrow_y <= 334;
                end
                3'b100: begin
                    use_up_arrow <= 0;
                    arrow_x <= 460;
                    arrow_y <= 334;
                end
                3'b101: begin
                    use_up_arrow <= 0;
                    arrow_x <= 800;
                    arrow_y <= 334;
                end
            endcase
            if (right_click) begin
                if (select_out == 3'b101) begin
                    select_out <= 3'b000;
                end else begin       
                    select_out <= select_out + 1;
                end
            end 
            else if (left_click) begin
                if (select_out == 3'b000) begin
                    select_out <= 3'b101;
                end else begin       
                    select_out = select_out - 1;
                end
            end 
            pixel_out <= select_pixel_out;
        end
    end


endmodule //select_filter_screen


`default_nettype wire