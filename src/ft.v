// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

module ft_53_core(
	input					clk,
	input					rstn,
	
	input					go,
	input		[7:0]		width,
	input		[2:0]		ndecomp,
	
	output reg				cena_src_buf,
	output reg	[13:0]		aa_src_buf,
	input		[`W2:0]		qa_src_buf,

	output reg	[0:7][0:3][3:0]		codeblock_numbps,
	
	output reg	[`W_WT1P*2-1:0]	db_coeff_buf,
	output reg					cenb_coeff_buf,
	output reg	[11:0]			ab_coeff_buf,
	output reg	[3:0]			wenb_coeff_buf,
	
	output reg					ready,
	output						o_en,
	output		[`W_WT1:0]		y0,
	output		[`W_WT1:0]		y1

	);
	
	
	reg		[`W_WT1:0]	x0, x1;
	reg		en;
	
	reg					first_row;
	reg					second_row;
	reg					last_row;
	reg					one_plus_row;
	reg					row_start;
	reg					row_end;
	
	
	

	reg		[2:0]		level;
	reg					level_go;
	reg					level_ready;
	`DELAY16(level_go, 0)
	`DELAY16(level_ready, 0)
	
	reg  	[7:0]	level_width;
	`DELAY16(level_width, 7)
	`DELAY16(level, 2)
	always @(`CLK_RST_EDGE)
		if (`RST)		level_width <= 128;
		else 			level_width <= width >> level;
		
		
	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg					cnt_level_e;
	reg		[ 15 :0]		cnt_level;
	wire				cnt_level_max_f = cnt_level == level_width*level_width/2 + level_width -1;
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_level_e <= 0;
		else if (level_go)			cnt_level_e <= 1;
		else if (cnt_level_max_f)	cnt_level_e <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_level <= 0;
		else 		cnt_level <= cnt_level_e? cnt_level + 1 : 0;
	
	reg		[7:0]	cnt_level_e_d;
	always @(*)	cnt_level_e_d[0] = cnt_level_e;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_level_e_d[7:1] <= 0;
		else 		cnt_level_e_d[7:1] <= cnt_level_e_d;	
	reg		[7:0][15:0]	cnt_level_d;
	always @(*)	cnt_level_d[0] = cnt_level;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_level_d[7:1] <= 0;
		else 		cnt_level_d[7:1] <= cnt_level_d;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	level_ready <= 0;
		else 		level_ready <= one_plus_row & row_end;

	wire			loop_ready = level_ready && level == (ndecomp-1);

	`DELAY16(loop_ready, 0)

	always @(`CLK_RST_EDGE)
		if (`RST)	ready <= 0;
		else 		ready <= loop_ready_d16;
	
	reg				sub_level_go_b2, sub_level_go_b1, sub_level_go;
	always @(`CLK_RST_EDGE)
		if (`RST)	sub_level_go_b2 <= 0;
		// else 		level_go_b2 <= one_plus_row & row_end && level_width > 8;
		else 		sub_level_go_b2 <= one_plus_row & row_end && level != (ndecomp-1);
	always @(`CLK_RST_EDGE)
		if (`RST)	sub_level_go_b1 <= 0;
		else 		sub_level_go_b1 <= sub_level_go_b2;
	always @(`CLK_RST_EDGE)
		if (`RST)	sub_level_go <= 0;
		else 		sub_level_go <= sub_level_go_b1;
	
	
	always @(`CLK_RST_EDGE)
		if (`RST)	level_go <= 0;
		else 		level_go <= sub_level_go_b1 | go ;
		
		
	always @(`CLK_RST_EDGE)
		if (`RST)				level <= 0;
		else if (go)			level <= 0;
		else if (sub_level_go) 	level <= level + 1;
	
	
	// temp_LL
	//  64 *64 /2 items 2^11
	reg		[10:0]	aa_LL_temp_buf;
	reg				cena_LL_temp_buf;
	reg		[10:0]	ab_LL_temp_buf;
	reg		[`W_WT2:0]	db_LL_temp_buf;
	reg				cenb_LL_temp_buf;
	reg		[1:0]	wenb_LL_temp_buf;
	wire	[`W_WT2:0]	qa_LL_temp_buf;
	reg		[`W_WT2:0]	qa_LL_temp_buf_d1;
	
	// 64x64/2 = 
	rfdp2048x24_wp12 LL_temp_buf(
		.CLKA   (clk),
		.CENA   (cena_LL_temp_buf),
		.AA     (aa_LL_temp_buf),
		.QA     (qa_LL_temp_buf),
		.CLKB   (clk),
		.WENB   (wenb_LL_temp_buf),
		.CENB   (cenb_LL_temp_buf),
		.AB     (ab_LL_temp_buf),
		.DB     (db_LL_temp_buf)
		);
	
	
	always @(`CLK_RST_EDGE)
		if (`RST)					aa_LL_temp_buf <= 0;
		else if (level_go)			aa_LL_temp_buf <= 0;
		else if (cnt_level_e_d[1])	aa_LL_temp_buf <= aa_LL_temp_buf + 1;   // 
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cena_LL_temp_buf <= 0;
		else 		cena_LL_temp_buf <= ! (cnt_level_e && level !=0 );

	always @(`CLK_RST_EDGE)
		if (`ZST)	qa_LL_temp_buf_d1 <= 0;
		else 		qa_LL_temp_buf_d1 <= qa_LL_temp_buf;
	
	always @(`CLK_RST_EDGE)
		if (`RST)					aa_src_buf <= 0;
		else if (go)				aa_src_buf <= 0;
		else if (cnt_level_e_d[1])	aa_src_buf <= aa_src_buf + 1;   // 
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cena_src_buf <= 0;
		else 		cena_src_buf <= ~(cnt_level_e && level==0);
	reg		[`W2:0]		qa_src_buf_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	qa_src_buf_d1 <= 0;
		else 		qa_src_buf_d1 <= qa_src_buf;
		
	always @(`CLK_RST_EDGE)
		if (`RST)					{x0, x1} <= 0;
		else if (level == 0)		{x0, x1} <= {{(`W_WT1-`W1){qa_src_buf_d1[`W2]}}, qa_src_buf_d1[`W2-:`W1P], {(`W_WT1-`W1){qa_src_buf_d1[`W1]}}, qa_src_buf_d1[`W1:0]};
		else 						{x0, x1} <= qa_LL_temp_buf_d1;
	always @(`CLK_RST_EDGE)
		if (`RST)	en <= 0;
		else 		en <= cnt_level_e_d[3];
	




	reg		[15:0]	row_cnt;
	reg		[15:0]	col_cnt;

	always @(`CLK_RST_EDGE)
		if (`RST)	{first_row, second_row, last_row, one_plus_row, row_start, row_end} <= 0;
		else begin
			first_row <= cnt_level_d[3] /level_width == 0;
			second_row <= cnt_level_d[3] / level_width == 1;
			last_row  <= cnt_level_d[3] / level_width == level_width/2 -1;
			one_plus_row <= cnt_level_d[3]/ level_width == level_width/2;
			row_start <= cnt_level_d[3] % level_width == 0;
			row_end <= cnt_level_d[3] % level_width == level_width -1;

			row_cnt <= cnt_level_d[3]/level_width;
			col_cnt <= cnt_level_d[3]% level_width;
		end
	
	
	wire	col_level_go = level_go_d4;
	wire	col_level_ready = level_ready_d4;
	wire	col_o_level_go = level_go_d7;
	wire	col_o_level_ready = level_ready_d7;


	wire	row_level_go = level_go_d9;
	wire	row_level_ready = level_ready_d9;

	wire	row_o_level_go = level_go_d14;
	wire	row_o_level_ready = level_ready_d14;

	`DELAY16(row_o_level_go, 0)
	`DELAY16(row_o_level_ready, 0)
	
	wire	[`W_WT1:0]	col_y0, col_y1;
	ft_53_col ft_53_col(
		.clk	(clk),
		.rstn			(rstn),
		.first_row		(first_row),	
		.second_row     (second_row),
		.last_row		(last_row),	
		.one_plus_row	(one_plus_row),	
		.row_start	    (row_start	),
		.row_end	    (row_end	),
		.en			    (en			),
		.x0             (x0),
		.x1             (x1),
		
		
		.col_start		(col_start),
		.col_end		(col_end),
		.o_en			(col_en),
		.y0				(col_y0),
		.y1				(col_y1)
		);
	
	wire	[`W_WT1:0]	row_x0, row_x1;
	ft_53_row_trans ft_53_row_trans(
		.clk				(clk),
		.rstn				(rstn),	
		
		.i_start			(col_start),
		.i_end				(col_end),
	
		.en					(col_en),
		.i0					(col_y0),
		.i1					(col_y1),
		
		.o_start			(ft1_start),
		.o_end				(ft1_end),
		.o_en				(row_en),
		.o0					(row_x0),
		.o1					(row_x1)
		);
		
	ft_53_row ft_53_row (
		.clk				(clk),
		.rstn				(rstn),	
		.first_row			(ft1_start),	
		.last_row			(ft1_end),

		.en			    	(row_en),
		.x0             	(row_x0),
		.x1             	(row_x1),
		
		.col_start			(o_en_start),
		.col_end			(o_en_end),
	
		.o_en				(o_en),
		.y0					(y0),		
		.y1             	(y1)
		);
	
	reg		[7:0]	o_en_start_d;
	always @(*)	o_en_start_d[0] = o_en_start;
	always @(`CLK_RST_EDGE)
		if (`RST)	o_en_start_d[7:1] <= 0;
		else 		o_en_start_d[7:1] <= o_en_start_d;
	reg		[7:0]	o_en_end_d;
	always @(*)	o_en_end_d[0] = o_en_end;
	always @(`CLK_RST_EDGE)
		if (`RST)	o_en_end_d[7:1] <= 0;
		else 		o_en_end_d[7:1] <= o_en_end_d;
		
	reg		o_en_parity;
	always @(`CLK_RST_EDGE)
		if (`RST)	o_en_parity <= 0;
		else 		o_en_parity <= o_en? o_en_parity + 1 : 0;
	reg		[7:0]	o_en_line_parity;
	always @(`CLK_RST_EDGE)
		if (`RST)	o_en_line_parity <= 0;
		else 		o_en_line_parity <= o_en? o_en_line_parity + (o_en_end&o_en_parity) : 0;
	
	`DELAY4(o_en_line_parity, 7)

	always @(`CLK_RST_EDGE)
		if (`RST)				cenb_LL_temp_buf <= 1;
		else 					cenb_LL_temp_buf <= !(!o_en_parity & o_en);
	always @(`CLK_RST_EDGE)
		if (`RST)				wenb_LL_temp_buf <= 1;
		else 					wenb_LL_temp_buf <= {o_en_line_parity[0], !o_en_line_parity[0]};
	always @(`CLK_RST_EDGE)
		if (`RST)						db_LL_temp_buf <= 0;
		else if (!o_en_parity & o_en)	db_LL_temp_buf <= {y0, y0};	
	always @(`CLK_RST_EDGE)
		if (`RST)						ab_LL_temp_buf <= 0;
		else if (!o_en)					ab_LL_temp_buf <= 0;
		else if (!cenb_LL_temp_buf)	
			if (!o_en_line_parity_d1[0] & o_en_end_d[1])	ab_LL_temp_buf <= ab_LL_temp_buf + 1 - level_width_d6/2;
			else 						ab_LL_temp_buf <= ab_LL_temp_buf + 1;
	
	
	
	//  LL  HL 
	// 	LH	HH 

	// o_en 			  ll_en
	// parity   0   1  2  3   4  5  6  7
	// y0:  	LL LH  LL LH  LL LH  LL LH
	// y1:  	HL HH  HL HH  HL HH  HL HH
	//
	`DELAY4(o_en, 0)
	
	reg		[15:0]	coeff_cnt;	
	`DELAY4(coeff_cnt, 15)
	always @(`CLK_RST_EDGE)
		if (`RST)	coeff_cnt <= 0;
		else 		coeff_cnt <= o_en? coeff_cnt + 1 : 0;

	wire	co_en_ahead = o_en && coeff_cnt[1:0]==0;
	`DELAY4(co_en_ahead, 0)
	wire	co_en = co_en_ahead_d3;
	`DELAY4(co_en, 0)

	`DELAY8(y0, `W_WT1)
	`DELAY8(y1, `W_WT1)
	
	wire	LL_en = co_en;
	wire	HL_en = co_en_d1;
	wire	LH_en = co_en_d2;
	wire	HH_en = co_en_d3;

	`DELAY4(LL_en, 0)
	`DELAY4(HL_en, 0)
	`DELAY4(LH_en, 0)
	`DELAY4(HH_en, 0)
	reg			[`W_WT1:0]		coeff0, coeff1;
	always @(`CLK_RST_EDGE)
		if (`ZST)			{coeff0, coeff1} <= 0;
		else if (LL_en)		{coeff0, coeff1} <= {y0_d3, y0_d1 };
		else if (HL_en)		{coeff0, coeff1} <= {y1_d4, y1_d2 };
		else if (LH_en)		{coeff0, coeff1} <= {y0_d4, y0_d2 };
		else if (HH_en)		{coeff0, coeff1} <= {y1_d5, y1_d3 };

	reg			[`W_WT1:0]		abs_coeff0, abs_coeff1;
	always @(*) begin
		abs_coeff0 = coeff0[`W_WT1]?  0-coeff0[`W_WT1:0]	: coeff0[`W_WT1:0];
		abs_coeff1 = coeff1[`W_WT1]?  0-coeff1[`W_WT1:0]	: coeff1[`W_WT1:0];
		end
	reg		[`W_WT1:0]		abs_LL, abs_HL, abs_LH, abs_HH ; 
	always @(`CLK_RST_EDGE)
		if (`RST)					abs_LL <= 0;
		else if (row_o_level_go_d4)	abs_LL <= 0;
		else if (LL_en_d1) 			abs_LL <= abs_LL |  abs_coeff0 | abs_coeff1;
	always @(`CLK_RST_EDGE)
		if (`RST)					abs_HL <= 0;
		else if (row_o_level_go_d4)	abs_HL <= 0;
		else if (HL_en_d1) 			abs_HL <= abs_HL |  abs_coeff0 | abs_coeff1;
	always @(`CLK_RST_EDGE)
		if (`RST)					abs_LH <= 0;
		else if (row_o_level_go_d4)	abs_LH <= 0;
		else if (LH_en_d1) 			abs_LH <= abs_LH |  abs_coeff0 | abs_coeff1;
	always @(`CLK_RST_EDGE)
		if (`RST)					abs_HH <= 0;
		else if (row_o_level_go_d4)	abs_HH <= 0;
		else if (HH_en_d1) 			abs_HH <= abs_HH |  abs_coeff0 | abs_coeff1;

	reg		[3:0]	numbps_LL, numbps_HL, numbps_LH, numbps_HH ; 
	always @(`CLK_RST_EDGE)
		if (`RST)	numbps_LL <= 0;
		else 		numbps_LL <= bit_cnt(abs_LL);
	always @(`CLK_RST_EDGE)
		if (`RST)	numbps_HL <= 0;
		else 		numbps_HL <= bit_cnt(abs_HL);
	always @(`CLK_RST_EDGE)
		if (`RST)	numbps_LH <= 0;
		else 		numbps_LH <= bit_cnt(abs_LH);
	always @(`CLK_RST_EDGE)
		if (`RST)	numbps_HH <= 0;
		else 		numbps_HH <= bit_cnt(abs_HH);
	
	always @(`CLK_RST_EDGE)
		if (`RST)				codeblock_numbps <= 0;
		else if (LL_en_d3)		codeblock_numbps[level][0] <= numbps_LL;
		else if (HL_en_d3)		codeblock_numbps[level][1] <= numbps_HL;
		else if (LH_en_d3)		codeblock_numbps[level][2] <= numbps_LH;
		else if (HH_en_d3)		codeblock_numbps[level][3] <= numbps_HH;

	always @(`CLK_RST_EDGE)
		if (`RST)	cenb_coeff_buf <= 1;
		else 		cenb_coeff_buf <= ~(LL_en | HL_en | LH_en | HH_en);
	always @(`CLK_RST_EDGE)
		if (`RST)		db_coeff_buf <= 0;
		else if (LL_en)	db_coeff_buf <= {y0_d3, y0_d1 };
		else if (HL_en)	db_coeff_buf <= {y1_d4, y1_d2 };
		else if (LH_en)	db_coeff_buf <= {y0_d4, y0_d2 };
		else if (HH_en)	db_coeff_buf <= {y1_d5, y1_d3 };

	wire [15:0]		lvl_size =  (`TILE_WIDTH * `TILE_WIDTH )>> (( level_d11 + 1) * 2);	
	wire [15:0]		lvl_width =  (`TILE_WIDTH)>> ( level_d11 + 1);	
	
	wire	[15:0]	line_cnt = coeff_cnt_d3 /(lvl_width*2);		// TODO
	wire	[15:0]	hor_cnt = coeff_cnt_d3 % (lvl_width*2);

	always @(`CLK_RST_EDGE)
		if (`RST)		ab_coeff_buf <= 0;
		else if (LL_en)	ab_coeff_buf <= line_cnt/4 * lvl_width/2 + hor_cnt/4 + lvl_size/8 * 0;
		else if (HL_en)	ab_coeff_buf <= line_cnt/4 * lvl_width/2 + hor_cnt/4 + lvl_size/8 * 1;
		else if (LH_en)	ab_coeff_buf <= line_cnt/4 * lvl_width/2 + hor_cnt/4 + lvl_size/8 * 2;
		else if (HH_en)	ab_coeff_buf <= line_cnt/4 * lvl_width/2 + hor_cnt/4 + lvl_size/8 * 3;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	wenb_coeff_buf <= 4'b1111;
		else case(o_en_line_parity_d3[1:0])
			2'b00: wenb_coeff_buf <= 4'b0111;
			2'b01: wenb_coeff_buf <= 4'b1011;
			2'b10: wenb_coeff_buf <= 4'b1101;
			2'b11: wenb_coeff_buf <= 4'b1110;
			endcase

	function [3:0] bit_cnt(input [`W_WT1:0] d);
		begin
			for(int i=`W_WT1; i>0; i--)
				if(d[i-1]) begin
					bit_cnt = i;
					return bit_cnt;
				end
			bit_cnt = 0;	
			return bit_cnt;
		
		end
	endfunction

endmodule	

module ft_53_col(
	input					clk,
	input					rstn,
	input					first_row,
	input					second_row,
	input					last_row,
	input					one_plus_row,
	input					row_start,
	input					row_end,
	input					en,
	
	input		[`W_WT1:0]		x0,
	input		[`W_WT1:0]		x1,
	
	output	reg				col_start,
	output	reg				col_end,
	output	reg				o_en,
	output 	reg	[`W_WT1:0]		y0,
	output 	reg	[`W_WT1:0]		y1
	);
	
	
	reg	signed	[`W_WT1:0]		x0_pre, x1_pre;
	reg	signed	[`W_WT1:0]		x0_r, x1_r;
	reg	signed	[`W_WT1:0]		y1_pre;
	
	reg	signed	[`W_WT1:0]		y1_b1;
	
	reg		[ 6:0]			col_cnt;
	reg		[ 6:0]			row_cnt;
	reg		[0:127][`W_WT3:0]	pre_mem;
	
	

	`DELAY4(en, 0)
	`DELAY4(first_row, 0)
	`DELAY4(second_row, 0)
	`DELAY4(last_row, 0)
	`DELAY4(one_plus_row, 0)
	`DELAY4(row_start, 0)
	`DELAY4(row_end, 0)

	`DELAY4(col_cnt, 6)
	`DELAY4(x0_r, `W_WT1)
	`DELAY4(x1_r, `W_WT1)

	always @(`CLK_RST_EDGE)
		if (`RST)		col_cnt <= 0;
		else if (en)	col_cnt <= row_end? 0 : col_cnt + 1;
	
	always @(`CLK_RST_EDGE)
		if (`RST)				row_cnt <= 0;
		else if (first_row)		row_cnt <= 0;
		else if (en&row_end)	row_cnt <= row_cnt + 1;
		
	always @(`CLK_RST_EDGE)
		if (`RST)		{x0_r, x1_r} <= 0;
		else if (en)	{x0_r, x1_r} <= {x0, x1};
	always @(`CLK_RST_EDGE)
		if (`RST)		{x0_pre, x1_pre, y1_pre} <= 0;
		else if (en)	{x0_pre, x1_pre, y1_pre} <= row_start? pre_mem[0] : pre_mem[col_cnt];
	always @(`CLK_RST_EDGE)
		if (`RST)			pre_mem <= 0;
		else if(en_d3) 		pre_mem[col_cnt_d3] <= {x0_r_d2, x1_r_d2, y1};
	
	reg	signed	[`W_WT1:0]		y1_pre_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	y1_pre_d1 <= 0;
		else 		y1_pre_d1 <= y1_pre;
	reg	signed	[`W_WT1:0]		x0_pre_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	x0_pre_d1 <= 0;
		else 		x0_pre_d1 <= x0_pre;
	
		
	wire signed	[`W_WT1+1 :0]	x0_plus_pre = $signed(x0_r) + $signed(x0_pre);
	
	// y1 high pass
	always @(`CLK_RST_EDGE)
		if (`RST)					y1_b1 <= 0;
		else if (one_plus_row_d1)	y1_b1 <= $signed(x1_pre) - $signed(x0_pre);		
		else 						y1_b1 <= x1_pre - x0_plus_pre[`W_WT1+1:1];
	
	// y0 low pass 
	wire signed	[`W_WT1+1 :0]	y1_plus_pre = y1_b1 + (second_row_d2? y1_b1 : y1_pre_d1) + 2;	
	always @(`CLK_RST_EDGE)
		if (`RST)	y0 <= 0;
		else 		y0 <= x0_pre_d1 + $signed(y1_plus_pre[`W_WT1+1:2]);

	always @(`CLK_RST_EDGE)
		if (`RST)	y1 <= 0;
		else 		y1 <= y1_b1;
	always @(*) o_en = en_d3 & !first_row_d3;
	
	always @(*) col_start = row_start_d3& !first_row_d3;
	always @(*) col_end = row_end_d3 & !first_row_d3;
	
endmodule

module ft_53_row_trans(
	input				clk,
	input				rstn,
	
	input				i_start,
	input				i_end,
	input				en,
	input	[`W_WT1:0]		i0,
	input	[`W_WT1:0]		i1, 
	
	output	reg				o_start,
	output	reg				o_end,
	output	reg				o_en,
	output	reg		[`W_WT1:0]		o0,
	output	reg		[`W_WT1:0]		o1
	);
	
	`DELAY4(i0, `W_WT1)
	`DELAY4(i1, `W_WT1)
	`DELAY4(en, 0)
	`DELAY4(i_start, 0)
	`DELAY4(i_end, 0)
	
	reg		en_parity;
	`DELAY4(en_parity, 0)	
	always @(`CLK_RST_EDGE)
		if (`RST)		en_parity <= 0;
		else if (en) 	en_parity <= en_parity + 1;

	// i0  i0_d1
	// 			 x0
	// 		
	// 
	reg		[`W_WT1:0]	x0, x1;
	always @(`CLK_RST_EDGE)
		if (`RST)					{o0, o1} <= 0;
		else if (!en_parity_d1) 	{o0, o1} <= {i0_d1, i0};			// 
		else 						{o0, o1} <= {i1_d2, i1_d1};

	always @(`CLK_RST_EDGE)
		if (`RST)					o_start <= 0;
		else if (!en_parity_d1) 	o_start <= i_start_d1;
		else						o_start <= i_start_d2;

	always @(`CLK_RST_EDGE)
		if (`RST)					o_end <= 0;
		else if (!en_parity_d1) 	o_end <= i_end;
		else						o_end <= i_end_d1;
		
	reg		x_en;
	always @(`CLK_RST_EDGE)
		if (`RST)	o_en <= 0;
		else 		o_en <= en_d1;
endmodule


module ft_53_row(
	input					clk,
	input					rstn,
	input					first_row,
	input					last_row,
	
	input					en,
	input		[`W_WT1:0]		x0,
	input		[`W_WT1:0]		x1,
	
	
	output	reg				col_start,
	output	reg				col_end,
	
	output	reg				o_en,
	output	reg	[`W_WT1:0]		y0,		// LL0  LH0  LL1  LH1
	output	reg	[`W_WT1:0]		y1		// HL0  HH0  HL1  HH1
	);
	
	
	reg	signed	[`W_WT1:0]		x0_pre, x1_pre;
	reg	signed	[`W_WT1:0]		x0_r, x1_r;
	reg	signed	[`W_WT1:0]		y1_pre;
	reg	signed	[`W_WT1:0]		y1_b1;

	// en
	// col_cnt	
		// y1_pre	y1_pre_d1
		// x0_pre			y0
		// x1_pre	y1_b1	y1
		// x0_r
		// x1_r

	`DELAY8(en, 0)		
	`DELAY8(first_row, 0)		
	`DELAY8(last_row, 0)		
	wire			second_row = first_row_d2;
	
	`DELAY4(second_row, 0)
	`DELAY4(x0_r, `W_WT1)
	`DELAY4(x1_r, `W_WT1)
		
	always @(`CLK_RST_EDGE)
		if (`RST)		{x0_r, x1_r} <= 0;
		else if (en)	{x0_r, x1_r} <= {x0, x1};
	always @(`CLK_RST_EDGE)
		if (`RST)		{x0_pre, x1_pre, y1_pre} <= 0;
		else 			{x0_pre, x1_pre, y1_pre} <= {x0_r_d1, x1_r_d1, y1_b1};

	reg	signed	[`W_WT1:0]		y1_pre_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	y1_pre_d1 <= 0;
		else 		y1_pre_d1 <= y1_pre;
	reg	signed	[`W_WT1:0]		x0_pre_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	x0_pre_d1 <= 0;
		else 		x0_pre_d1 <= x0_pre;
	
	
	wire signed	[`W_WT1+1 :0]	x0_plus_pre = $signed(x0_r) + $signed(x0_pre);
	always @(`CLK_RST_EDGE)
		if (`RST)				y1_b1 <= 0;
		else if (last_row_d3)	y1_b1 <= $signed(x1_r_d2) - $signed(x0_r_d2);
		else 					y1_b1 <= $signed(x1_pre) -  $signed(x0_plus_pre[`W_WT1+1:1]);
		
	wire signed	[`W_WT1+1 :0]	y1_plus_pre = y1_b1 + (second_row_d2? y1_b1 : y1_pre_d1) + 2;	
	always @(`CLK_RST_EDGE)
		if (`RST)	y0 <= 0;
		else 		y0 <= x0_pre_d1 + $signed(y1_plus_pre[`W_WT1+1:2]);
	always @(`CLK_RST_EDGE)
		if (`RST)	y1 <= 0;
		else 		y1 <= y1_b1;
	always @(*) o_en = en_d3 & !first_row_d3 || en_d5 & last_row_d5;
	
	always @(*) col_start = first_row_d5;
	always @(*) col_end = last_row_d5;

endmodule
