
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2019/12/17
*Module Name:uicfg7611
*File Name:uicfg7611.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/

/*******************************uicfg5640***************************
--1.OV5640����ͷоƬ������������
*********************************************************************/

`timescale 1ns / 1ns

module uicfg5640#(
parameter	 CLK_DIV  = 16'd499
)
(
input  clk_i,//ϵͳʱ������
input  rst_n,//ϵͳ��λ����
output cmos_scl,//I2C���ߣ�SCLʱ��
inout  cmos_sda, //I2C���ߣ�SDA����
input wire [15 :0] CAM_HSIZE, //����ͷˮƽ����
input wire [15 :0] CAM_VSIZE, //����ͷ��ֱ����
output reg cfg_done
);
parameter   DEVID   =  8'h78; //����ͷӲ��ID	

//�ڲ�����������һ���ӳٸ�λ
reg[7:0] rst_cnt =0;
always@(posedge clk_i or negedge rst_n)  
    if(rst_n == 1'b0) //��λ��ʼ���Ĵ���
        rst_cnt<= 8'd0; 
    else if(rst_cnt[7] == 1'b0)
       rst_cnt <= rst_cnt + 1'b1; 
    else 
       rst_cnt <= rst_cnt; 

reg  iic_req;//�������I2C�������ź�
wire ic_busy; //I2C������æ�ź� 
reg  [31:0] wr_data;     //д���ݼĴ���
reg  [1 :0] TS_S = 2'd0; //״̬���Ĵ���
reg  [8 :0] reg_index;   //�Ĵ�����
wire [23:0] REG_DATA;    //�Ĵ�������
wire [8 :0] REG_SIZE;    //�Ĵ�������

always@(posedge clk_i ) begin 
    if(rst_cnt[7] == 1'b0)begin //��λ��ʼ���Ĵ���
        reg_index<= 9'd0;
        iic_req  <= 1'b0;
        wr_data  <= 32'd0;
        cfg_done <= 1'b0;
        TS_S     <= 2'd0;    
    end
    else begin
        case(TS_S)
        0:if(reg_index == REG_SIZE) //����������
            cfg_done <= 1'b1;       //���� cfg_done��׼
          else if(cfg_done == 1'b0) //���δ�������
            TS_S <= 2'd1;           //��һ��״̬
        1:if(!iic_busy)begin        //�����߷�æ���ſ��Բ���I2C������
            iic_req  <= 1'b1;       //�������I2C������
            wr_data[7  :0] <= DEVID;// ov5640 id 
			wr_data[15 :8] <= REG_DATA[23:16];  //������ַ   
			wr_data[23:16] <= REG_DATA[15: 8];  //�Ĵ�����ַ     
			wr_data[31:24] <= REG_DATA[7 : 0];  //�Ĵ�������
            TS_S      <= 2'd2; //��һ��״̬
        end    
        2:if(iic_busy)begin
             iic_req  <= 1'b0;  //���� iic_req =0
             TS_S     <= 2'd3;  //��һ��״̬
        end
        3:if(!iic_busy)begin  //�����߷�æ���ſ��Բ���I2C������ 
			reg_index<= reg_index + 1'b1;//�Ĵ���������1
			TS_S    <= 2'd0;//�ص���ʼ״̬
        end 
        endcase
   end
end


//����I2C����ģ��
uii2c#
(
.WMEN_LEN(5),     //���֧��һ��д��4BYTE(����������ַ)
.RMEN_LEN(1),     //���֧��һ�ζ���1BYTE
.CLK_DIV(CLK_DIV) //100KHZ I2C����ʱ��
)
uii2c_inst
(
.clk_i(clk_i),//ϵͳʱ��
.rstn_i(rst_cnt[7]),//ϵͳ��λ
.iic_scl(cmos_scl),//I2C SCL����ʱ��
.iic_sda(cmos_sda),//I2C SDA��������
.wr_data(wr_data),//д���ݼĴ���
.wr_cnt(8'd4),//��Ҫд������BYTES
.rd_data(),   //�����ݼĴ���
.rd_cnt(8'd0),//��Ҫ��������BYTES
.iic_mode(1'b0),//��ģʽ����
.iic_req(iic_req),//I2C����������
.iic_busy(iic_busy)//I2C������æ
);

//����OV5640�ļĴ������ñ�
ui5640reg ui5640reg_inst
(
.CAM_VSIZE(CAM_VSIZE),
.CAM_HSIZE(CAM_HSIZE),
.REG_SIZE(REG_SIZE),
.REG_INDEX(reg_index),
.REG_DATA(REG_DATA)
);   

endmodule
