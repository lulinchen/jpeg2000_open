
`ifndef GOLBAL_INC
`define GOLBAL_INC

`ifdef TIMESCALE_PS	
	`timescale 1ps/1ps
	`define TIME_COEFF		1000
`else
	`timescale 1ns/1ps
	`define TIME_COEFF		1
`endif

`define W_CAMD_I  47


`define MAX_CB_WIDTH 64
`define TILE_WIDTH 128

// 8 pixel in a item 
// x0 x4
// x1 x5
// x2 x6
// x3 x7 

`define PIXEL_PER_ITEM  4
`define W_AA_COEFF_BUF 	($clog2(`TILE_WIDTH*`TILE_WIDTH/`PIXEL_PER_ITEM) -1)

`define W_AB_COEFF_BUF 	($clog2(`TILE_WIDTH*`TILE_WIDTH/`PIXEL_PER_ITEM/2) -1)

// for level_cnt = 0 
// band leghth in pixel  = (`TILE_WIDTH*`TILE_WIDTH) >> (ndecomp -1 - level_cnt + 2)
// band leghth in pixel  = (`TILE_WIDTH*`TILE_WIDTH) >> (ndecomp - level_cnt + 2)
// units per band  = band leghth in pixel / PIXEL_PER_ITEM
`define INIT_AA_LL 0
`define INIT_AA_HL (`TILE_WIDTH*`TILE_WIDTH/`PIXEL_PER_ITEM) * 1/4 
`define INIT_AA_LH (`TILE_WIDTH*`TILE_WIDTH/`PIXEL_PER_ITEM) * 2/4 
`define INIT_AA_HH (`TILE_WIDTH*`TILE_WIDTH/`PIXEL_PER_ITEM) * 3/4 


`define W_AFRAMEBUF 17

`define MAX_PIC_WIDTH	4096
// in 8x8 size
`define W_PWInMbs 	 9 - 1  //   
`define W_PHInMbs 	 9 - 1  // 


`define W_PWInMbsM1		 `W_PWInMbs
`define W_PHInMbsM1		 `W_PHInMbs

`define	W_PICMBS	(`W_PWInMbs + `W_PHInMbs + 1)

`define W_PW	`W_PWInMbs+3     // 11-1 
`define W_PH	`W_PHInMbs+3	 // 11-1


`define W1                 7
`define W2                15
`define W3                23
`define W4                31
`define W5                39
`define W6                47
`define W7                55
`define W8                63
`define W9                71
`define W10               79
`define W11               87
`define W12               95
`define W13              103
`define W14              111
`define W15              119
`define W16              127
`define W17              135
`define W18              143
`define W19              151
`define W20              159
`define W21              167
`define W22              175
`define W23              183
`define W24              191
`define W25              199
`define W26              207
`define W27              215
`define W28              223
`define W29              231
`define W30              239
`define W31              247
`define W32              255
`define W48              383
`define W64              511
`define W63              503
`define W71				 567
`define W72				 575
`define W78				 623
`define W79				 631	
`define W80			     639
`define W128            1023
`define W256            2047
`define W512            4095

`define W1P                 (`W1  + 1)          // P = Plus1
`define W2P                 (`W2  + 1)
`define W3P                 (`W3  + 1)
`define W4P                 (`W4  + 1)
`define W5P                 (`W5  + 1)
`define W6P                 (`W6  + 1)
`define W7P                 (`W7  + 1)
`define W8P                 (`W8  + 1)
`define W9P                 (`W9  + 1)
`define W10P                (`W10 + 1)
`define W11P                (`W11 + 1)
`define W12P                (`W12 + 1)
`define W13P                (`W13 + 1)
`define W14P                (`W14 + 1)
`define W15P                (`W15 + 1)
`define W16P                (`W16 + 1)
`define W17P                (`W17 + 1)
`define W18P                (`W18 + 1)
`define W19P                (`W19 + 1)
`define W20P                (`W20 + 1)
`define W32P                (`W32 + 1)
`define W48P                (`W48 + 1)
`define W64P                (`W64 + 1)



`define W_WT1	(`W1+4)
`define W_WT2	(`W_WT1*2+1)
`define W_WT3	(`W_WT1*3+2)

`define W_WT1P	(`W_WT1+1)


`ifdef SIMULATION_FREQ_133MHZ
	`define	CLK_PERIOD_DIV2			(3.750*`TIME_COEFF) 		// 133.3 MHz
`elsif SIMULATION_FREQ_333MHZ
	`define	CLK_PERIOD_DIV2			(1.500*`TIME_COEFF) 		// 333.3 MHz
`elsif SIMULATION_FREQ_100MHZ
	`define	CLK_PERIOD_DIV2			(5.000*`TIME_COEFF) 		// 100.0 MHz
	`define	EE_CLOCK_PERIOD_DIV2	(2.000*`TIME_COEFF) 		// 250MHz
`elsif SIMULATION_FREQ_200MHZ
	`define	CLK_PERIOD_DIV2			(2.500*`TIME_COEFF) 		// 200.0 MHz
	`define	EE_CLOCK_PERIOD_DIV2	(1.670*`TIME_COEFF) 		// 300MHz
