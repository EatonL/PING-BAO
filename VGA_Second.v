module VGA_Second
(
	//输入端口
	CLK_50M,RST_N,PS2_CLK,PS2_DATA,
	//输出端口
	VGA_VSYNC,VGA_HSYNC,VGA_DATA,
);

//---------------------------------------------------------------------------
//--	外部端口声明
//---------------------------------------------------------------------------
input 				CLK_50M;				//时钟的端口,开发板用的50M晶振
input 				RST_N;				//复位的端口,低电平复位

input             PS2_CLK;
input             PS2_DATA;

output 				VGA_VSYNC;			//VGA垂直同步端口
output 				VGA_HSYNC;			//VGA水平同步端口
output  	[ 7:0]	VGA_DATA;			//VGA数据端口
//---------------------------------------------------------------------------
//--内部端口说明
//---------------------------------------------------------------------------

wire     [15:0]     o_ps2_data;     //接收到PS2的完整数据
      
wire     [7:0]      readdata;       //从ROM中读出的VGA数据
wire     [14:0]     o_addr_wire;    //
//---------------------------------------------------------------------------
//--	逻辑功能实现	
//---------------------------------------------------------------------------
//例化PLL模块，生成VGA需要的40M时钟
PLL_Module			PLL_Inst 
(
	.inclk0 			(CLK_50M 	),		//50M时钟输入
	.c0 				(CLK_40M 	)		//40M时钟输出
);

//例化PS2
Ps2_Module			Ps2_Init
(
	.CLK_50M			(CLK_50M		),	//时钟端口
	.RST_N			(RST_N		),	//复位端口
	.PS2_CLK			(PS2_CLK		),	//PS2的时钟端口
	.PS2_DATA		(PS2_DATA	),	//PS2的数据端口
	.o_ps2_data		(o_ps2_data	)	//接收的PS2的完整数据
);

Vga_Module			Vga_Init
(
	.CLK_50M			(CLK_40M		),		//40M时钟输入
	.RST_N			(RST_N		),		//复位的端口,低电平复位
	.in_readdata   (readdata   ),    //从ROM中读出的VGA数据输入给VGA
	.VSYNC			(VGA_VSYNC	),		//VGA垂直同步端口
	.HSYNC			(VGA_HSYNC	),		//VGA水平同步端口
	.VGA_DATA		(VGA_DATA	),		//VGA数据端口
	.o_addr        (o_addr_wire),    //o_addr的地址端口
   .KEY				(o_ps2_data	)	   //将接收的数据输出给VGA模块
);

ROM	ROM_inst 
(
	.address  ( o_addr_wire ),       //ROM地址端口
	.clock    ( CLK_40M),            //ROM时钟端口
	.q        ( readdata )           //ROM数据端口
	);
endmodule
