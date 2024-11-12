//	
/*	eeprom.v
����ģ����ʵ��EEPROM��AT24C02/4/8/16���������д���ܡ����ڷ���AT24C02/4/8/16
Ҫ��� scl �� sda �����/д�ź��ܸ���I2CЭ�飬�����京�岢������Ӧ�� ��/д ����

��ģ������Ϊģ�飬�����ۺ�Ϊ �ż�����
*/

`define     timeslice 100

module eeprom(scl, sda);

input  scl;          		// ����ʱ����
inout  sda;          		// ����������

reg    	   out_flag;        // SDA ��������Ŀ����ź�
reg [7:0]  memory [2047:0];
reg [10:0] address; 
reg [7:0]  memory_buf;
reg [7:0]  sda_buf;       // SDA��������Ĵ���    
reg [7:0]  shift;         // SDA��������Ĵ���
reg [7:0]  addr_byte;     // EEPROM �洢��Ԫ��ַ�Ĵ���
reg [7:0]  ctrl_byte;     // �����ּĴ���
reg [1:0]  state;         // ״̬�Ĵ���

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

//   �Ĵ����ʹ洢����ʼ��
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

//  �����ź�
always@(negedge sda)
     if(scl == 1)
        begin
            state = state + 1;   // ע�⣺Modelsim6.1���ϰ汾����Ϊ�Ӹ���̬��1�Ǹ�������
            if(state == 2'b11)
              disable write_to_eeprm;		// ��������write_to_eeprm �Ĺ��̻�����
        end

//  ��״̬��
always@(posedge sda)
     if(scl == 1)       // ֹͣ����
        stop_W_R;
     else 
        begin
            casex(state)
              2'b01:                 begin
// ע�⣺�ϰ�����Ϊ 2'b01����ΪModelsim 6.0 ���°汾   ����Ϊ�Ӹ���̬��1�������أ�
// ��Modelsim 6.1���ϰ汾����RTL����ʱ����Ϊ�Ӹ���̬��1�Ǹ������أ�����д
// EEPROM������ 2'b10 ״̬��ʼ��

// �������ߺ����ʱ��Modelsim 6.1���ϰ汾��������Ϊ����̬��1�� �������أ�����
// Ӧ�ý�����ת̬2'b10����Ϊ���ϰ���һ�£���2'b01.
// ��ͬ�ķ��湤���ڴ������Ͳ���̬ʱ������ͬ��������������ߵ�ע��

              read_in;
              if(ctrl_byte == w7 || ctrl_byte == w6 || ctrl_byte == w5 
              || ctrl_byte == w4 || ctrl_byte == w3 || ctrl_byte == w2
              || ctrl_byte == w1 || ctrl_byte == w0)
              begin
                  state = 2'b10;
                  write_to_eeprm;   // д����
              end
              
              else
                  state = 2'b00;
          end

              2'b11:
                read_from_eeprm;   // ������
    
    default: state = 2'b00;
    endcase
end
       // ��״̬������

//      ����ֹͣ
task stop_W_R;
   begin
       state = 2'b00;    // ״̬����Ϊ��ʼ״̬
       addr_byte = 0;
       ctrl_byte = 0;
       out_flag  = 0;
       sda_buf   = 0;       
   end
endtask

//      ���������ֺʹ洢��Ԫ��ַ
task read_in;
   begin
      shift_in(ctrl_byte);
      shift_in(addr_byte);         
   end    
endtask

//  EEPROM��д����
task write_to_eeprm;
   begin
       shift_in(memory_buf);
       address = {ctrl_byte[3:1], addr_byte};
       memory[address] = memory_buf;
//       $dispaly("eeprm---memory[%0h] = %0h", address, memory[address]);
       state = 2'b00;      // �ص� 0 ״̬
   end
endtask

//  EEPROM�Ķ�����
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

//  SDA�������ϵ����ݴ���Ĵ����������� SCL �ĸߵ�ƽ��Ч
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
              out_flag = 1;   // Ӧ���ź����
              sda_buf  = 0;
        end
        
        @(negedge scl)
            #`timeslice     out_flag = 0;
    
    end
endtask

//     EEPROM�洢���е�����ͨ�� SDA ����������������� SCL �͵�ƽʱ�仯
task shift_out;
      begin
          out_flag = 1;
    for(i=6; i>=0; i=i-1)
        begin
          @(negedge scl);
            #`timeslice;
            sda_buf = sda_buf << 1;
        end
        
        @(negedge scl) #`timeslice sda_buf[7] = 1;    // ��Ӧ���ź����
        @(negedge scl) #`timeslice out_flag   = 0;
        
       end
endtask

endmodule
