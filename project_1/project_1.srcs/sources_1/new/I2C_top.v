`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/31 20:58:13
// Design Name: 
// Module Name: I2C_top
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


module I2C_top(
       input clk                   ,
       input i_rst                   ,
       input i_vaild                 ,
       /*-------------用户端输入参数--------------*/
       input [7:0]   i_slave_address            ,
       input [7:0]  i_slave_reg_address        ,
       input [7:0]   i_master_data              ,
       input         i_master_type              ,
       input         i_master_vaild             ,
     
       
//       output        o_slave_data               ,  
//       output        i_master_ready                ,
//       output        o_slave_ready              ,
       
       
       
       
       inout          i2c_sda               ,
       output        reg  i2c_scl              
       
           
    );
    /*-------------有限长状态机--------------*/
    parameter     st_idle=0            ;
    parameter     st_start=1           ;
    parameter     st_address=2         ;  
    parameter     st_reg_address=3     ;  
    parameter     st_wire_data=4       ;  
    parameter     st_read_data=5       ; 
    //parameter     st_listen_ack=20      ;                  
    parameter     st_restart=6                  ;
    parameter     st_read=7               ;
    parameter     st_end=8               ;
    
    /*-------------状态机转移--------------*/
    reg         [7:0]       st_current       ;
    reg         [7:0]       st_next          ;
    reg         [7:0]       st_cnt           ;
    wire        st_listen_ack;
    reg         st_turn                      ;
    /*-------------SDA信号线释放状态--------------*/
    reg         st_sda       ;  
    wire        w_iic_sda       ;
    reg         r_iic_sda       ;
    /*-------------SDA三态门-------------*/
    assign i2c_sda           = st_sda ? r_iic_sda : 1'bz   ;//三态门输出               ;
//    assign w_iic_sda            = !st_sda ? i2c_sda : 1'b0 ;//三态门输入
    assign w_iic_sda            = !st_sda ? i_vaild : 1'b0 ;
    assign st_listen_ack=!st_sda ? i_vaild : 1'b0 ;
    reg     [3:0]clk_cnt1;  
    reg     [3:0]clk_cnt2; 
    reg     i_clk;
    reg [5:0]cnt_clk;
    reg      sda_fuzhi;
    reg      flag_sda;  
    reg      flag_scl;
    reg      st_ack;
    reg     flag_turn;
          
       always@(posedge clk,posedge i_rst)                                      
       begin                                                                     
                                                                                 
           if(i_rst)                                                             
           begin                                                       
               i_clk<=0;   
               cnt_clk<=0; 
               flag_scl<=0;                                       
            end                                                        
                                                                       
           else if(cnt_clk==14) 
            
           begin                                                    
           i_clk <= ~i_clk;
           flag_scl<=1;
           cnt_clk <= cnt_clk+1;
           end
           
           else 
           begin                                                                            
               cnt_clk <= cnt_clk+1;                                          
               flag_scl<=0;  
            end
                                                                        
       end                                                                       
    
    
    always@(posedge clk,posedge i_rst)
    begin
   
        if(i_rst)
        begin
            st_ack<=0;
         end
        else if(w_iic_sda==1)
        st_ack<=1;
        else if(w_iic_sda==0) 
        st_ack<=0;


    end
    
    
     always@(posedge clk,posedge i_rst)                                                                      
 begin                                                                                                   
                                                                                                         
     if(i_rst)                                                                                           
     begin                                                                                               
         flag_sda<=0;                                                                                    
      end                                                                                                
     else if(cnt_clk==7)                                                                                 
     flag_sda<=1;                                                                                        
                                                                                                         
     else                                                                                                
     flag_sda<=0;                                                                                        
 end                                                                                                     
                                                                                                         
    always@(posedge clk,posedge i_rst)                               
 begin                                                                
                                                                      
     if(i_rst)                                                        
     begin                                                            
         flag_turn<=0;                                                 
      end                                                             
     else if(cnt_clk==6)                                              
     flag_turn<=1;                                                     
                                                                      
     else                                                             
     flag_turn<=0;                                                     
 end                                                                  
    
    
    always@(posedge clk,posedge i_rst)
    begin
        if(i_rst)
        begin
            i2c_scl<=1;
        end
        
        else if(flag_scl==1)
        
        begin
        i2c_scl<=~i2c_scl;
        cnt_clk<=0;
        end
    end
    
    
                      
    always@(posedge clk,posedge i_rst)
    begin
   
        if(i_rst)
        begin
            sda_fuzhi<=0;
         end

        else 
        sda_fuzhi<=~sda_fuzhi;
    end
   
    
    
    
    
    
    
    
    
//    always@(posedge i_clk,posedge i_rst)
//    begin
   
//        if(i_rst)
//        begin
//            i2c_scl<=1;
//         end

//        else if
//        (st_current >= st_address && st_current <= st_end)
//        begin 
//            i2c_scl <= ~i2c_scl;
//            end
//    end
         
         
//    always@(posedge i_clk,posedge i_rst)
//    begin
    
//        if(i_rst)
//                begin
//            clk_cnt2 <= 0;
//            i_clk<=0;
//                 end
//        else if (clk_cnt2!=3)
//            clk_cnt2 <= clk_cnt2+1;
//        else if (clk_cnt2==3)  
//        begin 
//            clk_cnt2 <= 0;
//            i_clk <= ~i_clk;
//            end
//    end
           
            
    always@(posedge clk,posedge i_rst)
    begin
    
        if(i_rst)
            st_current <= st_idle;
        else 
            st_current <= st_next;
    end
    
     always@(*)                                                                    
     begin                                                                                                   
         if(!i_rst)                                                                                           
                       case(st_current)
                                        st_idle                 :           st_next<=  i_vaild            ?                 st_start:    st_idle; 
                                        st_start                :           st_next<=  st_turn            ?                 st_address:   st_start;  
                                        st_address              :           st_next<=  st_turn            ?                 st_listen_ack   ?    st_reg_address:   st_start:   st_address;  
                                        st_reg_address          :           st_next<=  st_turn            ?                 (st_listen_ack   ?    (i_master_type?st_wire_data:st_read_data):   st_start) : st_reg_address;              
//                                        begin
//                                        if(st_listen_ack)
                                        
//                                                st_next<=      i_master_type             ?               st_wire_data:st_read_data;           
                                        
//                                        else    
//                                                st_next<=      st_reg_address;
//                                                end
                                                
                                        st_wire_data            :           st_next<=     st_turn            ?                 st_listen_ack   ?    st_idle:   st_start:   st_wire_data; 
                                        st_read_data            :           st_next<=     st_turn            ?                 st_listen_ack   ?    st_idle:   st_start:   st_read_data; 
                                        //st_restart              :           st_next<=                   ?              st_start
                                       // st_read                 :           st_next<=                   ?                                                        
                                    //st_end                  :           st_next<=                       ?       
                                         default     : st_next <=  st_idle;  
                                         endcase                                                                   
            else     
                                         st_next <=  st_idle;                                         
     end           
                                                                                               
//     always@(negedge i_clk,posedge i_rst)                               
//     begin                                                              
//         if(i_rst)                                                      
//                     st_listen_ack<=0;                                                   
//         else        
//         begin
//                if(!st_sda)
//                st_listen_ack<=i_vaild;//仿真方便 ACK为0
//                else 
                
//                st_listen_ack<=0;
                
//          end                                                     
                                                                        
//     end   
                     
                                                                  
     always@(posedge clk or posedge i_rst)                              
     begin                                                              
         if(i_rst)     
         begin                                                 
                              r_iic_sda<=1;                                          
         end
          else if     (flag_sda&&~i2c_scl)
          begin
                  if((st_current ==  st_address)||(st_current ==  st_start))
                              r_iic_sda<=i_slave_address[7 - st_cnt];
                else if( st_current ==  st_reg_address)                           
                              r_iic_sda<=i_slave_reg_address[7 - st_cnt];
                else if( st_current == st_wire_data)                                         
                              r_iic_sda<=i_master_data[7 - st_cnt];   
                //else if( st_current ==  st_address)                           
                //              r_iic_sda<=st_address[7 - st_cnt]; 
                end   
    end
           
           
           
                                                                                                  
            always@(posedge clk,posedge i_rst)                                                  
            begin                                                                                 
                if(i_rst)                                                                         
                                     r_iic_sda<=1;                                                
                       else if( st_current ==  st_start&&flag_sda&&i2c_scl)                                          
                                     r_iic_sda<=0;                                                
//                                     else if(st_current ==  st_address&&st_cnt==8'b00&&i2c_scl)            
//                                     r_iic_sda<=0;                                          
                       end                                                                        
           
           
           
           
           
           
           
                          
      always@(posedge clk,posedge i_rst)        
      begin                                                       
                                                                                                                   
          if(i_rst)                                                                              
              st_cnt<=0;      
          else    if(     flag_scl&&~i2c_scl )   
                         
              st_cnt<=st_cnt+1;
           
//          else    if(     st_cnt==8'b00001000    &&    !i2c_scl )   
//              st_cnt<=0;   
      end      
     
   
       
       always@(posedge clk,posedge i_rst)
       begin                               
                                           
           if(i_rst)                       
               st_sda <= 1; 
                   
//               else    if(st_cnt==8&&!i2c_scl) 
                    else    if(flag_sda&&~i2c_scl&&st_cnt==8)
               begin                           
                   st_sda <=0;
                                  
               end                                  
                   
                   
           else    if((flag_sda&&~i2c_scl&&st_cnt!=8))
           begin 
                    
               st_sda <=1;
            
           end            
    
       end                                 
       
      
        always@(posedge clk,posedge i_rst)
       begin                               
                                           
           if(i_rst)                       
               st_sda <= 1; 
                   
//               else    if(st_cnt==8&&!i2c_scl) 
                    else    if(st_cnt==9&&flag_turn&&~i2c_scl)
                        st_turn<=1;               
                    else    if(flag_scl&&~i2c_scl&&st_current==st_start)
                        st_turn<=1;                                                           
                   
           else   
            
           begin          
             
               st_turn<=0;
           end            
    
       end                                 
       
       
       
       
       
       
       
       
       
       
       
          always@(posedge clk,posedge i_rst)        
      begin                                                       
                                                                                                                   
          if(i_rst)                                                                              
              st_cnt<=0;   
                 
//              else if(st_turn)
//               st_cnt<=0;
               
          else    if(st_cnt==9 &&    !i2c_scl&&flag_turn) 
           begin                
               st_cnt<=0;   
           end  
           
//          else    if(     st_cnt==8'b00001000    &&    !i2c_scl )   
//              st_cnt<=0;   
      end      
       
       
                                                                               
          always@(posedge clk,posedge i_rst)                                 
      begin                                                                    
                                                                              
          if(i_rst)                                                         
              st_turn<=0;                                                       
//          else    if(st_cnt==8 &&    i2c_scl)                                 
                                                                     
//              st_turn<=1;
//              else                                                          
//              st_turn<=0;                                              
                                                                               
       
       
      end                                                                     
                                                                              
                                                                              
                                                                                                                                                    
                                                                              
                                                                                                        
endmodule
    