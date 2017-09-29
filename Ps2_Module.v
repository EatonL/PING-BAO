//---------------------------------------------------------------------------
//--	文件名		:	Ps2_Module.v
//--	作者		:	ZIRCON
//--	描述		:	PS2的功能模块
//--	修订历史	:	2014-1-1
//---------------------------------------------------------------------------
module Ps2_Module
(
	//输入端口
	CLK_50M,RST_N,PS2_CLK,PS2_DATA,
	//输出端口
	o_ps2_data
);

//---------------------------------------------------------------------------
//--	外部端口声明
//---------------------------------------------------------------------------
input						CLK_50M;				//时钟的端口,开发板用的50M晶振
input						RST_N;				//复位的端口,低电平复位
input						PS2_CLK;				//PS2的时钟端口
input						PS2_DATA;			//PS2的数据端口
output reg	[15:0] 	o_ps2_data;			//从PS2数据线中解析完后的数据。

//---------------------------------------------------------------------------
//--	内部端口声明
//---------------------------------------------------------------------------
reg			[ 1:0]	detect_edge;		//记录PS2的开始脉冲,即第一个下降沿
wire			[ 1:0]	detect_edge_n;		//detect_edge的下一个状态
reg			[ 3:0]	bit_cnt;				//记录PS2的时钟个数,即数据位数
reg			[ 3:0]	bit_cnt_n;			//bit_cnt的下一个状态
reg			[10:0]	bit_shift;			//数据移位寄存器,用于读出PS2线上数据
reg			[10:0]	bit_shift_n;		//bit_shift的下一个状态
reg			[39:0]	data_shift;			//数据移位寄存器,用于记录数据帧数
reg			[39:0]	data_shift_n;		//data_shift的下一个状态
reg			[15:0]	o_ps2_data_n;		//o_ps2_data的下一个状态
reg						negedge_reg;		//下降沿标志
wire						negedge_reg_n;		//negedge_reg的下一个状态

//---------------------------------------------------------------------------
//--	逻辑功能实现	
//---------------------------------------------------------------------------
//时序电路,用来给detect_edge寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		detect_edge	<= 2'b11;				//初始化detect_edge值
	else
		detect_edge <= detect_edge_n;		//用来给detect_edge赋值
end

//组合电路,检测下降沿
assign detect_edge_n = {detect_edge[0] , PS2_CLK};	//接收PS2的时钟信号

//时序电路,用来给negedge_reg寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		negedge_reg	<= 1'b0;					//初始化negedge_reg值
	else
		negedge_reg <= negedge_reg_n;		//用来给negedge_reg赋值
end

//组合电路,判断下降沿,如果detect_edge等于10,negedge_reg_n就置1
assign negedge_reg_n = (detect_edge == 2'b10) ? 1'b1 : 1'b0; 

//时序电路,用来给bit_cnt寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		bit_cnt <= 4'b0;						//初始化bit_cnt值
	else
		bit_cnt <= bit_cnt_n;				//用来给bit_cnt赋值
end

//组合电路,判断下降沿,并记录下降沿个数
always @ (*)
begin
	if(bit_cnt == 4'd11)						//判断时钟个数
		bit_cnt_n = 4'b0;						//如果等于11,bit_cnt_n就置0
	else if(negedge_reg)						//判断下降沿
		bit_cnt_n = bit_cnt + 4'b1;		//如果下降沿到来,bit_cnt_n就加1
	else							
		bit_cnt_n = bit_cnt;					//否则,保持不变
end

//时序电路,用来给bit_shift寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		bit_shift <= 11'b0;					//初始化bit_shift值
	else
		bit_shift <= bit_shift_n;			//用来给bit_shift赋值
end

//组合电路,读出PS2线上数据并放到移位寄存器中
always @ (*)
begin
	if(negedge_reg)							//判断下降沿
		bit_shift_n = {PS2_DATA , bit_shift[10:1]};	//如果下降沿到来,就将PS2数据线上的值存入移位寄存器中
	else
		bit_shift_n = bit_shift;			//否则,保持不变
end

//时序电路,用来给data_shift寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		data_shift <= 40'b0;					//初始化data_shift值
	else
		data_shift <= data_shift_n;		//用来给data_shift赋值
end

//组合电路,将字节拼合成帧
always @ (*)
begin
	if(bit_cnt == 4'd11)						//判断时钟个数
		data_shift_n = {data_shift[31:0] , bit_shift[8:1]}; //如果等于11,就将8位数据存入帧的移位寄存器中
	else
		data_shift_n = data_shift;			//否则,保持不变
end

//时序电路,用来给o_ps2_data寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		o_ps2_data <= 16'b0;					//初始化o_ps2_data值
	else
		o_ps2_data <= o_ps2_data_n;		//用来给o_ps2_data赋值
end

//组合电路,用来判断通码和断码,并将数据输出
always @ (*)
begin
	if((data_shift_n[15:8] == 8'hF0) && (data_shift_n[23:16] == 8'hE0)) //判断断码和通码
		o_ps2_data_n = {8'hE0 , data_shift_n[7:0]};	//如果相等就将E0和数据位输出
	else if((data_shift_n[15:8] == 8'hF0) && (data_shift_n[23:16] != 8'hE0)) //判断断码和通码
		o_ps2_data_n = {8'h0, data_shift_n[7:0]};		//如果通码不等于E0,就将数据位输出
	else
		o_ps2_data_n = o_ps2_data;			//否则,保持不变
end

endmodule

