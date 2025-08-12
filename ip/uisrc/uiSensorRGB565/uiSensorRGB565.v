/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2022/12/23
*Module Name:uii2c
*File Name:uii2c.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.1
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/

/*******************************uiSensorRGB565*********************
--ʵ��RGB565ʱ��תRGB888ʱ��
*********************************************************************/

`timescale 1ns / 1ns //����̶�/����

module uiSensorRGB565(
    input rstn_i,
	input cmos_clk_i, //ʱ�����룬һ������24M��ֱ�Ӹ�cmos_xclk_o
	input cmos_pclk_i,//����ʱ������
	input cmos_href_i,//����href��Ч
	input cmos_vsync_i,//����VS��Ч
	input [7:0]cmos_data_i,//�������ݣ�ÿ2������Ϊһ��RGB565
	output cmos_xclk_o,//FPGA���������ͷ��ʱ��
    output [23:0] rgb_o,//RGB888
    output de_o,//RGB888����Ч�ź�
    output vs_o,//RGB888��VS�ź�
    output hs_o//RGB888��HS�ź�
    );
    
assign cmos_xclk_o = cmos_clk_i; 
     
reg cmos_href_r1 = 1'b0,cmos_href_r2 = 1'b0,cmos_href_r3 = 1'b0;
reg cmos_vsync_r1 = 1'b0,cmos_vsync_r2 = 1'b0;
reg [7:0]cmos_data_r1 = 8'b0;
reg [7:0]cmos_data_r2 = 8'b0;    

//�첽��λתͬ����λ
reg rstn1,rstn2;
always@(posedge cmos_pclk_i or negedge rstn_i)begin
        if(!rstn_i)begin
            rstn2 <= 1'b0;
            rstn1 <= 1'b0;
        end
        else begin
            rstn1 <= 1'b1;
            rstn2 <= rstn1;
        end
end

//�źŴ���
always@(posedge cmos_pclk_i)begin
       cmos_href_r1  <= cmos_href_i;
       cmos_href_r2  <= cmos_href_r1;
       cmos_href_r3  <= cmos_href_r2;       
       cmos_data_r1  <= cmos_data_i;
       cmos_data_r2  <= cmos_data_r1;
       cmos_vsync_r1 <= ~cmos_vsync_i;      
       cmos_vsync_r2 <= cmos_vsync_r1;       
end    

//��ʼ��֡���ݶ�����֡����ֹ��ʼ�����ݲ���
parameter FRAM_FREE_CNT = 5;
reg [7:0]vs_cnt;
wire vs_p = !cmos_vsync_r2&&cmos_vsync_r1;
always@(posedge cmos_pclk_i)begin
    if(!rstn2)begin
        vs_cnt <= 8'd0;
    end 
    else if(vs_p)begin
        if(vs_cnt < FRAM_FREE_CNT)
            vs_cnt <= vs_cnt + 1'b1;
         else
            vs_cnt <= vs_cnt;
    end
end    

wire out_en = (vs_cnt == FRAM_FREE_CNT);

//�������RGB565תRGB888
reg href_cnt   = 1'b0;
reg data_en  = 1'b0;
reg [15:0]rgb2 = 32'd0;
always@(posedge cmos_pclk_i)begin
	if(vs_p||(~out_en))begin
	   href_cnt  <= 1'd0;
	   data_en   <= 1'b0;
	   rgb2      <= 16'd0;
	end	
	else begin
	   href_cnt  <= cmos_href_r2 ?  href_cnt + 1'b1 : 1'b0 ;
       data_en   <= (href_cnt==1'd1);
       if(cmos_href_r2) begin
            rgb2 <= {rgb2[7:0],cmos_data_r2};
       end    
	end	
end

//RGB565תRGB888 ��λ��0
assign  rgb_o  = {rgb2[15:11],3'd0,rgb2[10:5],2'd0,rgb2[4:0],3'd0};

assign	de_o   =  out_en && data_en ;
assign	vs_o   =  out_en && cmos_vsync_r2 ;
assign	hs_o   =  out_en && cmos_href_r3 ;

endmodule
