
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

/*******************************I2C������ MASTER*********************
--��������������Ƶ�I2C����MASTER������
--1.�����࣬ռ�ü����߼���Դ������ṹ�������߼�����Ͻ�
--2.ʹ�÷��㣬ֻ��Ҫ�ѷ��͵����ݷ���Ĵ������Ϳ����Զ�֧�����ⳤ�ȵ�д����
--3.ʹ�÷��㣬ֻ��Ҫ�Ѷ������ݸ�֪���������Ϳ����Զ�֧�����ⳤ�ȵĶ�����
--4.1.1�汾��������iic_bus_error��־�źţ�������д����û��ACK���أ�����iic_bus_error������ͨ���۲�iic_bus_error�鿴�����Ƿ��д���
*********************************************************************/

`timescale 1ns / 1ns //����̶�/����

module uii2c#
(
parameter WMEN_LEN = 8'd0,//д���ȣ����ֽ�Ϊ��λ������������ַ
parameter RMEN_LEN = 8'd0,//�����ȣ����ֽ�Ϊ��λ��������������ַ
parameter CLK_DIV  = 16'd499// I2Cʱ�ӷ�Ƶϵ��
)
(
input  wire clk_i,//ϵͳʱ������
input  wire rstn_i,//ϵͳ��λ���͵�ƽ��Ч
output reg  iic_scl = 1'b0,//I2Cʱ��SCL
inout  wire iic_sda,//I2C ��������
input  wire [WMEN_LEN*8-1'b1:0]wr_data,//д���ݼĴ���������WMEN_LEN���������֧�ֵ������ֽ�����Խ��ռ�õ�FPGA��ԴԽ��
input  wire [7:0]wr_cnt,//д���ݼ�����������д�˶��ٸ��ֽ�
output reg  [RMEN_LEN*8-1'b1:0]rd_data = 0,//�����ݼĴ���������RMEN_LEN���������֧�ֵ������ֽ�����Խ��ռ�õ�FPGA��ԴԽ��
input  wire [7:0]rd_cnt,//�����ݼ�����
input  wire iic_req,//iic_req == 1 ʹ��I2C����
input  wire iic_mode,//iic_mode = 1 �����   iic_mode = 0 ����ǰ�Ĵ�������ҳ��
output reg  iic_busy = 1'b0,//I2C������æ
output reg  iic_bus_error, //I2C���ߣ��޷�������ȷACK����
output reg  iic_sda_dg
);

localparam IDLE    = 4'd0;//I2C ���߿���״̬
localparam START   = 4'd1;//I2C ��������
localparam W_WAIT  = 4'd2;//I2C ���ߵȴ�д���
localparam W_ACK   = 4'd3;//I2C ���ߵȴ�дWACK
localparam R_WAIT  = 4'd4;//I2C ���ߵȴ������ 
localparam R_ACK   = 4'd5;//I2C ���ߵȴ���RACK 
localparam STOP1   = 4'd6;//I2C ���߲���ֹͣλ
localparam STOP2   = 4'd7;//I2C ���߲���ֹͣλ   

localparam SCL_DIV = CLK_DIV/2;

localparam OFFSET = SCL_DIV - SCL_DIV/4;//����I2C���ߵ�SCLʱ�ӵ�ƫ�ƣ�������SCL��SDA��ʱ��Ҫ���ⲿ��SCL�ӳ��ڲ��İ����ڵ��ķ�֮��

reg [2:0] IIC_S = 4'd0; //I2C ״̬��
//generate  scl
reg [15:0] clkdiv = 16'd0;   //I2C ʱ�ӷ�Ƶ�Ĵ���
reg scl_r 	   = 1'b1;       //I2C��������SCL�ڲ�ʱ��
reg sda_o 	   = 1'b0;       //I2C��������SDA
reg scl_clk    = 1'b0;       //I2C�������ڲ�SCLʱ�ӣ����ⲿʱ�Ӵ���OFFSET�������õ���λƫ��
reg [7:0] sda_r = 8'd0;      //���ͼĴ���
reg [7:0] sda_i_r = 8'd0;    //���ռĴ���
reg [7:0] wcnt = 8'd0;       //�������ݼ���������byteΪ��λ
reg [7:0] rcnt = 8'd0;       //�������ݼ���������byteΪ��λ
reg [2:0] bcnt = 3'd0;       //bit������
reg  rd_req = 1'b0;          //�����󣬵��жϵ���Ҫ�����ݣ��ڲ�״̬��������1
wire sda_i;                  //sda ����
wire scl_offset;             //scl ʱ��ƫ�ƿ���

assign  sda_i   = (iic_sda == 1'b0) ?  1'b0 : 1'b1;  //������ 
assign  iic_sda = (sda_o == 1'b0) ?  1'b0 : 1'bz;    //д���ߣ�1'bz������裬I2C�ⲿͨ���������裬ʵ�����ߵĸߵ�ƽ


//scl ʱ�ӷ�Ƶ��
always@(posedge clk_i)
    if(clkdiv < SCL_DIV)    
        clkdiv <= clkdiv + 1'b1;
    else begin
        clkdiv <= 16'd0; 
        scl_clk <= !scl_clk;
    end


assign  scl_offset  = (clkdiv == OFFSET);//����scl_offset��ʱ�����
always @(posedge clk_i) iic_scl <=  scl_offset ?  scl_r : iic_scl; //iic_scl�ӳ�scl_offsetʱ���scl_r

//�ɼ�I2C ��������sda
always @(posedge clk_i) iic_sda_dg <= sda_i;  

//��IIC_S״̬�����ڣ�ͬʱ����״̬������SCLΪ�ߵ�ƽ��ͬʱҲ�ǿ��У�ֹͣ״̬�����ڲ�����ʼλ��ֹͣλʱ�򣬷���Ĵ�scl_clkʱ��
always @(*) 
    if(IIC_S == IDLE || IIC_S == STOP1 || IIC_S == STOP2)
        scl_r <= 1'b1;
    else 
        scl_r <= scl_clk;
  

//������IIC_S״̬Ϊ������ֹͣ����sda=0�����scl������ʼλ������(IIC_S == R_ACK && (rcnt != rd_cnt) sda=0�����ڲ�����������ACK
always @(*) 
    if(IIC_S == START || IIC_S == STOP1 || (IIC_S == R_ACK && (rcnt != rd_cnt)))
        sda_o <= 1'b0;
    else if(IIC_S == W_WAIT)
        sda_o <= sda_r[7]; 
    else  sda_o <= 1'b1; //��������״̬��Ϊ1����(IIC_S == R_ACK && (rcnt == rd_cnt) ����һ��NACK 

//I2C���ݷ���ģ�飬���е�д���ݶ�ͨ����ģ�鷢��
always @(posedge scl_clk) 
    if(IIC_S == W_ACK || IIC_S == START)begin//IIC_S=START��W_ACK������Ҫ���͵����ݣ��Ĵ浽sda_r
        sda_r <= wr_data[(wcnt*8) +: 8];//�Ĵ���Ҫ�����͵����ݵ�sda_r
        if( rd_req ) sda_r <= {wr_data[7:1],1'b1};//���ڶ�������rd_req���ڲ������������д���һ������(������ַ)����ͨ���ж�rd_cnt��ȷ���Ƿ�������Ҫ��
    end
    else if(IIC_S == W_WAIT)//��W_WAT״̬��ͨ����λ�����������ݷ��͵���������
        sda_r <= {sda_r[6:0],1'b1};//��λ����
    else 
        sda_r <= sda_r;

//sda data bus read and hold data to rd_data register when IIC_S=R_ACK
//I2C���ݽ���ģ�飬I2C���ڼ䣬������ͨ����λ����������rd_data
always @(negedge scl_clk)begin
    if(IIC_S == R_WAIT ) //��IIC_S == R_WAIT ||IIC_S == W_ACK(�������������1��BIT��W_ACK���״̬��)������λ����
        sda_i_r <= {sda_i_r[6:0],sda_i};
    else if(IIC_S == R_ACK)//��IIC_S == R_ACK,���һ��BYTE���������ݱ��浽rd_data
        rd_data[((rcnt-1'b1)*8) +: 8] <= sda_i_r[7:0];
    else if(IIC_S == IDLE)//����״̬������sda_i_r
        sda_i_r <= 8'd0;
end

//����æ״̬
always @(posedge scl_clk or negedge rstn_i )begin
	if(rstn_i == 1'b0)
    	iic_busy <= 1'b0; 
	else begin
    	if((iic_req == 1'b1 || rd_req == 1'b1 || iic_bus_error))//iic_req == 1'b1 || rd_req == 1'b1���߽���æ״̬
    	    iic_busy <= 1'b1; 
        else if(IIC_S == IDLE)
        	iic_busy <= 1'b0;
    end 		
end

//����æ״̬
always @(negedge scl_clk or negedge rstn_i )begin
	if(rstn_i == 1'b0)
    	iic_bus_error <= 1'b0;  	
	else begin
    	if(IIC_S  == W_ACK && sda_i == 1'b1)//iic_req == 1'b1 || rd_req == 1'b1���߽���æ״̬
    	    iic_bus_error <= 1'b1; 
        else if(iic_req == 0)
        	iic_bus_error <= 1'b0;
    end 		
end

//I2C Master������״̬��
always @(posedge scl_clk or negedge rstn_i )begin
		if(rstn_i == 1'b0)begin //�첽��λ����λ��ؼĴ���
           wcnt 	<= 8'd0;
           rcnt 	<= 8'd0;
           rd_req 	<= 1'b0;   
        end
        else begin
        case(IIC_S) //sda = 1 scl =1
        IDLE:begin//�ڿ���״̬��sda=1 scl=1 
           if(iic_req == 1'b1 || rd_req == 1'b1) //��iic_req == 1'b1������������ �� rd_req == 1'b1 �����������Ҫ����repeated start �ظ�����  
              IIC_S  <= START; //����START״̬
           else begin
              wcnt <= 8'd0; //��λ������
              rcnt <= 8'd0; //��λ������
           end
        end
        START:begin //���״̬��ǰ��Ĵ��룬������sda = 0��scl_offset����������scl_clkʱ�ӵ�ƫ�ƣ�֮�� scl_clk =0 ��scl =0 ������ʼλ�����ظ���ʼλ
           bcnt <= 3'd7; //����bcnt�ĳ�ֵ         
           IIC_S  <= W_WAIT;//���뷢�͵ȴ�
        end           
        W_WAIT://�ȴ�������ɣ����﷢��8bits ���ݣ�д������ַ��д�Ĵ�����ַ��д���ݣ��������״̬���
        begin
           if(bcnt > 3'd0)//���8bitsû�����ֱ꣬��������
               bcnt  <= bcnt - 1'b1; //bcnt��������ÿ����1bit��1
           else begin //8bits�������
               wcnt <= wcnt + 1'b1; //wcnt�����������ڼ�¼�Ѿ�д�˶����ֽ�
               IIC_S  <= W_ACK;//����W_ACK״̬
           end
        end 
        W_ACK://�ȴ�WACK���˽׶Σ�Ҳ�ж��Ƿ��ж�����
        begin 
           if(wcnt < wr_cnt)begin //�ж��Ƿ��������ݷ���(д)���
              bcnt <= 3'd7; //���û��д�꣬����bcnt
              IIC_S <= W_WAIT;//�����ص�W_WAIT�ȴ����ݷ���(д)���
           end
           else if(rd_cnt > 3'd0)begin//rd_cnt > 0������������Ҫ����rd_cnt�������ж���������Ҫ��
              if(rd_req == 1'b0 && iic_mode == 1'b1)begin //���ڵ�һ��д��������ַ�����iic_mode==1����֧�������
                  rd_req <= 1'b1;//����rd_req=1�����������
                  IIC_S <= IDLE; //����״̬����IDLE������rd_req��ֵ�����²���һ��Ϊ���������е�repeated�ظ�start
              end
              else //���֮ǰ�Ѿ������repeated�ظ�start����ô��������������ݽ׶�
                  IIC_S <= R_WAIT;//������ȴ�
                  bcnt <= 3'd7;//����bcnt�ĳ�ֵ  
           end
           else //������еķ�����ɣ�Ҳû������Ҫ��������ֹͣ״̬
              IIC_S <= STOP1; 
        end  
        R_WAIT://�ȴ����������
        begin
           rd_req <= 1'b0;//���ö�����rd_req=0
           bcnt  <= bcnt - 1'b1; //bit ������
           if(bcnt == 3'd0)begin //��8bits���ݶ���
              rcnt <= (rcnt < rd_cnt) ? (rcnt + 1'b1) : rcnt;//�ж��Ƿ���������Ҫ��
              IIC_S  <= R_ACK;//����R_ACK
           end
        end
        R_ACK://R_ACK״̬����NACK
        begin
           bcnt <= 3'd7;//���ö�����bcnt������
           IIC_S <= (rcnt < rd_cnt) ? R_WAIT : STOP1; //����������ݶ��꣬����ֹͣ״̬
        end  
        STOP1:begin//����ֹͣλ sda = 0 scl = 1
            rd_req 	<= 1'b0;              
            IIC_S <= STOP2;
        end
        STOP2://����ֹͣλ  sda = 1 scl = 1
            IIC_S <= IDLE;          
        default:
            IIC_S <= IDLE;
    	endcase
    end
end

endmodule
