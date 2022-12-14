`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)
  input wire btnl,
  input wire btnr,
  input wire cpu_resetn,


  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camerafull_pixel_pipe
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,

///// PLOTTER PMOD
  output logic [7:0] jc,
  output logic [7:0] jd

  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = !cpu_resetn; //just done to make sys_rst more obvious
  //assign led = sw; //switches drive LED (change if you want)

  /* Video Pipeline */
  logic clk_65mhz; //65 MHz clock line

  //vga module generation signals:
  logic [10:0] hcount;    // pixel on current line
  logic [10:0] hcount_pipe [6:0];

  logic [9:0] vcount;     // line number
  logic [9:0] vcount_pipe [6:0];

  logic hsync, vsync, blank; //control signals for vga
  logic blank_pipe [6:0];
  logic hsync_pipe [7:0];
  logic vsync_pipe [7:0];
  logic hsync_t, vsync_t, blank_t; //control signals out of transform

  //camera module: (see datasheet)
  logic cam_clk_buff, cam_clk_in; //returning camera clock
  logic vsync_buff, vsync_in; //vsync signals from camera
  logic href_buff, href_in; //href signals from camera
  logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
  logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
  logic valid_pixel; //indicates valid pixel from camera
  logic frame_done; //indicates completion of frame from camera

  //rotate module:
  logic valid_pixel_rotate;  //indicates valid rotated pixel
  logic [15:0] pixel_rotate; //rotated 565 rotate pixel
  logic [16:0] pixel_addr_in; //address of rotated pixel in 240X320 memory

  //values  of frame buffer:
  logic [16:0] pixel_addr_out; //
  logic [15:0] frame_buff; //output of scale module

  // output of scale module
  logic [15:0] full_pixel;//mirrored and scaled 565 pixel
  logic [15:0] full_pixel_pipe [2:0];
  //output of rgb to ycrcb conversion:
  logic [9:0] y, cr, cb; //ycrcb conversion of full pixel

  //output of threshold module:
  logic mask; //Whether or not thresholded pixel is 1 or 0
  logic [3:0] sel_channel; //selected channels four bit information intensity
  //sel_channel could contain any of the six color channels depend on selection

  //Center of Mass variables
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...
  //using x_com_calc and y_com_calc values

  //output of image sprite
  //Output of sprite that should be centered on Center of Mass (x_com, y_com):
  logic [11:0] com_sprite_pixel;

  //har value hot when hcount,vcount== (x_com, y_com)
  logic crosshair;

  //vga_mux output:
  logic [11:0] mux_pixel; //final 12 bit information from vga multiplexer
  //goes right into RGB of output for video render

  logic [4:0] gray_pixel;


  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_65mhz) begin
    cam_clk_buff <= jb[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= jb[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= jb[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= ja; //sync pixels
    pixel_in <= pixel_buff;
  end

  //Controls and Processes Camera information


  //NEW FOR LAB 04B (START)----------------------------------------------
  logic [15:0] pixel_data_rec; // pixel data from recovery module
  logic [10:0] hcount_rec; //hcount from recovery module
  logic [9:0] vcount_rec; //vcount from recovery module
  logic  data_valid_rec; //single-cycle (65 MHz) valid data from recovery module

  logic [10:0] hcount_f0;  //hcount from filter modules
  logic [9:0] vcount_f0; //vcount from filter modules
  logic [15:0] pixel_data_f0; //pixel data from filter modules
  logic data_valid_f0; //valid signals for filter modules

  logic [10:0] hcount_f [5:0];  //hcount from filter modules
  logic [9:0] vcount_f [5:0]; //vcount from filter modules
  logic [15:0] pixel_data_f [5:0]; //pixel data from filter modules
  logic data_valid_f [5:0]; //valid signals for filter modules

  logic [10:0] hcount_fmux; //hcount from filter mux
  logic [9:0]  vcount_fmux; //vcount from filter mux
  logic [15:0] pixel_data_fmux; //pixel data from filter mux
  logic data_valid_fmux; //data valid from filter mux

  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz
  
  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank));

   camera camera_m(
    //signal generate to camera:
    .clk_65mhz(clk_65mhz),
    .jbclk(jbclk),
    .jblock(jblock),
    //returned information from camera:
    .cam_clk_in(cam_clk_in),
    .vsync_in(vsync_in),
    .href_in(href_in),
    .pixel_in(pixel_in),
    //output framed info from camera for processing:
    .pixel_out(cam_pixel),
    .pixel_valid_out(valid_pixel),
    .frame_done_out(frame_done));

  rotate rotate_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .valid_pixel_out(valid_pixel_rotate),
    .pixel_out(pixel_rotate),
    .frame_done_in(frame_done),
    .pixel_addr_in(pixel_addr_in));
  //grayscaling directly from camera 

  // ----------------- converting to grayscale here -------
  logic [7:0] red,green,blue;
  assign red = {pixel_rotate[15:11],2'b0};
  assign green = {pixel_rotate[10:5],1'b0};
  assign blue = {pixel_rotate[4:0],2'b0};
  logic [6:0] pix_data;
  assign pix_data = (red>>2)+(red>>5)+(red>>6)+(green>>1)+(green>>4)+(green>>5)+(blue>>3)+(blue>>5);




 //------------------ writing grayscaled pix into BRAM ------
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(11),
    .RAM_DEPTH(320*240))
    frame_buffer (
    //Write Side (16.67MHz)
    .addra(pixel_addr_in),
    .clka(cam_clk_in),
    .wea(valid_pixel_rotate && !sw[15]),
    .dina({pix_data[6:2],pix_data[6:1],pix_data[6:2]}),             
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side (65 MHz)
    .addrb(pixel_addr_out),
    .dinb(16'b0),
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(frame_buff)
  );

//pipeline hcount vcount? 

  recover recover_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(pix_data),
    .frame_done_in(frame_done),

    .system_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .pixel_out(pixel_data_rec),
    .data_valid_out(data_valid_rec),
    .hcount_out(hcount_rec),
    .vcount_out(vcount_rec));

  logic thresh_pixel_out; 

 threshold threshold(
     .pixel_in(frame_buff),
     .thresh_mux(1),
     .pixel_out(thresh_pixel_out)
 );


 logic pixel_avg_valid;
 logic pixel_avg_data_out;
 logic [10:0] pix_avg_hcount;
 logic [9:0] pix_avg_vcount;

 pixelAverage pixelAverage(
   .clk_in(clk_65mhz),
   .rst_in(sys_rst),
   .data_valid_in(valid_pixel_rotate && !sw[15]),
   .pixel_data_in(thresh_pixel_out),
   .hcount_in(hcount_rec),
   .vcount_in(vcount_rec),
   .data_valid_out(pixel_avg_valid),
   .pixel_data_out(pixel_avg_data_out),
   .hcount_out(pix_avg_hcount), 
   .vcount_out(pix_avg_vcount) 
 ); 
  
    //addr rotate2 

  logic [10:0] pix_avg_hcount_prev;
  logic [9:0] pix_avg_vcount_prev;

  logic [10:0] pix_avg_hcount_enter;
  logic [9:0] pix_avg_vcount_enter;

  logic[1:0] vcount_mod;
  logic[1:0] hcount_mod;
  logic write_avg;
  always_ff @(posedge clk_65mhz)begin
    if(pixel_avg_valid) begin
      if(pix_avg_hcount ==0 && pix_avg_hcount==0)begin
        vcount_mod <=2;
        hcount_mod <=2;
        pix_avg_hcount_enter <=0;
        pix_avg_vcount_enter <=0;
        write_avg <= 0;
      end else begin
        pix_avg_hcount_prev <= pix_avg_hcount;
        pix_avg_vcount_prev <= pix_avg_vcount;
        
        if(pix_avg_vcount_prev!=pix_avg_vcount) begin
          if(vcount_mod==0)begin
            vcount_mod <= 2;
          end else begin
            vcount_mod <= vcount_mod - 2;
          end
        end

        if(pix_avg_hcount_prev!=pix_avg_hcount) begin
          if(hcount_mod==0)begin
            hcount_mod <= 2;
          end else begin
            hcount_mod <= hcount_mod - 2;
          end
        end

        if(vcount_mod==1&&hcount_mod==1)begin
          if(pix_avg_hcount_enter==79)begin
            pix_avg_hcount_enter <=0;
            pix_avg_vcount_enter <=pix_avg_vcount_enter+1;
          end else begin
            pix_avg_hcount_enter <=pix_avg_hcount_enter+1;
          end
          write_avg <= 1;
        end else begin 
          write_avg <= 0;
        end

      end
    end
  end

 logic avg_bram_in;
 logic [16:0] avg_addr;
 logic avg_write_bram;
 rotate2_small rotateAvg(
   .clk_in(clk_65mhz),
   .hcount_in(pix_avg_hcount_enter),
   .vcount_in(pix_avg_vcount_enter),
   .data_valid_in(write_avg),
   .pixel_in(pixel_avg_data_out),
   .pixel_out(avg_bram_in),
   .pixel_addr_out(avg_addr),
   .data_valid_out(avg_write_bram)
 );

    logic black_white_out; 

    logic [16:0] small_pix_addr_out;
    logic[16:0] small_pix_addr_out_other;

    always_ff @(posedge clk_65mhz)begin
    small_pix_addr_out = (pix_avg_hcount/3*80) + pix_avg_vcount/3;
    if(hcount_pipe[0]==600 && vcount_pipe[0]==250)begin
      small_pix_addr_out_other <= 8480;
    end else if (hcount_pipe[0] >= 600 && hcount_pipe[0] < 680 && vcount_pipe[0] >= 250 && vcount_pipe[0] < 356)begin
      small_pix_addr_out_other <= small_pix_addr_out_other - 1;
    end
  end

xilinx_true_dual_port_read_first_2_clock_ram #(
   .RAM_WIDTH(1),
   .RAM_DEPTH(106*80))
   black_white (
   //Write Side (16.67MHz)
   .addra(small_pix_addr_out),
   .clka(clk_65mhz),
   .wea(1'b1),
   .dina(thresh_pixel_out),             
   .ena(1'b1),
   .regcea(1'b1),
   .rsta(sys_rst),
   .douta(),
   //Read Side (65 MHz)
   .addrb(small_pix_addr_out_other),
   .dinb(16'b0),
   .clkb(clk_65mhz),
   .web(1'b0),
   .enb(1'b1),
   .rstb(sys_rst),
   .regceb(1'b1),
   .doutb(black_white_out)
 );

    assign led[4] = black_white_out;


  // UPDATE PIPELINES
  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    for (int i=1; i<7; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
    end

    vcount_pipe[0] <= vcount;
    for (int i=1; i<7; i = i+1)begin
      vcount_pipe[i] <= vcount_pipe[i-1];
    end


    full_pixel_pipe[0] <= full_pixel;
    for (int i=1; i<3; i = i+1)begin
      full_pixel_pipe[i] <= full_pixel_pipe[i-1];
    end

    blank_pipe[0] <= blank;
    for (int i=1; i<7; i = i+1)begin
      blank_pipe[i] <= blank_pipe[i-1];
    end

    hsync_pipe[0] <= hsync;
    for (int i=1; i<8; i = i+1)begin
      hsync_pipe[i] <= hsync_pipe[i-1];
    end

    vsync_pipe[0] <= vsync;
    for (int i=1; i<8; i = i+1)begin
      vsync_pipe[i] <= vsync_pipe[i-1];
    end
  end


//displaying averaged img for testing 
  // mirror mirror_s(
  //   .clk_in(clk_65mhz),
  //   .mirror_in(1'b0),
  //   .scale_in(2'b00),
  //   .hcount_in(hcount_pipe[2]-400), //
  //   .vcount_in(vcount_pipe[2]-450),
  //   .pixel_addr_out(small_pix_addr_out)
  // );

 logic small_full_pixel;

  scale scale_s(
    .scale_in(2'b00),
    .hcount_in(hcount_pipe[2]-400), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount_pipe[2]-450), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(frame_buff),
    .cam_out(small_full_pixel)
    );

   
    logic [3:0] bw_pix_out; 
    always_comb begin
      if (hcount_pipe[0] >= 600 && hcount_pipe[0] < 680 && vcount_pipe[0] >= 250 && vcount_pipe[0] < 356)begin
        bw_pix_out = black_white_out ? 4'b1111 : 4'b0000;
      end else begin
        bw_pix_out = 0;
      end
    end


//initial camera image 
  mirror mirror_m(
    .clk_in(clk_65mhz),
    .mirror_in(1'b0),
    .scale_in(2'b00),
    .hcount_in(hcount_pipe[2]-200), //
    .vcount_in(vcount_pipe[2]-250),
    .pixel_addr_out(pixel_addr_out)
  );

  scale scale_m(
    .scale_in(2'b00),
    .hcount_in(hcount_pipe[2]-200), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount_pipe[2]-250), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(frame_buff),
    .cam_out(full_pixel)
    );

  logic pixel_value_in; 
  logic ready_next_pixel;

  logic [3:0] jc_out;
  logic [3:0] jd_out;
  logic [15:0] led_out;
  logic hz_clk;
  logic drawing_done;
  assign pixel_value_in = sw[2]; 

 /* logic [3:0] next_pixel_value; 
*/

  logic enable_plotter;
  assign enable_plotter = sw[14];

  plotter_control plotter_control( 
    .clk_65mhz(clk_65mhz),
    .sw(sw),
    .cpu_resetn(cpu_resetn),
    .pixel_value_in(pixel_value_in),
    .enable_plotter(enable_plotter), 

    .ready_next_pixel(ready_next_pixel),  
    .hz_clk(hz_clk), 
    .jc_out(jc_out),
    .jd_out(jd_out),
    .led_out(led_out),
    .drawing_done(drawing_done)
  );

assign led[0] = ready_next_pixel; 




//x stepper PMODs 
assign jc[1] = jc_out[0];
assign jc[5] = jc_out[1];
assign jc[2] = jc_out[2];
assign jc[6] = jc_out[3];

//y stepper PMODs
assign jd[1] = jd_out[0];
assign jd[5] = jd_out[1];
assign jd[2] = jd_out[2];
assign jd[6] = jd_out[3];

assign led[15] = hz_clk;
//assign led[0] = drawing_done;
assign led[2] = enable_plotter; 

// 
// use this logic for writing to vga outside of state 1

  assign mux_pixel = {full_pixel[15:12],full_pixel[10:7],full_pixel[4:1]};
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank_pipe[3]?(mux_pixel[3:0]|bw_pix_out):0; //TODO: needs to use pipelined signal (PS6)
    vga_g <= ~blank_pipe[3]?(mux_pixel[3:0]|bw_pix_out):0;  //TODO: needs to use pipelined signal (PS6)
    vga_b <= ~blank_pipe[3]?(mux_pixel[3:0]|bw_pix_out):0;  //TODO: needs to use pipelined signal (PS6)
  end
  assign vga_hs = ~hsync_pipe[4];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[4];  //TODO: needs to use pipelined signal (PS7)

endmodule

`default_nettype wire 
