// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION


`include "jpc_global.v"

//	d0	v0	d1
//	h0	x	h1
//	d2	v1	d3
//

module zero_coding(
	input				clk,
	input				rstn,
	input		[1:0]	band,
	input 				h0, h1, v0, v1,
	input				d0, d1, d2, d3,	
	input				d,
	output reg	[ 4:0]	ctx,
	output reg			q
	);
	
	wire 			band_eq_1=(band==1);
	wire 			band_eq_3=(band==3);
	
	wire	[1:0] 	h_0=h0+h1;
	wire	[1:0] 	v_0=v0+v1;
	wire	[2:0] 	diag=d0+d1+d2+d3;


	wire	[1:0] 	h=band_eq_1?v_0:h_0;
	wire	[1:0] 	v=band_eq_1?h_0:v_0;
	wire	[2:0] 	h_add_v=h_0+v_0;
	
	wire 	CX_9 = band_eq_3? (diag>2)					:	(h==2);
	wire 	CX_8 = band_eq_3? ((h_add_v>0)&&(diag==2))	:	((h==1)&&(v>0));
	wire 	CX_7 = band_eq_3? ((h_add_v==0)&&(diag==2))	:	((h==1)&&(v==0)&&(diag>0));
	wire 	CX_6 = band_eq_3? ((h_add_v>1)&&(diag==1))	:	((h==1)&&(v==0)&&(diag==0));
	wire 	CX_5 = band_eq_3? ((h_add_v==1)&&(diag==1))	:	((h==0)&&(v==2));
	wire 	CX_4 = band_eq_3? ((h_add_v==0)&&(diag==1))	:	((h==0)&&(v==1));
	wire 	CX_3 = band_eq_3? ((h_add_v>1)&&(diag==0))	:	((h==0)&&(v==0)&&(diag>1));
	wire 	CX_2 = band_eq_3? ((h_add_v==1)&&(diag==0))	:	((h==0)&&(v==0)&&(diag==1));
	wire 	CX_1 = band_eq_3? ((h_add_v==0)&&(diag==0))	:	((h==0)&&(v==0)&&(diag==0));
	
	always @(`CLK_RST_EDGE)
		if (`RST)	ctx <= 0;
		else		
			case({CX_9,CX_8,CX_7,CX_6,CX_5,CX_4,CX_3,CX_2,CX_1})
			9'b1_0000_0000: ctx =4'b1001;
			9'b0_1000_0000: ctx =4'b1000;
			9'b0_0100_0000: ctx =4'b0111;
			9'b0_0010_0000: ctx =4'b0110;
			9'b0_0001_0000: ctx =4'b0101;
			9'b0_0000_1000: ctx =4'b0100;
			9'b0_0000_0100: ctx =4'b0011;
			9'b0_0000_0010: ctx =4'b0010;
			9'b0_0000_0001: ctx =4'b0001;
			default:		ctx =4'bxxxx;
			endcase
	always @(`CLK_RST_EDGE)
		if (`RST)	q <= 0;
		else 		q <= d;
	
endmodule	

/*	
module zero_coding(
	input				clk,
	input				rstn,
	input		[1:0]	band,
	input 				h0, h1, v0, v1,
	input				d0, d1, d2, d3,	input				d,
	output reg	[ 4:0]	ctx,
	output reg			q,	
	);
	
	wire		[1:0]	h  = h0 + h1;
	wire		[1:0]	v  = v0 + v1;
	wire		[2:0]	hv = h + v;
	wire		[2:0]	d_sum = d0 + d1 + d2 + d3;
	always @(`CLK_RST_EDGE)
		if (`RST)	q <= 0;
		else 		q <= d;
	always @(`CLK_RST_EDGE)
		if (`RST)	ctx <= 0;
		else case({band, h, v, d_sum})
			9'b00_00_00_000, 
							 :	ctx <= 8;
		
		
			endcase
endmodule
*/

module sign_coding(
	input				clk,
	input				rstn,
	input 				h0, h1, v0, v1,
	input				sign_h0, sign_h1, sign_v0, sign_v1,
	input				d,
	output reg	[ 4:0]	ctx,
	output reg			q
	);
	
	reg		[1:0]	h_contri;
	reg		[1:0]	v_contri;
	always @(*) 
		casex({h0, sign_h0, h1, sign_h1})
			4'b10_10 : h_contri <= 1;
			4'b11_10 : h_contri <= 0;
			4'b0?_10 : h_contri <= 1;
			4'b10_11 : h_contri <= 0;
			4'b11_11 : h_contri <= -1;
			4'b0?_11 : h_contri <= -1;
			4'b10_0? : h_contri <= 1;
			4'b11_0? : h_contri <= -1;
			4'b0?_0? : h_contri <= 0;
		endcase
	always @(*) 
		casex({v0, sign_v0, v1, sign_v1})
			4'b10_10 : v_contri <= 1;
			4'b11_10 : v_contri <= 0;
			4'b0?_10 : v_contri <= 1;
			4'b10_11 : v_contri <= 0;
			4'b11_11 : v_contri <= -1;
			4'b0?_11 : v_contri <= -1;
			4'b10_0? : v_contri <= 1;
			4'b11_0? : v_contri <= -1;
			4'b0?_0? : v_contri <= 0;
		endcase
	
	always @(`CLK_RST_EDGE)
		if (`ZST)	{ctx, q} <= 0;
		else case({h_contri, v_contri}) 		
			4'b01_01 : {ctx, q} <= {5'd17, d};
			4'b01_00 : {ctx, q} <= {5'd16, d};
			4'b01_11 : {ctx, q} <= {5'd15, d};
			4'b00_01 : {ctx, q} <= {5'd14, d};
			4'b00_00 : {ctx, q} <= {5'd13, d};
			4'b00_11 : {ctx, q} <= {5'd14, !d};
			4'b11_01 : {ctx, q} <= {5'd15, !d};
			4'b11_00 : {ctx, q} <= {5'd16, !d};
			4'b11_11 : {ctx, q} <= {5'd17, !d};
			default    {ctx, q} <= {5'd13, !d};
			endcase
endmodule


module mrc(
	input				clk,
	input				rstn,
	input				h0, h1, v0, v1,
	input				d0, d1, d2, d3,
	
	input				first_time,
	input				d,
	output reg			q,
	output reg	[4:0]	ctx
	);
	
	wire all = h0 | h1 | v0 | v1 | d0| d1 | d2| d3;
	always @(`CLK_RST_EDGE)
		if (`RST)				ctx <= 0;
		else if (!first_time) 	ctx <= 12;
		else 					ctx <= all ? 11 : 10;
	always @(`CLK_RST_EDGE)
		if (`RST)	q <= 0;
		else 		q <= d;
endmodule

module RLC(
	input			clk,
	input			rstn,
	
	input			data_0,
	input			data_1,
	input			data_2,
	input			data_3,
	
	output 		[4:0] 	ctx0,
	output reg			q0,
	output 		[4:0] 	ctx1,
	output reg			q1,
	output reg			q1_en,   // q1 q2 en
	output 		[4:0] 	ctx2,
	output reg			q2
	
	);
	
	assign 	ctx0 = 0;
	assign 	ctx1 = 18;
	assign 	ctx2 = 18;
	always @(`CLK_RST_EDGE)
		if (`RST)	q0 <= 0;
		else 		q0 <= data_0 | data_1 | data_2 | data_3;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	{q1, q2} <= 0;
		else if (data_0)
			{q1, q2} <= 2'b00;
		else if (data_1)
			{q1, q2} <= 2'b01;
		else if (data_2)
			{q1, q2} <= 2'b10;
		else if (data_3)
			{q1, q2} <= 2'b11;
		else
			{q1, q2} <= 2'b00;
	always @(`CLK_RST_EDGE)
		if (`RST)	q1_en <= 0;
		else 		q1_en <= data_0 | data_1 | data_2 | data_3;
endmodule



	