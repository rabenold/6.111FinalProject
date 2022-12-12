`default_nettype none
`timescale 1ns / 1ps


module display_filters(
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire left_in,
    input wire right_in,
    input wire [11:0] frame_buff_in,

    output logic [11:0] pixel_out,
    output logic [2:0] select_out
);

    logic use_up_arrow;
    logic [10:0] arrow_x;
    logic [9:0] arrow_y;
    logic [11:0] up_arrow_pixel_out;
    logic [11:0] down_arrow_pixel_out;
    logic [11:0] select_pixel_out;
    assign select_pixel_out = (use_up_arrow == 1) ? up_arrow_pixel_out : down_arrow_pixel_out;

    up_arrow_sprite #(.WIDTH(100), .HEIGHT(100)) up_arrow (.pixel_clk_in(clk_in), .rst_in(rst_in), .x_in(arrow_x), .hcount_in(hcount_in), .y_in(arrow_y), .vcount_in(vcount_in), .pixel_out(up_arrow_pixel_out));
    down_arrow_sprite #(.WIDTH(100), .HEIGHT(100)) down_arrow (.pixel_clk_in(clk_in), .rst_in(rst_in), .x_in(arrow_x), .hcount_in(hcount_in), .y_in(arrow_y), .vcount_in(vcount_in), .pixel_out(down_arrow_pixel_out));

    // -------------- FILTERS AND INPUTS --------------------
    // change when more filters are here

    // // dithering filter inputs
    // logic dither_data_valid_in_1;
    // logic dither_data_valid_out_1;
    // logic dither_pixel_out_1;

    // // dithering filter inputs
    // logic dither_data_valid_in_2;
    // logic dither_data_valid_out_2;
    // logic dither_pixel_out_2;

    // // dithering filter inputs
    // logic dither_data_valid_in_3;
    // logic dither_data_valid_out_3;
    // logic dither_pixel_out_3;

    // // dithering filter inputs
    // logic dither_data_valid_in_4;
    // logic dither_data_valid_out_4;
    // logic dither_pixel_out_4;

    // // dithering filter inputs
    // logic dither_data_valid_in_5;
    // logic dither_data_valid_out_5;
    // logic dither_pixel_out_5;

  
    // ditherConv #(.K_SELECT(0))
    //     dither_mod_1 (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .data_in(data_in),
    //     .hcount_in(hcount_in),
    //     .vcount_in(vcount_in),
    //     .data_valid_in(dither_data_valid_in_1),
    //     .data_valid_out(dither_data_valid_out_1),
    //     .hcount_out(hcount_out),
    //     .vcount_out(vcount_out),
    //     .pixel_out(dither_pixel_out_1)
    // );

    // ditherConv #(.K_SELECT(0))
    //     dither_mod_2 (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .data_in(data_in),
    //     .hcount_in(hcount_in),
    //     .vcount_in(vcount_in),
    //     .data_valid_in(dither_data_valid_in_2),
    //     .data_valid_out(dither_data_valid_out_2),
    //     .hcount_out(hcount_out),
    //     .vcount_out(vcount_out),
    //     .pixel_out(dither_pixel_out_2)
    // );

    // ditherConv #(.K_SELECT(0))
    //     dither_mod_3 (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .data_in(data_in),
    //     .hcount_in(hcount_in),
    //     .vcount_in(vcount_in),
    //     .data_valid_in(dither_data_valid_in_3),
    //     .data_valid_out(dither_data_valid_out_3),
    //     .hcount_out(hcount_out),
    //     .vcount_out(vcount_out),
    //     .pixel_out(dither_pixel_out_3)
    // );

    // ditherConv #(.K_SELECT(0))
    //     dither_mod_4 (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .data_in(data_in),
    //     .hcount_in(hcount_in),
    //     .vcount_in(vcount_in),
    //     .data_valid_in(dither_data_valid_in_4),
    //     .data_valid_out(dither_data_valid_out_4),
    //     .hcount_out(hcount_out),
    //     .vcount_out(vcount_out),
    //     .pixel_out(dither_pixel_out_4)
    // );

    // ditherConv #(.K_SELECT(0))
    //     dither_mod_5 (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .data_in(data_in),
    //     .hcount_in(hcount_in),
    //     .vcount_in(vcount_in),
    //     .data_valid_in(dither_data_valid_in_5),
    //     .data_valid_out(dither_data_valid_out_5),
    //     .hcount_out(hcount_out),
    //     .vcount_out(vcount_out),
    //     .pixel_out(dither_pixel_out_5)
    // );

    always_comb begin
        if (right_in) begin
            if (select_out == 3'b101) begin
                select_out = 3'b000;
            end else begin       
                select_out = select_out + 1;
            end
        end 
        if (left_in) begin
            if (select_out == 3'b000) begin
                select_out = 3'b101;
            end else begin       
                select_out = select_out - 1;
            end
        end 
        case (select_out)
            3'b000: begin
                use_up_arrow = 1;
                arrow_x = 120;
                arrow_y = 334;
            end
            3'b001: begin
                use_up_arrow = 1;
                arrow_x = 460;
                arrow_y = 334;
            end
            3'b010: begin
                use_up_arrow = 1;
                arrow_x = 800;
                arrow_y = 334;
            end
            3'b011: begin
                use_up_arrow = 0;
                arrow_x = 120;
                arrow_y = 334;
            end
            3'b100: begin
                use_up_arrow = 0;
                arrow_x = 460;
                arrow_y = 334;
            end
            3'b101: begin
                use_up_arrow = 0;
                arrow_x = 800;
                arrow_y = 334;
            end
        endcase
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            select_out <= 0;
            use_up_arrow <= 1;
            arrow_x <= 120;
            arrow_y <= 334;
        end
        else begin
            // copy filtered images into 1 of 6 boxes
            if (hcount_in >= 50 && hcount_in < 290 & vcount_in >= 26 & vcount_in < 346) begin //box 1
                // output pixel from orig photo
                pixel_out <= frame_buff_in; 
            end
            else if (hcount_in >= 390 && hcount_in < 630 & vcount_in >= 26 & vcount_in < 346) begin //box 2
                pixel_out <= frame_buff_in;
            end
            else if (hcount_in >= 730 && hcount_in < 970 & vcount_in >= 26 & vcount_in < 346) begin //box 3
                // replace pixel_out with output of different filter eventually
                pixel_out <= frame_buff_in;
            end
            else if (hcount_in >= 50 && hcount_in < 290 & vcount_in >= 446 & vcount_in < 766) begin //box 4
                // replace pixel_out with output of different filter eventually
                pixel_out <= frame_buff_in;
            end
            else if (hcount_in >= 390 && hcount_in < 630 & vcount_in >= 446 & vcount_in < 766) begin //box 5
                // replace pixel_out with output of different filter eventually
                pixel_out <= frame_buff_in;
            end
            else if (hcount_in >= 730 && hcount_in < 970 & vcount_in >= 446 & vcount_in < 766) begin //box 6
                // replace pixel_out with output of different filter eventually
                pixel_out <= frame_buff_in;
            end

            // draw black everywhere else 
            else begin
                pixel_out <= 0;
            end
        end
    end


endmodule //display_filters


`default_nettype wire