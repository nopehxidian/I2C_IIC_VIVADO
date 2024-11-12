//	
/*	eeprom.v
用于模拟真实的EEPROM（AT24C02/4/8/16）的随机读写功能。对于符合AT24C02/4/8/16
要求的 scl 和 sda 随机读/写信号能根据I2C协议，分析其含义并进行相应的 读/写 操作

本模块是行为模块，不可综合为 门级网表。
*/

`define     timeslice 100

module eeprom(scl, sda);

input  scl;          		// 串行时钟线
inout  sda;          		// 串行数据线

reg    	   out_flag;        // SDA 数据输出的控制信号
reg [7:0]  memory [2047:0];
reg [10:0] address; 
reg [7:0]  memory_buf;
reg [7:0]  sda_buf;       // SDA数据输出寄存器    
reg [7:0]  shift;         // SDA数据输入寄存器
reg [7:0]  addr_byte;     // EEPROM 存储单元地址寄存器
reg [7:0]  ctrl_byte;     // 控制字寄存器
reg [1:0]  state;         // 状态寄存器

integer i;

//
parameter  r7=8'b1010_1111, w7=8'b1010_1110,       // main7
           r6=8'b1010_1101, w6=8'b1010_1100,        // main6
           r5=8'b1010_1011, w5=8'b1010_1010,        // main5
           r4=8'b1010_1001, w4=8'b1010_1000,        // main4

           r3=8'b1010_0111, w3=8'b1010_0110,        // main3
           r2=8'b1010_0101, w2=8'b1010_0100,        // main2
           r1=8'b1010_0011, w1=8'b1010_0010,        // main1
           r0=8'b1010_0001, w0=8'b1010_0000;        // main0
//
assign     sda = (out_flag == 1) ? sda_buf[7] : 1'bz;

//   寄存器和存储器初始化
initial  
     begin
        addr_byte = 0;
        ctrl_byte = 0;
        out_flag  = 0;
        sda_buf   = 0;
        state     = 2'b00;
        memory_buf= 0;
        address   = 0;
        shift     = 0;
           for(i=0; i<=2047; i=i+1)
              memory[i] = 0;
    end 

//  启动信号
always@(negedge sda)
     if(scl == 1)
        begin
            state = state + 1;   // 注意：Modelsim6.1以上版本，认为从高阻态到1是负跳变沿
            if(state == 2'b11)
              disable write_to_eeprm;		// 禁用名：write_to_eeprm 的过程或任务
        end

//  主状态机
always@(posedge sda)
     if(scl == 1)       // 停止操作
        stop_W_R;
     else 
        begin
            casex(state)
              2'b01:                 begin
// 注意：老版书上为 2'b01，因为Modelsim 6.0 以下版本   不认为从高阻态到1是跳变沿，
// 而Modelsim 6.1以上版本，在RTL仿真时，认为从高阻态到1是负跳变沿，所以写
// EEPROM操作从 2'b10 状态开始。

// 而做布线后仿真时，Modelsim 6.1以上版本，并不认为高阻态到1是 负跳变沿，所以
// 应该将进入转态2'b10，改为与老版书一致，即2'b01.
// 不同的仿真工具在处理高阻和不定态时有所不同，必须引起设计者的注意

              read_in;
              if(ctrl_byte == w7 || ctrl_byte == w6 || ctrl_byte == w5 
              || ctrl_byte == w4 || ctrl_byte == w3 || ctrl_byte == w2
              || ctrl_byte == w1 || ctrl_byte == w0)
              begin
                  state = 2'b10;
                  write_to_eeprm;   // 写操作
              end
              
              else
                  state = 2'b00;
          end

              2'b11:
                read_from_eeprm;   // 读操作
    
    default: state = 2'b00;
    endcase
end
       // 主状态机结束

//      操作停止
task stop_W_R;
   begin
       state = 2'b00;    // 状态返回为初始状态
       addr_byte = 0;
       ctrl_byte = 0;
       out_flag  = 0;
       sda_buf   = 0;       
   end
endtask

//      读进控制字和存储单元地址
task read_in;
   begin
      shift_in(ctrl_byte);
      shift_in(addr_byte);         
   end    
endtask

//  EEPROM的写操作
task write_to_eeprm;
   begin
       shift_in(memory_buf);
       address = {ctrl_byte[3:1], addr_byte};
       memory[address] = memory_buf;
//       $dispaly("eeprm---memory[%0h] = %0h", address, memory[address]);
       state = 2'b00;      // 回到 0 状态
   end
endtask

//  EEPROM的读操作
task read_from_eeprm;
   begin
       shift_in(ctrl_byte);
       if(ctrl_byte == r7 || ctrl_byte == r6 || ctrl_byte == r5 || ctrl_byte == r4
       || ctrl_byte == r3 || ctrl_byte == r2 || ctrl_byte == r1 || ctrl_byte == r0)
         begin
              address = {ctrl_byte[3:1],addr_byte};
              sda_buf = memory[address];
              shift_out;
              state = 2'b00;
         end
   end
endtask

//  SDA数据线上的数据存入寄存器，数据在 SCL 的高电平有效
task shift_in;
  output [7:0] shift;
    begin
        @(posedge scl) shift[7] = sda;
        @(posedge scl) shift[6] = sda;
        @(posedge scl) shift[5] = sda;
        @(posedge scl) shift[4] = sda;
        @(posedge scl) shift[3] = sda;
        @(posedge scl) shift[2] = sda;
        @(posedge scl) shift[1] = sda;
        @(posedge scl) shift[0] = sda;
        
        @(negedge scl)      begin
            #`timeslice;
              out_flag = 1;   // 应答信号输出
              sda_buf  = 0;
        end
        
        @(negedge scl)
            #`timeslice     out_flag = 0;
    
    end
endtask

//     EEPROM存储器中的数据通过 SDA 数据线输出，数据在 SCL 低电平时变化
task shift_out;
      begin
          out_flag = 1;
    for(i=6; i>=0; i=i-1)
        begin
          @(negedge scl);
            #`timeslice;
            sda_buf = sda_buf << 1;
        end
        
        @(negedge scl) #`timeslice sda_buf[7] = 1;    // 非应答信号输出
        @(negedge scl) #`timeslice out_flag   = 0;
        
       end
endtask

endmodule
