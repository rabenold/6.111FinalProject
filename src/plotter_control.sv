`timescale 1ns / 1ps
`default_nettype none

module plotter_control(
  input wire clk_65mhz,
  input wire [15:0] sw,
  input wire cpu_resetn,
  input wire pixel_value_in,
  input wire enable_plotter,

  output logic hz_clk,
  output logic ready_next_pixel,
  output logic [3:0] jc_out,
  output logic [3:0] jd_out,
  output logic [15:0] led_out,
  output logic drawing_done
);

   logic rst;
   assign rst = !cpu_resetn;

//counters for stepper motor state machines   
   logic [1:0] step_x_motor;
   logic [1:0] step_y_motor;

//counters for positioning    
   logic [10:0] current_horizontal_ctr; 
   logic [10:0] current_vertical_ctr;

//setting drawing boundaries
   logic [9:0] horizontal_max;
   logic [9:0] vertical_max; 


   assign horizontal_max = 720;
   assign vertical_max = 960;
//   assign horizontal_max = 72;//0;
//   assign vertical_max = 96;//0; 

   logic enable_step;
   logic led_clk_high; 
   assign hz_clk = led_clk_high;
//generates the 40Hz signal used to operate stepper motors 
    PWM_generator PWM_gen(
            .clk_65mhz(clk_65mhz),
            .rst(rst),
            .clk_high(led_clk_high),
            .enable_step(enable_step)
        ); 

//initializing plotter counters,  
    logic activate_plotter;
    logic [3:0] pixel_step_ctr; 
    logic return_carriage; 
    logic [4:0] next_line_ctr;
    logic [5:0] empty_counter; 
    logic reset_carriage_horizontal; 
    logic [1:0] next_state; 

//state machine governing plotter drawing functions 
    logic [2:0] system_state; 
    parameter EMPTY_PIXEL = 0;
    parameter RETURN_CARRIAGE = 1;
    parameter SHIFT_LINE = 2;
    parameter MAKE_PIXEL = 3; 
    parameter DRAWING_DONE = 4;

//variables used to draw a filled pixel
    logic [1:0] pixel_direction;
    logic [5:0] pixel_counter;
    parameter DOWN_RIGHT = 0;
    parameter BACK_LEFT = 1; 
    parameter UP_RIGHT = 2; 
    

