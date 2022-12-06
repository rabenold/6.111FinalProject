`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire btnc,
  output logic [7:0] jc,
  output logic [7:0] jd,
  output logic [15:0] led
  );
    logic rst;
    assign rst = btnc;

    //clk div or counter 
   // logic sys_reset;
 // assign sys_reset = !cpu_resetn;

   logic [1:0] step_ctr_x;
   logic [1:0] step_ctr_y;
   logic q1;
   logic q2;
   logic q3;
   logic q4;
    
   reg [22:0] hz_ctr;
   reg out_10hz; 
   logic prev_hz_signal;
   always @(posedge clk_100mhz)begin
       if(rst)begin
           hz_ctr <= 0;
           out_10hz <= 0; 
                     
                     
           step_ctr_x <= 0;
           step_ctr_y <= 0;
   //        q1 <= 0;
   //        q2 <= 0;
   //        q3 <= 0;
   //        q4 <= 0;
           hz_ctr <= 0;
           prev_hz_signal <= 0;
       end else begin
           if(hz_ctr < 5000000)begin
               hz_ctr <= hz_ctr + 1;
           end else begin
               hz_ctr <= 0;
               case(sw[2])
                    1'b0: step_ctr_x <= step_ctr_x != 2'b11 ? step_ctr_x + 1 : 0; 
                    1'b1: step_ctr_x <= step_ctr_x != 2'b00 ? step_ctr_x - 1 : 2'b11; 
               endcase
               case(sw[3])
                    1'b0: step_ctr_y <= step_ctr_y != 2'b11 ? step_ctr_y + 1 : 0; 
                    1'b1: step_ctr_y <= step_ctr_y != 2'b00 ? step_ctr_y -1 : 2'b11; 
               endcase
               //out_10hz <= ~out_10hz; 

               //      prev_hz_signal = prev_hz_signal != out_10hz ? out_10hz : prev_hz_signal;
           end
       end 
    //prev_hz_signal <= out_10hz;
    //if (!prev_hz_signal 
   end 



    always_ff @(posedge clk_100mhz)begin
//   always_comb begin
       if(sw[0])begin 
           case(step_ctr_x)
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
        end 
       if(sw[1])begin 
           case(step_ctr_y)
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
//sign jc[0] = out_10hz;
//sign jc[1] = out_10hz;
//sign jc[2] = q1;
//sign jc[3] = q3;
//sign jc[4] = 1;
//sign jc[5] = 1;
//sign jc[6] = q2;
//sign jc[7] = q4;
//
//
//sign led[0] = q1;
//sign led[1] = q2;
//sign led[2] = q3;
//sign led[3] = q4;


endmodule

`default_nettype wire
