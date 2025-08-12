// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20210329
// Author Name                  : ZJL
// Module Name                  :
// Project Name                 :
// Tarject Device               : Intel-Altera-EP5CEFA5
// Tool Versions                : Quartus-15.1
// Description                  :
// 
// free tool : [Video Timings Calculator](https://tomverbeure.github.io/video_timings_calculator)
// 
//                              频率        总像素      显示像素       前廊        脉冲宽度     后廊
//  SVGA 800X600        行同步 37.879KHz     1056像素     800像素     40像素      128像素    88像素
//  60Hz 逐行扫描        场同步 60.317Hz      628行        600行      1行         4行         23行
//                      时钟 40.000 MHz
// 640*480
//                              频率        总像素      显示像素      前廊        脉冲宽度     后廊 
//   6400X480           行同步 37.879KHz     800像素     640像素      20像素      120像素    20像素
//  50Hz 逐行扫描        场同步 60.317Hz      500行        480行      1行         4行         15行
//                      时钟 20.000 MHz
// 最小值        
// HSYNC Back Porch = 10          HSYNC Front Porch = 60    HSYNC Pulse Width = 10 
// VSYNC Back Porch = 7           VSYNC Front Porch = 2     VSYNC Pulse Width = 1
//                              
//                              
// Revision                     : 1.00.0000
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module vesa_timing_gen_v2#(
	parameter TIMING_NAME       = "1280X720@60HZ",
	parameter HOR_SYNC_POLARITY = "POSITIVE",
	parameter VER_SYNC_POLARITY = "POSITIVE"
)(
//global input interface
    input         wire        [1-1:0]        i_Sys_clk      ,        //20MHZ-pin C9/F8
    input         wire        [1-1:0]        i_Rst        ,
    

    output        wire        [1-1:0]        o_Video_hs      ,
    output        wire        [1-1:0]        o_Video_vs      ,
    output        wire        [1-1:0]        o_Video_de      ,
    output        wire        [24-1:0]       o_Video_data        
);//oled_drive
//************************parameter defination***********************

//************************wire signal defination***********************
wire            [16-1:0]            HOR_TOTAL           ;     
wire            [16-1:0]            HOR_ADDR            ;     
wire            [16-1:0]            HOR_BLANK           ;     
wire            [16-1:0]            HOR_BLANK_START     ;             
wire            [16-1:0]            HOR_SYNC            ;     
wire            [16-1:0]            HOR_BACK_PORCH            ;     
wire            [16-1:0]            HOR_FRONT_PORCH            ;     
wire            [16-1:0]            VER_BACK_PORCH            ;     
wire            [16-1:0]            VER_FRONT_PORCH            ;     
wire            [16-1:0]            HOR_SYNC_START      ;         
wire            [16-1:0]            VER_TOTAL           ;     
wire            [16-1:0]            VER_ADDR            ;     
wire            [16-1:0]            VER_BLANK           ;     
wire            [16-1:0]            VER_BLANK_START     ;             
wire            [16-1:0]            VER_SYNC            ;     
wire            [16-1:0]            VER_SYNC_START      ;   

wire          [1-1:0]               field_rst           ;
reg           [16-1:0]              hcnt                ;
reg           [16-1:0]              vcnt                ;

wire           [1-1:0]              video_h_valid  ;
wire           [1-1:0]              video_h_blank  ;
wire           [1-1:0]              video_h_sync   ;
wire           [1-1:0]              video_h_de     ;
wire           [1-1:0]              video_v_valid  ;
wire           [1-1:0]              video_v_blank  ;
wire           [1-1:0]              video_v_sync   ;
wire           [1-1:0]              video_v_de     ;
wire           [1-1:0]              video_v_front  ;
wire           [1-1:0]               video_hsync                ;
wire           [1-1:0]               video_vsync                ;


wire           [1-1:0]               video_valid                ;

//**********************************************************************************************    
generate if (TIMING_NAME=="1280X720@60HZ") begin
    // assign PIX_CLOCK        = 'd74250000;
    // assign FRAME_RATE        = 'd60;

    assign HOR_TOTAL        = 'd1650;
    assign HOR_SYNC         = 'd40;
    assign HOR_BACK_PORCH   = 'd220;
    assign HOR_ADDR         = 'd1280;
    assign HOR_FRONT_PORCH  = 'd110;
    assign VER_TOTAL        = 'd750;
    assign VER_SYNC         = 'd5;
    assign VER_BACK_PORCH   = 'd20;
    assign VER_ADDR         = 'd720;
    assign VER_FRONT_PORCH  = 'd5;

    // assign HOR_BLANK        = 'd370;
    // assign HOR_BLANK_START  = 'd1280;
    // assign HOR_SYNC_START   = 'd1390;
    // assign VER_BLANK        = 'd30;
    // assign VER_BLANK_START  = 'd720;
    // assign VER_SYNC_START   = 'd725;
