`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, btnu, //btnc (used for reset)

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camerafull_pixel_pipe
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag

  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign led = sw; //switches drive LED (change if you want)

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

  

  //vga_mux output:
  logic [11:0] mux_pixel; //final 12 bit information from vga multiplexer
  //goes right into RGB of output for video render

  //Generate 65 MHz:
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


  //recovers hcount and vcount from camera module:
  //generates data and a valid signal on 65 MHz
  recover recover_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .frame_done_in(frame_done),

    .system_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .pixel_out(pixel_data_rec),
    .data_valid_out(data_valid_rec),
    .hcount_out(hcount_rec),
    .vcount_out(vcount_rec));

  //using generate/genvar, create five *Different* instances of the
  //filter module (you'll write that).  Each filter will implement a different
  //kernel
  filter #(.K_SELECT(1)) filtern(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .data_valid_in(data_valid_rec),
    .pixel_data_in(pixel_data_rec),
    .hcount_in(hcount_rec),
    .vcount_in(vcount_rec),
    .data_valid_out(data_valid_f0),
    .pixel_data_out(pixel_data_f0),
    .hcount_out(hcount_f0),
    .vcount_out(vcount_f0)
  );




  generate
    genvar i;
    for (i=0; i<6; i=i+1)begin
      filter #(.K_SELECT(i)) filterm(
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .data_valid_in(data_valid_f0),
        .pixel_data_in(pixel_data_f0),
        .hcount_in(hcount_f0),
        .vcount_in(vcount_f0),
        .data_valid_out(data_valid_f[i]),
        .pixel_data_out(pixel_data_f[i]),
        .hcount_out(hcount_f[i]),
        .vcount_out(vcount_f[i])
      );
    end
  endgenerate

  //combine hor and vert signals from filters 4 and 5 for special signal:
  logic [7:0] fcomb_r, fcomb_g, fcomb_b;
  assign fcomb_r = (pixel_data_f[4][15:11]+pixel_data_f[5][15:11])>>1;
  assign fcomb_g = (pixel_data_f[4][10:5]+pixel_data_f[5][10:5])>>1;
  assign fcomb_b = (pixel_data_f[4][4:0]+pixel_data_f[5][4:0])>>1;

  //based on values of sw[2:0] select which filter output gets handed on to the
  //next module. We must make sure to route hcount, vcount, pixels and valid signal
  // for each module.  Could have done this with a for loop as well!  Think
  // about it!
  always_ff @(posedge clk_65mhz)begin
    case (sw[2:0])
      3'b000: begin
        hcount_fmux <= hcount_f[0];
        vcount_fmux <= vcount_f[0];
        pixel_data_fmux <= pixel_data_f[0];
        data_valid_fmux <= data_valid_f[0];
      end
      3'b001: begin
        hcount_fmux <= hcount_f[1];
        vcount_fmux <= vcount_f[1];
        pixel_data_fmux <= pixel_data_f[1];
        data_valid_fmux <= data_valid_f[1];
      end
      3'b010: begin
        hcount_fmux <= hcount_f[2];
        vcount_fmux <= vcount_f[2];
        pixel_data_fmux <= pixel_data_f[2];
        data_valid_fmux <= data_valid_f[2];
      end
      3'b011: begin
        hcount_fmux <= hcount_f[3];
        vcount_fmux <= vcount_f[3];
        pixel_data_fmux <= pixel_data_f[3];
        data_valid_fmux <= data_valid_f[3];
      end
      3'b100: begin
        hcount_fmux <= hcount_f[4];
        vcount_fmux <= vcount_f[4];
        pixel_data_fmux <= pixel_data_f[4];
        data_valid_fmux <= data_valid_f[4];
      end
      3'b101: begin
        hcount_fmux <= hcount_f[5];
        vcount_fmux <= vcount_f[5];
        pixel_data_fmux <= pixel_data_f[5];
        data_valid_fmux <= data_valid_f[5];
      end
      3'b110: begin
        hcount_fmux <= hcount_f[4];
        vcount_fmux <= vcount_f[4];
        pixel_data_fmux <= {fcomb_r[4:0],fcomb_g[5:0],fcomb_b[4:0]};
        data_valid_fmux <= data_valid_f[4]&&data_valid_f[5];
      end
      default: begin
        hcount_fmux <= hcount_f[0];
        vcount_fmux <= vcount_f[0];
        pixel_data_fmux <= 16'b11111_000000_11111;
        data_valid_fmux <= data_valid_f[0];
      end
    endcase
  end
  //new rotate module only on 65 MHz:
  //same as old one, but this one runs on 65 MHz with valid signal as
  //opposed to old one that ran on 16.67 MHz.
  rotate2 rotate_m(
    .clk_in(clk_65mhz),
    .hcount_in(hcount_fmux),
    .vcount_in(vcount_fmux),
    .data_valid_in(data_valid_fmux),
    .pixel_in(pixel_data_fmux),
    .pixel_out(pixel_rotate),
    .pixel_addr_out(pixel_addr_in),
    .data_valid_out(valid_pixel_rotate));

  //NEW FOR LAB 04B (END)----------------------------------------------
  
  //Rotates Image to render correctly (pi/2 CCW rotate):
  // rotate rotate_m (
  //   .cam_clk_in(cam_clk_in),
  //   .valid_pixel_in(valid_pixel),
  //   .pixel_in(cam_pixel),
  //   .valid_pixel_out(valid_pixel_rotate),
  //   .pixel_out(pixel_rotate),
  //   .frame_done_in(frame_done),
  //   .pixel_addr_in(pixel_addr_in));

  //Two Clock Frame Buffer:
  //Data written on 16.67 MHz (From camera)
  //Data read on 65 MHz (start of video pipeline information)
  //Latency is 2 cycles.
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),
    .RAM_DEPTH(320*240))
    frame_buffer (
    //Write Side (16.67MHz)
    .addra(pixel_addr_in),
    .clka(clk_65mhz),
    .wea(valid_pixel_rotate),
    .dina(pixel_rotate),
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

  //Based on current hcount and vcount as well as
  //scaling and mirror information requests correct pixel
  //from BRAM (on 65 MHz side).
  //latency: 2 cycles
  //IMPORTANT: this module is "start" of Output pipeline
  //hcount and vcount are fine here.
  //however latency in the image information starts to build up starting here
  //and we need to make sure to continue to use screen location information
  //that is "delayed" the right amount of cycles!
  //AS A RESULT, most downstream modules after this will need to use appropriately
  //pipelined versions of hcount, vcount, hsync, vsync, blank as needed
  //these The pipelining of these stages will need to be determined
  //for CHECKOFF 3!
  mirror mirror_m(
    .clk_in(clk_65mhz),
    .mirror_in(1'b1),
    .scale_in(2'b01),
    .hcount_in(hcount), //
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_out)
  );

  //Based on hcount and vcount as well as scaling
  //gate the release of frame buffer information
  //Latency: 0
  scale scale_m(
    .scale_in(2'b01),
    .hcount_in(hcount_pipe[3]), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount_pipe[3]), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(frame_buff),
    .cam_out(full_pixel)
    );

  //Convert RGB of full pixel to YCrCb
  //See lecture 04 for YCrCb discussion.
  //Module has a 3 cycle latency
  rgb_to_ycrcb rgbtoycrcb_m(
    .clk_in(clk_65mhz),
    .r_in({full_pixel[15:11], 5'b0}), //all five of red
    .g_in({full_pixel[10:5],4'b0}), //all six of green
    .b_in({full_pixel[4:0], 5'b0}), //all five of blue
    .y_out(y),
    .cr_out(cr),
    .cb_out(cb));

  //LED Display controller
  //module not in video pipeline, provides diagnostic information
  //about high/low mask state as well as what channel is selected:
  //: "r:red, g:green, b:blue, y: luminance, Cr: Red Chrom, Cb: Blue Chrom
  lab04_ssc mssc(.clk_in(clk_65mhz),
                 .rst_in(btnc),
                 .val_in({sw[15:10],sw[5:3]}),
                 .cat_out({cag, caf, cae, cad, cac, cab, caa}),
                 .an_out(an));

  //Thresholder: Takes in the full RGB and YCrCb information and
  //based on upper and lower bounds masks
  //module has 0 cycle latency
  threshold( .sel_in(sw[5:3]),
     .r_in(full_pixel_pipe[2][15:12]), //TODO: needs to use pipelined signal (PS5)
     .g_in(full_pixel_pipe[2][10:7]),  //TODO: needs to use pipelined signal (PS5)
     .b_in(full_pixel_pipe[2][4:1]),   //TODO: needs to use pipelined signal (PS5)
     .y_in(y[9:6]),
     .cr_in(cr[9:6]),
     .cb_in(cb[9:6]),
     .lower_bound_in(sw[12:10]),
     .upper_bound_in(sw[15:13]),
     .mask_out(mask),
     .channel_out(sel_channel)
     );

  /

  //Image Sprite (your implementation from Lab03):
  //Latency 4 cycle
  // image_sprite #(
  //   .WIDTH(256),
  //   .HEIGHT(256))
  //   com_sprite_m (
  //   .pixel_clk_in(clk_65mhz),
  //   .rst_in(sys_rst),
  //   .hcount_in(hcount_pipe[2]),   //TODO: needs to use pipelined signal (PS1)
  //   .vcount_in(vcount_pipe[2]),   //TODO: needs to use pipelined signal (PS1)
  //   .x_in(x_com>128 ? x_com-128 : 0),
  //   .y_in(y_com>128 ? y_com-128 : 0),
  //   .pixel_out(com_sprite_pixel));


  //VGA MUX:
  //latency 0 cycles (combinational-only module)
  //module decides what to draw on the screen:
  // sw[7:6]:
  //    00: 444 RGB image
  //    01: GrayScale of Selected Channel (Y, R, etc...)
  //    10: Masked Version of Selected Channel
  //    11: Chroma Image with Mask in 6.205 Pink
  // sw[9:8]:
  //    00: Nothing
  //    01: green crosshair on center of mass
  //    10: image sprite on top of center of mass
  //    11: all pink screen (for VGA functionality testing)
  // vga_mux (.sel_in(sw[9:6]),
  // .camera_pixel_in({full_pixel[15:12],full_pixel[10:7],full_pixel[4:1]}), //TODO: needs to use pipelined signal(PS5)
  // .camera_y_in(y[9:6]),
  // .channel_in(sel_channel),
  // .thresholded_pixel_in(mask),
  // .crosshair_in(crosshair_pipe[3]), //TODO: needs to use pipelined signal (PS4)
  // .com_sprite_pixel_in(com_sprite_pixel),
  // .pixel_out(mux_pixel)
  // );


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

  //blankig logic.
  //latency 1 cycle
  assign mux_pixel = {full_pixel[15:12],full_pixel[10:7],full_pixel[4:1]};
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank_pipe[3]?mux_pixel[3:0]:0; //TODO: needs to use pipelined signal (PS6)
    vga_g <= ~blank_pipe[3]?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
    vga_b <= ~blank_pipe[3]?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
    // vga_r <= ~blank_pipe[6]?mux_pixel[11:8]:0; //TODO: needs to use pipelined signal (PS6)
    // vga_g <= ~blank_pipe[6]?mux_pixel[7:4]:0;  //TODO: needs to use pipelined signal (PS6)
    // vga_b <= ~blank_pipe[6]?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
  end

  assign vga_hs = ~hsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)





  logic [3:0] gray_out = full_pixel[4:1];
  logic [11:0] pixel_out;
  logic state_1;
  start_screen start_screen(
       .rst(sys_rst),
       .clk(clk_65mhz),
       .hcount(hcount_pipe[2]),
       .vcount(vcount_pipe[2]), 
       .cam_img(gray_out),
       .sw_state(sw[15]),
       .btnc_pressed(btnc),
       .pixel_out(pixel_out),
       .state_1_over(state_1)
  );

  logic[2:0] photobooth_state
  //////////STATE MACHINE////////////
  always_ff  @(posedge clk_65mhz)begin
    if(rst_in) begin
      photobooth_state <=0;
    end else begin
      if(photobooth_state ==0)begin //INITIAL
        if(state_1) begin
          photobooth_state <=1;
        end
      end else if(photobooth_state == 1) begin //PHOTO
      end else if(photobooth_state == 2) begin //CHOOSE
      end else if(photobooth_state == 3) begin //THRESHOLD
      end else if (photobooth_state == 4) begin //SEND
      end
    end
  end
endmodule




`default_nettype wire
