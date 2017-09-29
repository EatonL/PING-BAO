//---------------------------------------------------------------------------
//--	文件名		:	Vga_Module.v
//--	作者		:	ZIRCON
//--	描述		:	VGA显示图片
//--	修订历史	:	2014-1-1
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//-- VGA 800*600@60
//-- VGA_DATA[7:0] red2,red1,red0,green2,green1,green0,blue1,blue0
//-- VGA CLOCK 40MHz.
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//-- Horizonal timing information
//-- Sync pluse   128  a
//-- back porch   88   b
//-- active       800  c
//-- front porch  40   d
//-- All line     1056 e
//-- Vertical timing information
//-- sync pluse   4    o
//-- back porch   23   p
//-- active time  600  q
//-- front porch  1    r
//-- All lines    628  s
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//-- Horizonal timing information
`define HSYNC_A   16'd128  // 128
`define HSYNC_B   16'd216  // 128 + 88
`define HSYNC_C   16'd1016 // 128 + 88 + 800
`define HSYNC_D   16'd1056 // 128 + 88 + 800 + 40
//-- Vertical  timing information
`define VSYNC_O   16'd4    // 4 
`define VSYNC_P   16'd27   // 4 + 23
`define VSYNC_Q   16'd627  // 4 + 23 + 600
`define VSYNC_R   16'd628  // 4 + 23 + 600 + 1
//---------------------------------------------------------------------------

module Vga_Module
(
	//输入端口
	CLK_50M,RST_N,in_readdata,KEY,
	//输出端口
	VSYNC,HSYNC,VGA_DATA,o_addr,d_hr,d_vr
);

//---------------------------------------------------------------------------
//--	外部端口声明
//---------------------------------------------------------------------------
input 				CLK_50M;					//时钟的端口,开发板用的50M晶振
input 				RST_N;					//复位的端口,低电平复位
input    [7:0]    in_readdata;          //VGA输入端口

input    [7:0]    KEY;                 //按键端口

output 				VSYNC;					//VGA垂直同步端口
output 				HSYNC;					//VGA水平同步端口
output  	[ 7:0]	VGA_DATA;				//VGA数据端口
output   [14:0]   o_addr;              // o_addr的地址端口
//---------------------------------------------------------------------------
//--	内部端口声明
//---------------------------------------------------------------------------
reg 		[15:0] 	hsync_cnt;				//水平扫描计数器
reg 		[15:0]	hsync_cnt_n;			//hsync_cnt的下一个状态
reg 		[15:0] 	vsync_cnt;				//垂直扫描计数器
reg 		[15:0] 	vsync_cnt_n;			//vsync_cnt的下一个状态
reg 		[ 7:0] 	VGA_DATA;				//RGB端口总线
reg 		[ 7:0] 	VGA_DATA_N;				//VGA_DATA的下一个状态
reg 					VSYNC;					//垂直同步端口	
reg					VSYNC_N;					//VSYNC的下一个状态
reg 					HSYNC;					//水平同步端口
reg					HSYNC_N;					//HSYNC的下一个状态
reg 					vga_data_en;			//RGB传输使能信号		
reg 					vga_data_en_n;			//vga_data_en的下一个状态
reg      [14:0]   o_addr;              // o_addr的地址端口
reg      [14:0]   o_addr_n;     	      // o_addr的下一个状态

reg		[26:0] 	time_seconds;			//秒钟低位计数器
reg		[26:0] 	time_seconds_n;		//time_seconds的下一个状态

reg		[ 9:0] 	hsy;					//秒钟低位数据寄存器1
reg		[ 9:0] 	hsy_n;				//seconds1_data的下一个状态
reg		[ 9:0] 	vsy;					//秒钟低位数据寄存器1
reg		[ 9:0] 	vsy_n;				//seconds1_data的下一个状态
output reg      [ 9:0]   d_hr;
output reg      [ 9:0]   d_vr;

//设置定时器的时间为1s,计算方法为  (1*10^9) / (1/50)  50MHZ为开发板晶振
parameter SEC_TIME_1S  = 26'd25000_000;	
parameter h_edge_left = 10'd0;
parameter h_edge_right = 10'd505;
parameter v_edge_up = 10'd0;
parameter v_edge_down = 10'd400;

always @ (posedge CLK_50M or negedge RST_N)
begin
   if(!RST_N)                                //判断复位
	    time_seconds <= 1'b0;						//初始化time_seconds值		
	else
		 time_seconds <= time_seconds_n;			//用来给time_seconds赋值;
end

//组合电路，实现1s的定时计数器
always @ (*)
begin
	if(time_seconds == SEC_TIME_1S)				//判断1s时间
		time_seconds_n = 1'b0;						//如果到达1s,定时计数器将会被清零
	else								               //判断有没有按下暂停
		time_seconds_n = time_seconds + 1'b1;	//如果没有暂停,定时计数器将会继续累加
end	

always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)											//判断复位						    
		vsy <= 10'd0;						         //初始化vsy值
	else
		vsy <= vsy_n;		                     //用来给vsy赋值
end

always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)											//判断复位
		hsy <= 10'd0;						         //初始化hsy值
	else
		hsy <= hsy_n;		                     //用来给hsy赋值	
end

always @ (*)
begin
   if(time_seconds == SEC_TIME_1S) 
		begin 
		hsy_n = hsy + d_hr; 
		if(hsy == h_edge_right) 
			d_hr = -10'd5;	
	   if(hsy == h_edge_left)
			d_hr = 10'd5;
		end
	else;
end

