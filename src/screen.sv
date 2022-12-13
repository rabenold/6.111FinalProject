`timescale 1ns / 1ps
`default_nettype none

module screen (
    input wire rst_in,
    input wire clk_in,
    input wire sw_state,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire [3:0] cam_img, 
    input wire middle_in,
    input wire left_in,
    input wire right_in,

    output logic [11:0] pixel_out,
    output logic [2:0] filter_select_out,
    output logic [2:0] threshold_select_out,
    output logic start_over,
    output logic filters_over,
    output logic threshold_over
    );


    // start screen logic
    logic [11:0] pixel_out_photobooth;
    logic [11:0] pixel_out_start_instructions;
    logic [11:0] pixel_out_instructions;
    photobooth_sprite #(.WIDTH(800), .HEIGHT(128)) photobooth_image 
        (.pixel_clk_in(clk_in), 
        .rst_in(rst_in), 
        .x_in(100), 
        .hcount_in(hcount_in), 
        .y_in(50), 
        .vcount_in(vcount_in), 
        .pixel_out(pixel_out_photobooth));
    start_instructions_sprite #(.WIDTH(200), .HEIGHT(130)) start_instructions_image 
        (.pixel_clk_in(clk_in), 
        .rst_in(rst_in), 
        .x_in(600), 
        .hcount_in(hcount_in), 
        .y_in(225), 
        .vcount_in(vcount_in), 
        .pixel_out(pixel_out_start_instructions));
    instructions_sprite #(.WIDTH(200), .HEIGHT(200)) instructions_image 
        (.pixel_clk_in(clk_in), 
        .rst_in(rst_in), 
        .x_in(600), 
        .hcount_in(hcount_in), 
        .y_in(400), 
        .vcount_in(vcount_in), 
        .pixel_out(pixel_out_instructions));

    // filter select logic
    logic use_up_arrow;
    logic [10:0] arrow_x;
    logic [9:0] arrow_y;
    logic [11:0] up_arrow_pixel_out;
    logic [11:0] down_arrow_pixel_out;
    logic [11:0] select_pixel_out;
    logic [11:0] filter_screen_instructions_pixel_out;
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
    filter_select_instructions_sprite #(.WIDTH(900), .HEIGHT(24)) filter_screen_instructions 
        (.pixel_clk_in(clk_in), 
        .rst_in(rst_in), 
        .x_in(62), 
        .hcount_in(hcount_in), 
        .y_in(2), 
        .vcount_in(vcount_in), 
        .pixel_out(filter_screen_instructions_pixel_out)
        );

    // edge detection logic 
    logic old_left;
    logic old_right;
    logic old_middle;
    logic left_click;
    logic right_click;
    logic middle_click;
    always_ff @(posedge clk_in) begin
        old_left <= left_in;
        old_right <= right_in;
        old_middle <= middle_in;
    end
    assign left_click = left_in & ~old_left;
    assign right_click = right_in & ~old_right;
    assign middle_click = middle_in & ~old_middle;
    logic done_start;
    
    // state machine logic
    parameter START = 0;
    parameter FILTERS = 1;
    parameter THRESHOLD = 2;
    parameter SEND = 3;
    logic [1:0] state;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            start_over <= 0;
            filters_over <= 0;
            threshold_over <= 0;
            state <= START;
            done_start <= 0;
            filter_select_out <= 0;
            threshold_select_out <= 0;
            use_up_arrow <= 1;
            arrow_x <= 120;
            arrow_y <= 334;
        end 
        else begin
            case (state)
                START: begin
                    done_start <= middle_in && sw_state ? 1 : done_start;
                    if (!done_start) begin
                        pixel_out <= sw_state ? (pixel_out_photobooth | pixel_out_start_instructions | pixel_out_instructions) : (pixel_out_photobooth | pixel_out_start_instructions);
                    end
                    else begin
                        start_over <= 1;
                        state <= FILTERS;
                    end
                end
                FILTERS: begin
                    case (filter_select_out)
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
                        if (filter_select_out == 3'b101) begin
                            filter_select_out <= 3'b000;
                        end else begin       
                            filter_select_out <= filter_select_out + 1;
                        end
                    end 
                    else if (left_click) begin
                        if (filter_select_out == 3'b000) begin
                            filter_select_out <= 3'b101;
                        end else begin       
                            filter_select_out = filter_select_out - 1;
                        end
                    end 
                    if (middle_in & ~old_middle) begin
                        state <= THRESHOLD;
                        filters_over <= 1;
                        use_up_arrow <= 1;
                    end else begin
                        pixel_out <= select_pixel_out | filter_screen_instructions_pixel_out;
                    end
                end
                THRESHOLD: begin
                    case (threshold_select_out)
                        2'b00: begin
                            arrow_x <= 78;
                            arrow_y <= 560;
                        end
                        2'b01: begin
                            arrow_x <= 334;
                            arrow_y <= 560;
                        end
                        2'b10: begin
                            arrow_x <= 590;
                            arrow_y <= 560;
                        end
                        2'b11: begin
                            arrow_x <= 846;
                            arrow_y <= 560;
                        end
                    endcase
                    if (right_click) begin
                        if (threshold_select_out == 2'b11) begin
                            threshold_select_out <= 2'b00;
                        end else begin       
                            threshold_select_out <= threshold_select_out + 1;
                        end
                    end 
                    if (left_click) begin
                        if (threshold_select_out == 2'b00) begin
                            threshold_select_out <= 2'b11;
                        end else begin       
                            threshold_select_out <= threshold_select_out - 1;
                        end
                    end
                    if (middle_in & ~old_middle) begin
                        threshold_over <= 1;
                        state <= SEND;
                    end else begin
                        pixel_out <= up_arrow_pixel_out;
                    end
                end
                SEND: begin
                    pixel_out <= 12'hFFF;
                end
            endcase
        end
   end 
endmodule 

`default_nettype wire
