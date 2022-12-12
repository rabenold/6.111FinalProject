
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
   assign vertical_max = 960; 

   reg [22:0] hz_ctr;
   reg out_10hz; 
   logic prev_hz_signal;






//   logic [3:0] jc_out;
//   logic [3:0] jd_out;
//   logic [3:0] prev_jc_out;
//   logic [3:0] prev_jd_out;
//
//   logic trigger_step;
//
//   logic prev_hz_ctr;
//   logic pwm_pulse;
   


    /*
        *   This block is responsible for creating the PWM signal that pulses
        *   the stepper motors
        *
        *   The block runs off the FPGA's 100 MHz clock.
        *   The desired PWM frequency is 10 Hz at a 50% duty cycle.  
        *   To do this, we have a counter that goes up to 5,000,000. This
        *   essentially divides the 100 MHz clock. 
        *   
        *   We only want to pulse the motors on the rising edge of the PWM
        *   signal, so as hz_ctr is reset to 0, we send trigger_step high.
        *   Trigger_step is low if we aren't at a rising edge. 
        *   
        *   Outside of that, we shift trigger step into enable step. If enable
        *   step is high, we know that we can pulse the motor.
    */

//   always @(posedge clk_100mhz)begin
//      if(rst)begin
//           hz_ctr <= 0;
//           enable_step <= 0;
//           trigger_step <= 0;
//      end else begin
//           if(hz_ctr < 5000000)begin
//              hz_ctr <= hz_ctr + 1;
//              trigger_step <= 0;
//          end else begin
//               hz_ctr <= 0;
//               trigger_step <= 1;    
//           end 
//           enable_step <= trigger_step; 
//       end 
//   end 
//

logic enable_step; 
logic led_clk_high; 


//generates the 10Hz signal used to operate stepper motors 
PWM_generator PWM_gen(
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .clk_high(led_clk_high),
        .enable_step(enable_step)
    ); 

//assign led[15] = sw[15]; 
   
logic activate_plotter;
logic state_done; 
logic [3:0] pixel_step_ctr; 
logic prev_sw_one; 


logic return_carriage; 
logic [4:0] next_line_ctr;

parameter MOVE_RIGHT = 0;
parameter RETURN_CARRIAGE = 1;
parameter SHIFT_LINE = 2;
parameter MAKE_PIXEL = 3; 
logic [1:0] system_state; 


logic [1:0] pixel_direction;
logic [5:0] pixel_counter; 
parameter DOWN_RIGHT = 0;
parameter BACK_LEFT = 1; 
parameter UP_RIGHT = 2; 




logic [1:0] next_state; 
assign next_state = sw[2] ? 3 : 0;

logic next_line;
    always_ff @(posedge clk_100mhz)begin
        if(rst)begin pixel_step_ctr<=0; 
        step_x_motor <= 0;
        step_y_motor <=0 ; 
        activate_plotter <= 0;
        state_done <= 0;
        return_carriage <= 0; 
        next_line <= 0;
        next_line_ctr <= 0;
        system_state <= 0;
        


        current_horizontal_ctr <= 0;
        current_vertical_ctr <= 0;
        
        pixel_direction <= 0;
        pixel_counter <= 0;
        end
        state_done <= !sw[1];
        if(sw[1])begin
        if(!state_done)begin
            if(enable_step)begin
                case(system_state)
                    MAKE_PIXEL: begin
                        case(pixel_direction)
                            DOWN_RIGHT: begin
                                if(pixel_counter < 27)begin
                                    step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                    step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
                                    pixel_counter <= pixel_counter + 1;
                                end else begin
                                    pixel_direction <= 1; 
                                    pixel_counter <= 0;
                                end 
                            end 
                            BACK_LEFT: begin
                                if(pixel_counter < 27)begin
                                    step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
                                    pixel_counter <= pixel_counter + 1;
                                end else begin
                                    pixel_direction <= 2; 
                                    pixel_counter <= 0;
                                end 
                            end 

                            UP_RIGHT: begin
                                if(pixel_counter < 27)begin
                                    pixel_counter <= pixel_counter + 1;
                                    step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                                    step_y_motor <= step_y_motor != 2'b00 ? step_y_motor - 1 : 2'b11;
                                end else begin
                                    pixel_direction <= 0; 
                                    pixel_counter <= 0;
                                    system_state <= next_state;  
                                end 
                            end 
                            endcase 





                            end
                    MOVE_RIGHT: begin
                        if(current_horizontal_ctr < horizontal_max) begin
                            step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
                            current_horizontal_ctr <= current_horizontal_ctr + 1;
                            return_carriage <= 0;
                        end 
                        else system_state <= RETURN_CARRIAGE;
                    end 
                    RETURN_CARRIAGE: begin
                        if(current_horizontal_ctr > 0)begin
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
                            next_line_ctr <= 0;
                            //state_done <= 1; 
                        end 
                    end 
                endcase
                end 
            end
        end 
    end 

assign led[1:0] = system_state;
assign led[12:2] = current_horizontal_ctr; 
assign led[14] = state_done; 
assign led[15] = led_clk_high; 
//               if(current_horizontal_ctr < horizontal_max && !return_carriage && !next_line) begin
//                   step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                   current_horizontal_ctr <= current_horizontal_ctr + 1;
//                   return_carriage <= 0;
//               end 
//               else return_carriage <= 1;
//           end