always @ (*)
begin
   if(time_seconds == SEC_TIME_1S)        	//判断1s时间
		begin                                  
		vsy_n = vsy + d_vr; 
		if(vsy == v_edge_down)
			d_vr = -10'd5;
		if(vsy == v_edge_up)
			d_vr = 10'd5;
		end
	else;
end


//时序电路,用来给hsync_cnt寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									      //判断复位
		hsync_cnt <= 16'b0;					      //初始化hsync_cnt值
	else
		hsync_cnt <= hsync_cnt_n;			      //用来给hsync_cnt赋值
end

//组合电路,水平扫描
always @ (*)
begin
	if(hsync_cnt == `HSYNC_D)				      //判断水平扫描时序
		hsync_cnt_n = 16'b0;					      //如果水平扫描完毕,计数器将会被清零
	else
		hsync_cnt_n = hsync_cnt + 1'b1;	      //如果水平没有扫描完毕,计数器继续累加
end

//时序电路,用来给vsync_cnt寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									      //判断复位
		vsync_cnt <= 16'b0;					      //给行扫描赋值
	else
		vsync_cnt <= vsync_cnt_n;			      //给行扫描赋值
end

//组合电路,垂直扫描
always @ (*)
begin
	if((vsync_cnt == `VSYNC_R) && (hsync_cnt == `HSYNC_D))//判断垂直扫描时序
		vsync_cnt_n = 16'b0;					      //如果垂直扫描完毕,计数器将会被清零
	else if(hsync_cnt == `HSYNC_D)		      //判断水平扫描时序
		vsync_cnt_n = vsync_cnt + 1'b1;	      //如果水平扫描完毕,计数器继续累加
	else
		vsync_cnt_n = vsync_cnt;			      //否则,计数器将保持不变
end

//时序电路,用来给HSYNC寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									      //判断复位
		HSYNC <= 1'b0;							      //初始化HSYNC值
	else
		HSYNC <= HSYNC_N;						      //用来给HSYNC赋值
end

//组合电路，将HSYNC_A区域置0,HSYNC_B+HSYNC_C+HSYNC_D置1
always @ (*)
begin	
	if(hsync_cnt < `HSYNC_A)				      //判断水平扫描时序
		HSYNC_N = 1'b0;						      //如果在HSYNC_A区域,那么置0
	else
		HSYNC_N = 1'b1;						      //如果不在HSYNC_A区域,那么置1
end

//时序电路,用来给VSYNC寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									      //判断复位
		VSYNC <= 1'b0;							      //初始化VSYNC值
	else
		VSYNC <= VSYNC_N;						      //用来给VSYNC赋值
end

//组合电路，将VSYNC_o区域置0,VSYNC_P+VSYNC_Q+VSYNC_R置1
always @ (*)
begin	
	if(vsync_cnt < `VSYNC_O)				//判断水平扫描时序
		VSYNC_N = 1'b0;						//如果在VSYNC_O区域,那么置0
	else
		VSYNC_N = 1'b1;						//如果不在VSYNC_O区域,那么置1
end

//时序电路,用来给vga_data_en寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		vga_data_en <= 1'b0;					//初始化vga_data_en值
	else
		vga_data_en <= vga_data_en_n;		//用来给vga_data_en赋值
end

//组合电路，判断显示有效区（列像素>216&&列像素<1017&&行像素>27&&行像素<627）
always @ (*)
begin
	if((hsync_cnt > `HSYNC_B && hsync_cnt <`HSYNC_C) && 
		(vsync_cnt > `VSYNC_P && vsync_cnt < `VSYNC_Q))
		vga_data_en_n = 1'b1;				//如果在显示区域就给使能数据信号置1
	else
		vga_data_en_n = 1'b0;				//如果不在显示区域就给使能数据信号置0
end

//时序电路，用来给ROM赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		o_addr <= 1'b0;					//初始化o_addr值
	else
		o_addr <= o_addr_n;		     //用来给o_addr赋值
end

//组合电路，用来判断图片显示有效区域
always @ (*)
	begin
	if(KEY != 8'h70)
	begin
	     if((hsync_cnt == `HSYNC_B + hsy)&& (vsync_cnt == `VSYNC_P + vsy))
	      o_addr_n = 15'd0;
			else if((hsync_cnt > `HSYNC_B + hsy) && (hsync_cnt <= `HSYNC_B + hsy + 10'd120) &&(vsync_cnt > `VSYNC_P + vsy) && (vsync_cnt <= `VSYNC_P + vsy + 10'd117))
			o_addr_n = o_addr +1'b1;
			else
				o_addr_n =o_addr;
	end
	else;
   end
			
//时序电路,用来给VGA_DATA寄存器赋值
always @ (posedge CLK_50M or negedge RST_N)
begin
	if(!RST_N)									//判断复位
		VGA_DATA <= 8'd0;						//初始化VGA_DATA值
	else
		VGA_DATA <= VGA_DATA_N;				//用来给VGA_DATA赋值
end


//组合电路，显示图片,
always @ (*)
begin
	if(KEY != 8'h70)
	begin
	if(vga_data_en)							//判断数据使能
		begin
			if((hsync_cnt > `HSYNC_B + hsy) && (hsync_cnt <= `HSYNC_B + hsy + 10'd120) &&(vsync_cnt > `VSYNC_P + vsy) && (vsync_cnt <= `VSYNC_P + vsy + 10'd117))	
				VGA_DATA_N = in_readdata;	
			else
		      VGA_DATA_N =8'd0;	
		end
	else
		VGA_DATA_N = 8'd0;					//黑色	
	end
	else;
end
endmodule
