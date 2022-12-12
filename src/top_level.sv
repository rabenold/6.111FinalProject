
`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire cpu_resetn,


  output logic [7:0] jc,
  output logic [7:0] jd,
  output logic [15:0] led
  );



    logic rst;
    assign rst = !cpu_resetn;

   logic [1:0] step_x_motor;
   logic [1:0] step_y_motor;

   logic [10:0] current_horizontal_ctr; 
   logic [10:0] current_vertical_ctr;

   logic [9:0] horizontal_max;
   logic [9:0] vertical_max; 
   assign horizontal_max = 720;
   
  //  assign vertical_max = 27;
   assign vertical_max = 960; 

   reg [22:0] hz_ctr;
   reg out_10hz; 
   logic prev_hz_signal;

   logic enable_step; 
   logic led_clk_high; 


//generates the 10Hz signal used to operate stepper motors 
PWM_generator PWM_gen(
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .clk_high(led_clk_high),
        .enable_step(enable_step)
    ); 

   
logic activate_plotter;
logic [3:0] pixel_step_ctr; 
logic prev_sw_one; 


logic return_carriage; 
logic [4:0] next_line_ctr;

logic drawing_done; 

logic [2:0] system_state; 
parameter EMPTY_PIXEL = 0;
//parameter MOVE_RIGHT = 0;
parameter RETURN_CARRIAGE = 1;
parameter SHIFT_LINE = 2;
parameter MAKE_PIXEL = 3; 
parameter DRAWING_DONE = 4;

logic [1:0] pixel_direction;
logic [5:0] pixel_counter;
logic [5:0] empty_counter; 
parameter DOWN_RIGHT = 0;
parameter BACK_LEFT = 1; 
parameter UP_RIGHT = 2; 



logic reset_carriage_horizontal; 
logic [1:0] next_state; 
assign next_state = sw[2] ? 3 : 0;

logic next_line;
    always_ff @(posedge clk_100mhz)begin
        if(rst)begin pixel_step_ctr<=0; 
        step_x_motor <= 0;
        step_y_motor <=0 ; 
        activate_plotter <= 0;
        
        return_carriage <= 0; 
        next_line <= 0;
        next_line_ctr <= 0;
        system_state <= 0;
        
        reset_carriage_horizontal <= 0;


        current_horizontal_ctr <= 0;
        current_vertical_ctr <= 0;
        
        drawing_done <= 0;

        pixel_direction <= 0;
        pixel_counter <= 0;
        end else begin


        //state_done <= !sw[1];
        if(sw[1])begin
            if(!drawing_done)begin
                if(enable_step)begin
                    case(system_state)
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
                                        end 
                                    end 
                                    BACK_LEFT: begin
                                        if(pixel_counter < 9)begin
                                            step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
                                            pixel_counter <= pixel_counter + 1;
                                        end else begin
                                            pixel_direction <= 2; 
                                            pixel_counter <= 0;
                                        end 
                                    end 

                                    UP_RIGHT: begin
                                        if(pixel_counter < 9)begin
                                            pixel_counter <= pixel_counter + 1;
                                            step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                            step_y_motor <= step_y_motor != 2'b00 ? step_y_motor - 1 : 2'b11;
                                            current_horizontal_ctr <= current_horizontal_ctr + 1;
                                        end else begin
                                            pixel_direction <= 0; 
                                            pixel_counter <= 0;
                                            //trigger ready to receive here! 
                                            system_state <= next_state;  
                                        end 
                                    end 
                                endcase 
                            end else begin
                                reset_carriage_horizontal <= 1; 
                                system_state <= RETURN_CARRIAGE; 
                            end
                        end
                        
                        EMPTY_PIXEL: begin
                            if(current_horizontal_ctr < horizontal_max - 9 && !reset_carriage_horizontal) begin
                                if(empty_counter < 9)begin 
                                    step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                    current_horizontal_ctr <= current_horizontal_ctr + 1;
                                    empty_counter <= empty_counter + 1;
                                end else begin
                                    empty_counter <= 0;
                                    system_state <= next_state;
                                    //trigger ready to receive here!  
                                end 
                            end else begin
                                system_state <= RETURN_CARRIAGE;
                                reset_carriage_horizontal <= 1; 
                            end 
                        end
                        RETURN_CARRIAGE: begin
                            

                            //check this val - gotta make sure nums correct 
                            if(current_vertical_ctr >= vertical_max) system_state <= DRAWING_DONE; 
                            else if(reset_carriage_horizontal && current_horizontal_ctr > 0)begin
                                step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
                                current_horizontal_ctr <= current_horizontal_ctr - 1;
                            end 
                            else system_state <= SHIFT_LINE; 
                        end 
                    
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
                                //state_done <= 1; 
                            end 
                        end 
                        DRAWING_DONE: drawing_done <= 1; 




                    endcase
                    end
                end 
            end
        end 
    end 


assign led[2:0] = system_state;
assign led[10] = led_clk_high; 

assign led[4:3] = step_x_motor;
assign led[6:5] = step_y_motor; 

assign led[8] = reset_carriage_horizontal;
assign led[9] = current_vertical_ctr == vertical_max;
assign led[15] = drawing_done;

//assign led[12:2] = current_horizontal_ctr; 

//assign led[13:3] = current_vertical_ctr; 


//assign led[15] = drawing_done; 
//assign led[14] = reset_carriage_horizontal; 
//assign led[14] = state_done; 
//assign led[15] = led_clk_high; 





// This state machine governs stepper movement according to the inputs in
// step_x_motor and step_y_motor. Only activates on the positive edge of the
// 10Hz clock

//   /////////// horizontal movement /////////
 always_ff @(posedge clk_100mhz)begin
       if(enable_step)begin
               case(step_x_motor)
                    2'b00: begin
                        jc[1] = 1;
                        jc[5] = 0;
                        jc[2] = 1;
                        jc[6] = 0;
                        end 
                    2'b01: begin
                        jc[1] = 0;
                        jc[5] = 1;
                        jc[2] = 1;
                        jc[6] = 0;
                        end 
                    2'b10: begin
                        jc[1] = 0;
                        jc[5] = 1;
                        jc[2] = 0;
                        jc[6] = 1;
                        end 
                    2'b11: begin
                        jc[1] = 1;
                        jc[5] = 0;
                        jc[2] = 0;
                        jc[6] = 1; 
                        end 
               endcase
       ////////////////////////////////////////

       /////////// vertical movement /////////
               case(step_y_motor)
                    2'b00: begin
                        jd[1] = 1;
                        jd[5] = 0;
                        jd[2] = 1;
                        jd[6] = 0;
                        end 
                    2'b01: begin
                        jd[1] = 0;
                        jd[5] = 1;
                        jd[2] = 1;
                        jd[6] = 0;
                        end 
                    2'b10: begin
                        jd[1] = 0;
                        jd[5] = 1;
                        jd[2] = 0;
                        jd[6] = 1;
                        end 
                    2'b11: begin
                        jd[1] = 1;
                        jd[5] = 0;
                        jd[2] = 0;
                        jd[6] = 1; 
                        end 
                endcase
    end
end 
    //   ////////////////////////////////////////




endmodule

`default_nettype wire 
