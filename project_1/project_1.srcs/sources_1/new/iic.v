`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 17:55:15
// Design Name: 
// Module Name: iic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module iic(
    clk             ,//系统时钟
    rst_n           ,//系统复位信号
    word_addr       ,//IIC器件寄存器地址
    wr              ,//写使能
    wr_data         ,//IIC器件写数据
    wr_data_valid   ,//IIC器件写数据有效标志位
    rd              ,//读使能
    rd_data         ,//读数据
    rd_data_valid   ,//IIC器件读数据有效标志位
    iic_scl         ,//IIC时钟线
    iic_sda         ,//IIC数据线
    done             //对IIC器件读写完成标识位
);
parameter CTR_BYTE  =   8'hA0;                  //M24LC64器件地址
parameter SYS_CLOCK =   50_000_000;             //系统时钟50MHz
parameter SCL_CLOCK =   400_000;                //sclk总线时钟400KHz快速模式
parameter SCL_CNT_M =   SYS_CLOCK / SCL_CLOCK;  //产生时钟sclk计数器最大值
parameter W_ADDR    =   16;                     //寄存器地址位宽
parameter WR_DATA   =   8;                      //写数据位宽
parameter RD_DATA   =   8;                      //读数据位宽
parameter CNT0_DATA =   7;                      //sclk计数器位宽
parameter CNT1_BYTE =   6;                      //byte计数器位宽
parameter WDATA	    =	50;						//wdata位宽		
parameter CNT_PHASE =   2;                      //阶段计数器位宽			

input                   clk;
input                   rst_n;
input   [W_ADDR-1:0]    word_addr;
input                   wr;
input   [WR_DATA-1:0]   wr_data;
input                   rd;
output                  wr_data_valid;
output  [RD_DATA-1:0]   rd_data;
output                  rd_data_valid;
output                  iic_scl;
output                  done;
inout                   iic_sda;

reg                     wr_data_valid;
reg     [RD_DATA-1:0]   rd_data;
reg                     rd_data_valid;
reg                     iic_scl;
reg                     done;

reg                     iic_out;
wire                    iic_in;
reg                     iic_en;

//中间变量
reg     [CNT0_DATA-1:0] cnt_sclk;
wire                    add_cnt_sclk;
wire                    end_cnt_sclk;

reg     [CNT1_BYTE-1:0] cnt_byte;
wire                    add_cnt_byte;
wire                    end_cnt_byte;

wire                    scl0;
wire                    scl1;
wire                    start_flag;
wire                    stop_flag;
wire                    wr_flag;
reg					    	sclk_valid;
reg	  [CNT1_BYTE-1:0]	cnt_byte_num;
reg	  [WDATA-1:0]		wdata;
wire							rd_flag;

wire                    rd2_start;

//三态门
//防止多主机冲突
//assign iic_sda = iic_en?(iic_out?1'bz:0):1'bz;
//assign iic_sda = (iic_en && !iic_out) ? 1'b0 : 1'bz;
assign iic_sda = iic_en?iic_out:1'bz;
assign iic_in = iic_sda;

//sclk时钟计数器
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_sclk <= 0;
    end
    else if(add_cnt_sclk)begin
        if(end_cnt_sclk)
            cnt_sclk <= 0;
        else
            cnt_sclk <= cnt_sclk + 1'b1;
    end
end
assign add_cnt_sclk = sclk_valid;
assign end_cnt_sclk = add_cnt_sclk && cnt_sclk == SCL_CNT_M - 1;

//比特位计数器
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_byte <= 0;
    end
    else if(add_cnt_byte)begin
        if(end_cnt_byte)
            cnt_byte <= 0;
        else
            cnt_byte <= cnt_byte + 1'b1;
    end
end
assign add_cnt_byte = end_cnt_sclk;
assign end_cnt_byte = add_cnt_byte && cnt_byte == cnt_byte_num - 1;

//sclk起始,结束
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sclk_valid <= 0;
    end
    else if(wr || rd)begin
        sclk_valid <= 1'b1;
    end
    else if(end_cnt_byte)begin
        sclk_valid <= 1'b0;
    end
end

//sclk高低电平转换
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        iic_scl <= 1;
    end
    else if(scl0)begin
        iic_scl <= 0;
    end
    else if(scl1)begin
        iic_scl <= 1;
    end
end
assign scl0         =   (add_cnt_sclk && cnt_sclk == SCL_CNT_M-1) && (!start_flag) && (!stop_flag) && !end_cnt_byte && !rd2_start;  //scl信号拉低条件
assign scl1         =   cnt_sclk == ((SCL_CNT_M >> 1) - 1) && add_cnt_sclk;                                                         //scl信号拉高条件
assign start_flag   =   (add_cnt_sclk && cnt_sclk == 0) && cnt_byte == 0;                                                           //起始位
assign stop_flag    =   (add_cnt_sclk && cnt_sclk == SCL_CNT_M-1) && cnt_byte == cnt_byte_num - 2;                                  //停止位
assign rd2_start    =   add_cnt_byte && cnt_byte == 28 && rd_data_valid;                                                            //第二阶段读开始位

//写数据
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        iic_out <= 1;
    end
    else if(wr_flag)begin
        iic_out <= wdata[(WDATA - 1) - cnt_byte];
    end
end
assign wr_flag = cnt_sclk == ((SCL_CNT_M >> 2) - 1) && add_cnt_sclk;

//读数据
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_data <= 8'b0;
    end
    else if(rd_flag)begin
        rd_data <= {rd_data[6:0],iic_in};
    end
end
assign rd_flag = (cnt_sclk == ((3*(SCL_CNT_M >> 2)) - 1)) && add_cnt_sclk && (cnt_byte >= 39) && (cnt_byte < 47) && rd_data_valid;

//读有效
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_data_valid <= 0;
    end
    else if(rd && !wr && !sclk_valid)begin
        rd_data_valid <= 1;
    end
    else if((wr && !rd && !sclk_valid) || end_cnt_byte)begin
        rd_data_valid <= 0;
    end
end

//写有效
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_data_valid <= 0;
    end
    else if(wr && !rd && !sclk_valid)begin
        wr_data_valid <= 1;
    end
    else if((rd && !wr && !sclk_valid) || end_cnt_byte)begin
        wr_data_valid <= 0;
    end
end

//cnt_byte_num设置
always @(*)begin
    if(wr_data_valid)begin
        //2字节地址写
        cnt_byte_num = 6'd39;
        //写数据
        wdata = {1'b0,CTR_BYTE | 8'h00,1'b0,word_addr[15:8],1'b0,word_addr[7:0],1'b0,wr_data,1'b0,1'b0,1'b1,11'b0};
    end
    else if(rd_data_valid)begin
        //2字节地址读
        cnt_byte_num = 6'd50;
        //读数据
        wdata = {1'b0,CTR_BYTE | 8'h00,1'b0,word_addr[15:8],1'b0,word_addr[7:0],1'b0,1'b1,1'b0,CTR_BYTE | 8'h01,1'b0,8'b0,1'b1,1'b0,1'b1};
    end
	else begin
		  cnt_byte_num = 0;
        wdata = 0;
	end
end

//done
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        done <= 0;
    end
    else if(end_cnt_byte)begin
        done <= 1;
    end
    else
        done <= 0;
end

//iic三态门使能
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        iic_en <= 0;
    end
    else if(wr && !rd && !sclk_valid)begin
        iic_en <= 1;
    end
    else if((rd && !wr && !sclk_valid) || (rd_data_valid && (cnt_byte == 0 || cnt_byte == 46) && add_cnt_byte))begin
        iic_en <= 1;
    end
    else if(rd_data_valid && cnt_byte == 38 && add_cnt_byte)begin
        iic_en <= 0;
    end
	else if(done)begin
		iic_en <= 0;
	end
end


endmodule