`elsif SIMULATION_FREQ_300MHZ
	`define	CLK_PERIOD_DIV2			(1.670*`TIME_COEFF) 		// 300MHz
`elsif SIMULATION_FREQ_275MHZ
	`define	CLK_PERIOD_DIV2			(1.800*`TIME_COEFF) 		// 275MHz
`elsif SIMULATION_FREQ_250MHZ
	`define	CLK_PERIOD_DIV2			(2.000*`TIME_COEFF) 		// 250MHz	
`else
	`define	CLK_PERIOD_DIV2			(2.500*`TIME_COEFF) 		// 200.0 MHz
	`define	EE_CLOCK_PERIOD_DIV2	(1.670*`TIME_COEFF) 		// 300MHz
`endif 	
`define	CLOCK_PERIOD		(  2 * `CLK_PERIOD_DIV2)
`define	RESET_DELAY			(200 * `CLOCK_PERIOD   )


`ifdef SIMULATION_FREQ_200MHZ
	`define PULSE_CNT_2MS 400000
`elsif SIMULATION_FREQ_100MHZ
	`define PULSE_CNT_2MS 200000
`endif
`define RST_CAM				!rstn_cam

`ifdef SIMULATING
	`define RST          !rstn
	`define ZST          1'b0
	`define ZST_CAM			1'b0
	`define CLK_RST_EDGE posedge clk
	`define CLK_EDGE     posedge clk
	`define RST_EDGE
	`define RST_EDGE_CAM	or negedge rstn_cam
	`define RESET_ACTIVE 1'b0
	`define RESET_IDLE   1'b1
`elsif FPGA_0_XILINX
	`define RST          !rstn
	`define ZST          1'b0
	`define ZST_CAM			1'b0
	`define CLK_RST_EDGE posedge clk
	`define CLK_EDGE     posedge clk
	`define RST_EDGE
	`define RST_EDGE_CAM 	
	`define RESET_ACTIVE 1'b0
	`define RESET_IDLE   1'b1
`else
	`define RST          !rstn
	`define ZST          !rstn
	`define ZST_CAM			!rstn_cam
	`define CLK_RST_EDGE posedge clk or negedge rstn
	`define CLK_EDGE     posedge clk
	`define RST_EDGE    
	`define RST_EDGE_CAM	or negedge rstn_cam
	`define RESET_ACTIVE 1'b0
	`define RESET_IDLE   1'b1
`endif	



`define DELAY1(name, width)    \
	reg		[width:0]		``name``_d1; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	``name``_d1 <= 0;       \
		else 		``name``_d1 <= name;

`define DELAY2(name, width)    \
	reg		[width:0]		``name``_d1, ``name``_d2; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2} <= 0;       \
		else 		{``name``_d1, ``name``_d2} <= 	\
								{name, ``name``_d1};		

`define DELAY4(name, width)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4} <= 0;       \
		else 		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4} <= 	\
								{name, ``name``_d1, ``name``_d2, ``name``_d3};
`define DELAY8(name, width)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8} <= 0;       \
		else 		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8} <= 	\
								{name, ``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7 };

`define DELAY16(name, width)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16 ; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16 } <= 0;       \
		else 		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16 } <= 	\
								{name, ``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15 };

`define DELAY32(name, width)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
							``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
							``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31,``name``_d32; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
					``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
					``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31,``name``_d32 } <= 0;       \
		else 		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
					``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
					``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31,``name``_d32 } <= 	\
							{name,  ``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
							``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
							``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31};

`define DELAYEN8(name, width, en)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8 } <= 0;  \
		else if (en)		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8} <= 	\
								{name, ``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7};
							
`define DELAYEN16(name, width, en)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16 ; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16 } <= 0;       \
		else if (en)		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16 } <= 	\
								{name, ``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15 };
`define DELAYEN32(name, width, en)    \
	reg		[width:0]		``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
							``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
							``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31,``name``_d32; \
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
					``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
					``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31,``name``_d32 } <= 0;       \
		else if (en) 		{``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
					``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
					``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
					``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31,``name``_d32 } <= 	\
							{name,  ``name``_d1, ``name``_d2, ``name``_d3, ``name``_d4, ``name``_d5, ``name``_d6, ``name``_d7, ``name``_d8, \
							``name``_d9, ``name``_d10, ``name``_d11, ``name``_d12, ``name``_d13, ``name``_d14, ``name``_d15, ``name``_d16, \
							``name``_d17, ``name``_d18, ``name``_d19, ``name``_d20,``name``_d21, ``name``_d22,``name``_d23,``name``_d24, \
							``name``_d25, ``name``_d26, ``name``_d27, ``name``_d28,``name``_d29, ``name``_d30,``name``_d31};

							
`define VDELAY(name, length)    \
	reg		[length:0]		``name``_d; \
	always @(*) ``name``_d[0] = name;	\
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	``name``_d[length:1] <= 0;       \
		else 		``name``_d[length:1] <= ``name``_d;

`define VDELAYS(name, width, length)    \
	reg		[length:0][width:0]		``name``_d; \
	always @(*) ``name``_d[0] = name;	\
	always @(`CLK_RST_EDGE)					\
		if (`ZST)	``name``_d[length:1] <= 0;       \
		else 		``name``_d[length:1] <= ``name``_d;





`endif