//setting drawing state based on input pixel value
    assign next_state = pixel_value_in ? 3 : 0;

        always_ff @(posedge clk_65mhz)begin
            if(rst)begin pixel_step_ctr<=0; 
                step_x_motor <= 0;
                step_y_motor <=0 ; 
                activate_plotter <= 0;
                
                return_carriage <= 0; 
                next_line_ctr <= 0;
                system_state <= 0;
                
                reset_carriage_horizontal <= 0;

                current_horizontal_ctr <= 0;
                current_vertical_ctr <= 0;
                
                drawing_done <= 0;

                pixel_direction <= 0;
                pixel_counter <= 0;

                ready_next_pixel <= 0;
            end else begin


            //can temporarily pause plotter by turning off sw[1]     
        if(enable_plotter)begin
            if(sw[1])begin
                if(!drawing_done)begin
                    if(enable_step)begin
                        case(system_state)
                       
                            //State to represent a filled-in pixel 
                            MAKE_PIXEL: begin
                                if(current_horizontal_ctr < horizontal_max - 9 && !reset_carriage_horizontal)begin 
                                    case(pixel_direction)
                                        DOWN_RIGHT: begin
                                            if(pixel_counter < 9)begin
                                                step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                                step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
                                                pixel_counter <= pixel_counter + 1;
                                            end else begin
                                                pixel_direction <= 1; 
                                                pixel_counter <= 0;
                                                ready_next_pixel <= 0;
                                            end 
                                        end 
                                        BACK_LEFT: begin
                                            if(pixel_counter < 9)begin
                                                step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
                                                pixel_counter <= pixel_counter + 1;
                                            end else begin
                                                pixel_direction <= 2; 
                                                pixel_counter <= 0;
                                                ready_next_pixel <= 0;
                                            end 
                                        end 

                                        UP_RIGHT: begin
                                            if(pixel_counter < 9)begin
                                                pixel_counter <= pixel_counter + 1;
                                                step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                                step_y_motor <= step_y_motor != 2'b00 ? step_y_motor - 1 : 2'b11;
                                                current_horizontal_ctr <= current_horizontal_ctr + 1;
                                                ready_next_pixel <= 0;
                                            end else begin
                                                pixel_direction <= 0; 
                                                pixel_counter <= 0;
                                                system_state <= next_state;  
                                                
                                                //trigger ready to receive next pixel here!
                                                ready_next_pixel <= 1;
                                            end 
                                        end 
                                        default: pixel_direction <= 0;
                                    endcase 
                                end else begin
                                    reset_carriage_horizontal <= 1; 
                                    system_state <= RETURN_CARRIAGE; 
                                    ready_next_pixel <= 0;
                                end
                            end
                            
                            //State to represent an empty pixel
                            EMPTY_PIXEL: begin
                                if(current_horizontal_ctr < horizontal_max - 9 && !reset_carriage_horizontal) begin
                                    if(empty_counter < 9)begin 
                                        step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                        current_horizontal_ctr <= current_horizontal_ctr + 1;
                                        empty_counter <= empty_counter + 1;
                                        ready_next_pixel <= 0;
                                    end else begin
                                        empty_counter <= 0;
                                        system_state <= next_state;
                                        //trigger ready to receive here!
                                        ready_next_pixel <= 1;
                                    end 
                                end else begin
                                    system_state <= RETURN_CARRIAGE;
                                    reset_carriage_horizontal <= 1; 
                                    ready_next_pixel <= 0;
                                end 
                            end


                            //Once the carriage reaches the right boundary of
                            //the frame, reset it before continuing 
                            RETURN_CARRIAGE: begin
                                
                                //Here - if at bottom of frame, end!
                                if(current_vertical_ctr >= vertical_max) system_state <= DRAWING_DONE; 
                                
                                //Resetting carriage to the left side of the
                                //frame 
                                else if(reset_carriage_horizontal && current_horizontal_ctr > 0)begin
                                    step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
                                    current_horizontal_ctr <= current_horizontal_ctr - 1;
                                end 
                                
                                //After carriage reset, shift to the next line
                                else system_state <= SHIFT_LINE; 
                                ready_next_pixel <= 0;
                            end 
                       
                            //In this state, shift the carriage down to the
                            //next line 
                            SHIFT_LINE: begin
                                if(next_line_ctr < 9)begin            
                                    step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 2'b00; 
                                    current_vertical_ctr <= current_vertical_ctr + 1;
                                    next_line_ctr <= next_line_ctr + 1;
                                end 
                                else begin
                                    system_state <=  next_state; 
                                    reset_carriage_horizontal <= 0;
                                    next_line_ctr <= 0;
                                    ready_next_pixel <= 0;
                                end 
                            end

                            //Once drawing has completed
                            DRAWING_DONE: drawing_done <= 1; 
                            
                            default: system_state <= !drawing_done ? next_state : DRAWING_DONE;

                        endcase
                        end
                    end 
                end
            end 
        end
    end 


    assign led_out[2:0] = system_state;
    assign led_out[10] = led_clk_high; 

    assign led_out[4:3] = step_x_motor;
    assign led_out[6:5] = step_y_motor; 

    assign led_out[8] = reset_carriage_horizontal;
    assign led_out[9] = current_vertical_ctr == vertical_max;
    assign led_out[15] = drawing_done;



    // This state machine governs stepper movement according to the inputs in
    // step_x_motor and step_y_motor. Only activates on the positive edge of the
    // 10Hz clock

    //   /////////// horizontal movement /////////
     always_ff @(posedge clk_65mhz)begin
           if(enable_step)begin
                   case(step_x_motor)
                        2'b00: begin
                            jc_out[0] = 1;
                            jc_out[1] = 0;
                            jc_out[2] = 1;
                            jc_out[3] = 0;
                            end 
                        2'b01: begin
                            jc_out[0] = 0;
                            jc_out[1] = 1;
                            jc_out[2] = 1;
                            jc_out[3] = 0;
                            end 
                        2'b10: begin
                            jc_out[0] = 0;
                            jc_out[1] = 1;
                            jc_out[2] = 0;
                            jc_out[3] = 1;
                            end 
                        2'b11: begin
                            jc_out[0] = 1;
                            jc_out[1] = 0;
                            jc_out[2] = 0;
                            jc_out[3] = 1; 
                            end 
                   endcase
           ////////////////////////////////////////

           /////////// vertical movement /////////
                   case(step_y_motor)
                        2'b00: begin
                            jd_out[0] = 1;
                            jd_out[1] = 0;
                            jd_out[2] = 1;
                            jd_out[3] = 0;
                            end 
                        2'b01: begin
                            jd_out[0] = 0;
                            jd_out[1] = 1;
                            jd_out[2] = 1;
                            jd_out[3] = 0;
                            end 
                        2'b10: begin
                            jd_out[0] = 0;
                            jd_out[1] = 1;
                            jd_out[2] = 0;
                            jd_out[3] = 1;
                            end 
                        2'b11: begin
                            jd_out[0] = 1;
                            jd_out[1] = 0;
                            jd_out[2] = 0;
                            jd_out[3] = 1; 
                            end 
                    endcase
        end
    end 
        //   ////////////////////////////////////////




endmodule

`default_nettype wire 
