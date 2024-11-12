
`timescale 1 ns/ 1 ns
module iic_vlg_tst();
// test vector input registers
reg clk;
reg rd;
reg rst_n;
reg [15:0] word_addr;
reg wr;
reg [7:0] wr_data;
// wires                                               
wire done;
wire iic_scl;
wire iic_sda;
wire [7:0]  rd_data;
wire rd_data_valid;
wire wr_data_valid;

// assign statements (if any)                          
//assign iic_sda = treg_iic_sda;
iic i1 (
// port map - connection between master ports and signals/registers   
	.clk(clk),
	.done(done),
	.iic_scl(iic_scl),
	.iic_sda(iic_sda),
	.rd(rd),
	.rd_data(rd_data),
	.rd_data_valid(rd_data_valid),
	.rst_n(rst_n),
	.word_addr(word_addr),
	.wr(wr),
	.wr_data(wr_data),
	.wr_data_valid(wr_data_valid)
);

//M24LC64 M24LC64(
//	.A0(1'b0),
//	.A1(1'b0),
//	.A2(1'b0),
//	.WP(1'b0),
//	.SDA(iic_sda),
//	.SCL(iic_scl),
//	.RESET(!rst_n)
//);

//时钟周期，单位ns，在这里修改时钟周期
parameter CYCLE = 20;

//生成本地时钟50M
initial begin
	clk = 0;
	forever
	#(CYCLE/2)
	clk=~clk;
end

//产生复位信号
initial begin
	rst_n = 0;
	word_addr = 0;
	wr = 0;
	wr_data = 0;
	rd = 0;
	#(CYCLE * 200 + 1)
	rst_n = 1;
	#200;

	word_addr = 0;
	wr_data = 0;
	wr = 1'b1;
	#(CYCLE)
	wr = 1'b0;
	wr_data = 8'b1010_0011;
	#200000;

	word_addr = 0;
	rd = 1'b1;
	#(CYCLE)
	rd = 1'b0;
end

endmodule