//               if(return_carriage && current_horizontal_ctr > 0 && !next_line)begin
//                   step_x_motor <= step_x_motor !=2'b00 ? step_x_motor - 1 : 2'b11;
//                   current_horizontal_ctr <= current_horizontal_ctr - 1;
//              
//               end else begin return_carriage <= 0;
//                   next_line <= 1;
//               end 
//           end 
///
///
///               if(next_line && next_line_ctr <2)begin
///                  next_line_ctr <= next_line_ctr + 1;
///                  step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
///               end else begin
///                   state_done <= 0;
///                   next_line_ctr <= 0;
///                   next_line <= 0;
///       
///               end 
///           end 
                //               case(pixel_step_ctr)
//                   3'b000 : begin
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
//                   end
//                   
//                   3'b001 : begin 
// //                     step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
// //                     step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
// //                     pixel_step_ctr <= pixel_step_ctr + 1;
//                   end 
//                   3'b010 : begin 
//   //                   step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
//   //                   step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//   //                   pixel_step_ctr <= pixel_step_ctr + 1;
//                   end 
//                   3'b011 : begin 
//  //                    step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
//  //                    pixel_step_ctr <= pixel_step_ctr + 1;
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
//                   end 
//                   3'b100 : begin 
// //                     step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
// //                     pixel_step_ctr <= pixel_step_ctr + 1;
//                   end 
//                   3'b101 : begin 
////                      step_x_motor <= step_x_motor != 2'b00 ? step_x_motor - 1 : 2'b11;
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
////                      pixel_step_ctr <= pixel_step_ctr + 1;
//                   end 
//                   3'b110 : begin 
///                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= pixel_step_ctr + 1;
///                       step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
///                       pixel_step_ctr <= pixel_step_ctr + 1;
//                   end
//                   3'b111 : begin 
//                       step_x_motor <= step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                       //step_y_motor <= step_y_motor != 2'b11 ? step_y_motor + 1 : 0;
//                       pixel_step_ctr <= 0;
//                       activate_plotter <= 0; 
//                       end 
//               endcase



// assign led[13] = activate_plotter;
// assign led[8:7] = step_y_motor;
// assign led[5:4] = step_x_motor;
// assign led[0] = next_line; 
// assign led[1] = return_carriage;

//assign led[2:0] = pixel_step_ctr;

//
//   logic move_x;
//   logic move_y; 
//   
//
//   
///fix this timing stuff
//
//
//   /////////// horizontal movement /////////
 always_ff @(posedge clk_100mhz)begin
       if(enable_step)begin
      //     if(move_x)begin
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
    //       end
       ////////////////////////////////////////

       /////////// vertical movement /////////
 //          if(move_y)begin
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
   //        end        
    end
end 
           //   ////////////////////////////////////////
//   end 
//nd 
//
///gonna have logic jc_out
//
///assigning jc pins
//
//   logic enable_return_x;
//   logic enable_return_y; 
//
//   logic next_state; 
//   logic [1:0] empty_pixel_counter; 
//   
//   logic [3:0] motor_state; 
//
//   parameter WAITING =  3'b000;
//   
//   parameter DRAW_PIXEL = 3'b001;
//   parameter EMPTY_PIXEL = 3'b010;
//
//   parameter NEXT_LINE = 3'b011;
//
//   parameter RETURN_X = 3'b100;
//   parameter RETURN_Y = 3'b101;
//
///all of this needs to happen on the 10hz pulse 
//
//   always_ff @(posedge clk_100mhz)begin
//       if(enable_pulse)begin 
//           case(motor_state) 
//               WAITING: begin
//                   move_x = 0;
//                   move_y = 0;
//               end 
//               DRAW_PIXEL: 
//
//                   
//               EMPTY_PIXEL: begin
//                   //move x stepper by three 
//                   move_x = 1; 
//                   case(empty_pixel_counter)
//                       2'b00: begin step_x_motor = step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                           empty_pixel_counter = empty_pixel_counter + 1; 
//                           end 
//                       2'b01: begin step_x_motor = step_x_motor != 2'b11 ? step_x_motor + 1 : 0;
//                           empty_pixel_counter = empty_pixel_counter + 1; 
//                           end 
//                       2'b10: begin step_x_motor = step_x_motor != 2'b11 ? step_x_motor + 1: 0; 
//                           empty_pixel_counter = 2'b00;
//                           move_x = 0;
//                           motor_state = next_state; 
//                           end 
//                           endcase
//                       end 
//
//
//
//               NEXT_LINE: begin
//                   //this involves stepping y three times 
//
//
//
//                   end
//               RETURN_X: begin
//                                   
//
//
//
//
//
//                   end 
//               RETURN_Y: begin
//                       
//
//
//
//                   end 
//               default: begin
//
//
//               end 
//
//
//           endcase 
//       end
//       //else nothign 
//   end
//
//
//
//
//lways_comb begin
//   //horizontal motor phase 1 
//   jc[1] = jc_out[0];
//   jc[5] = jc_out[1];
//   
//   //horizontal motor phase 2
//   jc[2] = jc_out[2];
//   jc[6] = jc_out[3];
//
//   //vertial motor phase 1
//   jd[1] = jd_out[0];
//   jd[5] = jd_out[1];
//
//   //vertical motor phase 2
//   jd[2] = jd_out[2];
//   jd[6] = jd_out[3];
//
//nd 


// assign led[13:12] = step_ctr_y;
// assign led[6:5] = step_ctr_x;
// a
// assign led[15] = make_pixel;
// assign led[3:0] = int_pix_ctr;
endmodule

`default_nettype wire 
