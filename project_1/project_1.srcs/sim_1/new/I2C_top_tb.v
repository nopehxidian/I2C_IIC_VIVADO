`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/31 23:19:45
// Design Name: 
// Module Name: I2C_top_tb
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


module I2C_top_tb(

    );
 
 reg i_clk;    
 reg i_rst;    
 reg i_vaild;      
 wire i2c_sda;
 wire  i2c_scl;
 
 I2C_top test(                                                                       
        . clk                      (    i_clk                      )           ,  
        . i_rst                      (    i_rst                      )           ,  
        . i_vaild                    (    i_vaild                    )           ,  
        . i_slave_address            (    8'b1010_0000            )              ,  
        . i_slave_reg_address        (    8'b1010_0000        )                  ,  
        . i_master_data              (    8'b11010101              )             ,  
        . i_master_type               (    1              )                      ,   
        . i_master_vaild              (    1             )                       ,                                                                               
                                                                                     
        .         i2c_sda              (           i2c_sda            )       ,      
        .         i2c_scl              (          i2c_scl            )                                                                                     
     );                                                                              
 
M24LC64 M24LC64(
	.A0(1'b0),
	.A1(1'b0),
	.A2(1'b0),
	.WP(1'b0),
	.SDA(i2c_sda),
	.SCL(i2c_scl),
	.RESET(!i_rst)
); 

eeprom		u1_eeprom(
.sda				(i2c_sda			),
.scl				(i2c_scl			)
); 
 
 
 
 
 
 initial
 
 begin
     i_clk = 1'b0;
     forever #50 i_clk = ~i_clk;
 end
 //reset
 
 initial
 begin
     i_rst = 1;
     #5000;
     i_rst = 1'b0;
     i_vaild=1'b1;
 end
 //master control

 

 






  



















endmodule