end
else if(TIMING_NAME=="1024X768@60HZ")begin
    // assign PIX_CLOCK        = 'd65000000;
    // assign FRAME_RATE        = 'd60;

    assign HOR_TOTAL        = 'd1344;
    assign HOR_SYNC         = 'd136;
    assign HOR_BACK_PORCH   = 'd160;
    assign HOR_ADDR         = 'd1024;
    assign HOR_FRONT_PORCH  = 'd24;
    assign VER_TOTAL        = 'd806;
    assign VER_SYNC         = 'd5;
    assign VER_BACK_PORCH   = 'd29;
    assign VER_ADDR         = 'd768;
    assign VER_FRONT_PORCH  = 'd3;

    // assign HOR_BLANK        = 'd370;
    // assign HOR_BLANK_START  = 'd1280;
    // assign HOR_SYNC_START   = 'd1390;
    // assign VER_BLANK        = 'd30;
    // assign VER_BLANK_START  = 'd720;
    // assign VER_SYNC_START   = 'd725;
end
else if(TIMING_NAME=="800X600@60HZ")begin
    // assign PIX_CLOCK        = 'd40000000;
    // assign FRAME_RATE        = 'd60;

    assign HOR_TOTAL        = 'd1056;
    assign HOR_SYNC         = 'd128;
    assign HOR_BACK_PORCH   = 'd88;
    assign HOR_ADDR         = 'd800;
    assign HOR_FRONT_PORCH  = 'd40;
    assign VER_TOTAL        = 'd628;
    assign VER_SYNC         = 'd4;
    assign VER_BACK_PORCH   = 'd23;
    assign VER_ADDR         = 'd600;
    assign VER_FRONT_PORCH  = 'd1;
end
else if(TIMING_NAME=="800X600@56HZ")begin
    // assign PIX_CLOCK        = 'd36000000;
    // assign FRAME_RATE        = 'd56;

    assign HOR_TOTAL        = 'd1024;
    assign HOR_SYNC         = 'd72;
    assign HOR_BACK_PORCH   = 'd128;
    assign HOR_ADDR         = 'd800;
    assign HOR_FRONT_PORCH  = 'd24;
    assign VER_TOTAL        = 'd625;
    assign VER_SYNC         = 'd2;
    assign VER_BACK_PORCH   = 'd22;
    assign VER_ADDR         = 'd600;
    assign VER_FRONT_PORCH  = 'd1;
end
else if(TIMING_NAME=="1024X600@60HZ")begin
    // assign PIX_CLOCK        = 'd51206400;
    // assign FRAME_RATE        = 'd60;

    assign HOR_TOTAL        = 'd1344;
    assign HOR_SYNC         = 'd32;
    assign HOR_BACK_PORCH   = 'd120;
    assign HOR_ADDR         = 'd1024;
    assign HOR_FRONT_PORCH  = 'd168;

    assign VER_TOTAL        = 'd635;
    assign VER_SYNC         = 'd6;
    assign VER_BACK_PORCH   = 'd14;
    assign VER_ADDR         = 'd600;
    assign VER_FRONT_PORCH  = 'd15;
end
endgenerate
//**********************************************************************************************
always @ ( posedge i_Sys_clk ) begin
    if(i_Rst ) begin
        hcnt <= 'd0;
        vcnt <= 'd0;
    end
    // else if(field_rst)begin
    //     hcnt <= 'd0;
    //     vcnt <= 'd0;
    // end
    else if( (vcnt == VER_TOTAL-'d1) && (hcnt == HOR_TOTAL-'d1) )begin
        hcnt <= 'd0;
        vcnt <= 'd0;
    end
    else if(hcnt == HOR_TOTAL-'d1)begin
        hcnt <= 'd0;
        vcnt <= vcnt + 'd1;
    end
    else begin
        hcnt <= hcnt + 'd1;
        vcnt <= vcnt;
    end
end
//**********************************************************************************************    
assign video_v_sync  = (vcnt >= 'd0 && vcnt < VER_SYNC);
assign video_v_valid = (vcnt >= VER_SYNC+VER_BACK_PORCH && vcnt < VER_SYNC+VER_BACK_PORCH+VER_ADDR);

assign video_v_blank  = (vcnt >= VER_SYNC && vcnt < VER_SYNC+VER_BACK_PORCH);
//**********************************************************************************************
assign video_h_sync    = (hcnt >= 'd0 && hcnt < HOR_SYNC);
assign video_h_valid    = (hcnt >= HOR_SYNC+HOR_BACK_PORCH && hcnt < HOR_SYNC+HOR_BACK_PORCH+HOR_ADDR);

assign video_h_blank   = (hcnt >= HOR_SYNC && hcnt < HOR_SYNC+HOR_BACK_PORCH);
//**********************************************************************************************
generate if(HOR_SYNC_POLARITY=="POSITIVE")begin
    assign video_hsync = ~video_h_sync;
    end
    else begin
        assign video_hsync = video_h_sync;
    end
endgenerate
generate if(VER_SYNC_POLARITY=="POSITIVE")begin
    assign video_vsync = ~video_v_sync;
    end
    else begin
        assign video_vsync = video_v_sync;
    end
endgenerate

assign video_valid = video_v_valid && video_h_valid;
reg [16-1:0] test_data;
//**********************************************************************************************    
assign o_Video_hs        = video_hsync;
assign o_Video_vs        = video_vsync;
assign o_Video_de        = video_valid;
assign o_Video_data      = test_data;//{hcnt[7:0],hcnt[7:0],hcnt[7:0]};//hcnt;//
//**********************************************************************************************    
always @ ( posedge i_Sys_clk ) begin
    if(i_Rst ) test_data <= 'd0;
    else if(video_valid)test_data <= test_data + 'd1;
    else test_data <= 'd0;
end
//**********************************************************************************************    
endmodule