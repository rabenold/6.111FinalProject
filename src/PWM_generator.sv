`timescale 1ns / 1ps
`default_nettype none 

    /*
        *   This module is responsible for creating the PWM signal that pulses
        *   the stepper motors
        *
        *   The module runs off the FPGA's 100 MHz clock.
        *   The desired PWM frequency is 10 Hz at a 50% duty cycle.  
        *   To get this, we have a counter that goes up to 5,000,000.
        *   100 mill / 5 mill = 20, or 10 Hz @ 50% duty cycle.  
        *   
        *   We only want to pulse the motors on the rising edge of the PWM
        *   signal, so as hz_ctr is reset to 0, trigger_step goes high.
        *   Trigger_step is set low if not at a rising edge. 
        *  
        *   Trigger step is shifted into enable step, which runs off the
        *   100MHz clock, and only goes high on the positive edge of the 10 Hz
        *   clock. 
        *
        *   Clk_high indicates a positive edge of the 10Hz signal. Used in
        *   top_level as a visual confirmation that PWM is working. 
    */

module PWM_generator(
    input wire clk_100mhz,
    input wire rst,

    output logic clk_high,
    output logic enable_step
);
    logic [22:0] hz_ctr; 
    logic trigger_step;
    
    always @(posedge clk_100mhz)begin
       if(rst)begin
            hz_ctr <= 0;
            trigger_step <= 0;
            clk_high <= 0; 
        end else begin
           if(hz_ctr < 5000000)begin
               hz_ctr <= hz_ctr + 1;
               trigger_step <= 0;
           end else begin
                hz_ctr <= 0;
                trigger_step <= 1;    
                clk_high <= !clk_high;   

            end
            enable_step <= trigger_step; 
        end 
    end 
endmodule 

`default_nettype wire
