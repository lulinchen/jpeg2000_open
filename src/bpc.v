// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

//band  0:LL 1:HL 2:LH 3:HH
// 	0	1
//	2	3
//	d0	v0	d1
//	h0	x	h1
//	d2	v1	d3
//

module bpc(
	input					clk,
	input					rstn,
	
	input	[`W_WT1:0]		coeff0,
	input	[`W_WT1:0]		coeff1,
	input	[`W_WT1:0]		coeff2,
	input	[`W_WT1:0]		coeff3,
	input					coef_en,
	
	input					first_row,
	input					first_col,
	input					last_col,
	
	
	input					first_plane,
	input	[1:0]			band,
	input	[3:0]			bit_pos,


	input					mq_sig_e,
	input					mq_ref_e,
	input					mq_cln_e,
	
	output					sig_pass_empty,
	output					ref_pass_empty,
	output					cln_pass_empty,

	output					sig_pass_ctxd_en,
	output	[5:0]			sig_pass_ctx,
	output					sig_pass_d,

	output					cln_pass_ctxd_en,
	output	[5:0]			cln_pass_ctx,
	output					cln_pass_d,

	output					ref_pass_ctxd_en,
	output	[5:0]			ref_pass_ctx,
	output					ref_pass_d,

	output					pp
	
	);
	
	`DELAY8(coef_en, 0)
	`DELAY8(first_row, 0)
	`DELAY8(first_col, 0)
	`DELAY8(last_col, 0)
	`DELAY8(first_plane, 0)

	reg		[5:0]	col_cnt;
	`DELAY8(col_cnt, 5)	
	always @(`CLK_RST_EDGE)
		if (`RST)			col_cnt <= 0;
		else if (coef_en) 	col_cnt <= last_col? 0 : col_cnt + 1;	
		else 				col_cnt <= 	0;
	reg		[0:63]	top_sig_buf;
	reg		[0:63]	top_sign_buf;
	reg		[0:63]	top_sig_buf_cln;
	
	
	reg		A_pre, B_pre, C_pre, D_pre;
	reg		A0, B0, C0, D0, E0;  
	reg		A1, B1, C1, D1, E1; 
	reg		A2, B2, C2, D2, E2; 
	reg		A3, B3, C3, D3, E3; 
	
	reg		coeff_bit0, coeff_bit1, coeff_bit2, coeff_bit3;
	reg		sig_bit0, sig_bit1, sig_bit2, sig_bit3;
	reg		sign_bit0, sign_bit1, sign_bit2, sign_bit3;
	reg		ref_bit0, ref_bit1, ref_bit2, ref_bit3;
	// always @(`CLK_RST_EDGE)
		// if (`RST)	{coeff_bit0, coeff_bit1, coeff_bit2, coeff_bit3} <= 0;
		// else begin
			// coeff_bit0 <= coeff0 & (1<<bit_pos) != 0;
			// coeff_bit1 <= coeff1 & (1<<bit_pos) != 0;
			// coeff_bit2 <= coeff2 & (1<<bit_pos) != 0;
			// coeff_bit3 <= coeff3 & (1<<bit_pos) != 0;
		// end
	wire	[`W_WT1:0]		one_shift = (1<<bit_pos);
	always @(*)
		begin
			coeff_bit0 = (coeff0 & one_shift) != 0;
			coeff_bit1 = (coeff1 & one_shift) != 0;
			coeff_bit2 = (coeff2 & one_shift) != 0;
			coeff_bit3 = (coeff3 & one_shift) != 0;
		end              
	always @(*)
		begin
			sign_bit0 = (coeff0[`W_WT1]) != 0;
			sign_bit1 = (coeff1[`W_WT1]) != 0;
			sign_bit2 = (coeff2[`W_WT1]) != 0;
			sign_bit3 = (coeff3[`W_WT1]) != 0;
		end
	always @(*)
		begin
			sig_bit0 = (coeff0[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0;
			sig_bit1 = (coeff1[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0;
			sig_bit2 = (coeff2[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0;
			sig_bit3 = (coeff3[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0;
		end
	always @(*)
		begin
			ref_bit0 = (coeff0[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0 && (coeff0[`W_WT1-1:0] & (-1<<(bit_pos+2))) == 0;
			ref_bit1 = (coeff1[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0 && (coeff1[`W_WT1-1:0] & (-1<<(bit_pos+2))) == 0;
			ref_bit2 = (coeff2[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0 && (coeff2[`W_WT1-1:0] & (-1<<(bit_pos+2))) == 0;
			ref_bit3 = (coeff3[`W_WT1-1:0] & (-1<<(bit_pos+1))) != 0 && (coeff3[`W_WT1-1:0] & (-1<<(bit_pos+2))) == 0;
		end
		
	
	// for ref pass
	reg		sig_An1, sig_Bn1, sig_Cn1, sig_Dn1, sig_En1;
	reg		sig_A0,  sig_B0,  sig_C0,  sig_D0,  sig_E0;  
	reg		sig_A1,  sig_B1,  sig_C1,  sig_D1,  sig_E1; 
	reg		sig_A2,  sig_B2,  sig_C2,  sig_D2,  sig_E2; 
	reg		sig_A3,  sig_B3,  sig_C3,  sig_D3,  sig_E3; 

	// for clean pass
	reg		sig2_An1, sig2_Bn1, sig2_Cn1, sig2_Dn1, sig2_En1;
	reg		sig2_A0,  sig2_B0,  sig2_C0,  sig2_D0,  sig2_E0;  
	reg		sig2_A1,  sig2_B1,  sig2_C1,  sig2_D1,  sig2_E1; 
	reg		sig2_A2,  sig2_B2,  sig2_C2,  sig2_D2,  sig2_E2; 
	reg		sig2_A3,  sig2_B3,  sig2_C3,  sig2_D3,  sig2_E3; 


	
	reg		sign_An1, sign_Bn1, sign_Cn1, sign_Dn1, sign_En1;
	reg		sign_A0,  sign_B0,  sign_C0,  sign_D0,  sign_E0;  
	reg		sign_A1,  sign_B1,  sign_C1,  sign_D1,  sign_E1; 
	reg		sign_A2,  sign_B2,  sign_C2,  sign_D2,  sign_E2; 
	reg		sign_A3,  sign_B3,  sign_C3,  sign_D3,  sign_E3; 


	reg		ref_A0,  ref_B0,  ref_C0,  ref_D0,  ref_E0;  
	reg		ref_A1,  ref_B1,  ref_C1,  ref_D1,  ref_E1; 
	reg		ref_A2,  ref_B2,  ref_C2,  ref_D2,  ref_E2; 
	reg		ref_A3,  ref_B3,  ref_C3,  ref_D3,  ref_E3; 
	

	wire		qa_sig_buf = first_row? 0 : top_sig_buf[col_cnt];
	wire		qa_sign_buf = first_row? 0 : top_sign_buf[col_cnt];
	wire		qa_sig_buf_cln = first_row_d2? 0 : top_sig_buf_cln[col_cnt_d2];


	wire	 		  sig_D0_new;
	wire	 		  sig_D1_new;
	wire	 		  sig_D2_new;
	wire	 		  sig_D3_new;

	wire	oth_sig0 =  !first_col_d2&sig_Cn1| sig_Dn1| !last_col_d2 &sig_En1|
                        !first_col_d2&sig_C0|           !last_col_d2 &sig_E0|
                        !first_col_d2&sig_C1|  sig_D1|  !last_col_d2 &sig_E1      ; 

	wire	oth_sig1 =  !first_col_d2&sig_C0|  sig_D0_new  |  !last_col_d2 &sig_E0| 
                        !first_col_d2&sig_C1|  		    	  !last_col_d2 &sig_E1|
                        !first_col_d2&sig_C2|  sig_D2|  	  !last_col_d2 &sig_E2       ;

	wire	oth_sig2 =  !first_col_d2&sig_C1|  sig_D1_new  |  !last_col_d2 &sig_E1|
                        !first_col_d2&sig_C2|  		    	  !last_col_d2 &sig_E2|
                        !first_col_d2&sig_C3|  sig_D3|  	  !last_col_d2 &sig_E3      ;
	
	wire	oth_sig3 =  !first_col_d2&sig_C2|  sig_D2_new  |  !last_col_d2 &sig_E2|
                        !first_col_d2&sig_C3|  				  !last_col_d2 &sig_E3    ;

	assign	 sig_D0_new = 	sig_D0 || oth_sig0 && D0;
	assign	 sig_D1_new = 	sig_D1 || oth_sig1 && D1;
	assign	 sig_D2_new = 	sig_D2 || oth_sig2 && D2;
	assign	 sig_D3_new = 	sig_D3 || oth_sig3 && D3;


	always @(`CLK_RST_EDGE)
		if (`RST)	{	A0, B0, C0, D0, E0,
						A1, B1, C1, D1, E1,
						A2, B2, C2, D2, E2,
						A3, B3, C3, D3, E3 } <= 0;
		// else if (coef_en)	
		else 
				{	A0, B0, C0, D0, E0,
					A1, B1, C1, D1, E1,
					A2, B2, C2, D2, E2,
					A3, B3, C3, D3, E3 } <=  {  B0, C0, D0, E0, coeff_bit0,
												B1, C1, D1, E1, coeff_bit1,
												B2, C2, D2, E2, coeff_bit2,
												B3, C3, D3, E3, coeff_bit3};
	always @(`CLK_RST_EDGE)
		if (`RST)	{sig_An1, sig_Bn1, sig_Cn1, sig_Dn1, sig_En1,
		             sig_A0,  sig_B0,  sig_C0,  sig_D0,  sig_E0,  
		             sig_A1,  sig_B1,  sig_C1,  sig_D1,  sig_E1, 
		             sig_A2,  sig_B2,  sig_C2,  sig_D2,  sig_E2, 
		             sig_A3,  sig_B3,  sig_C3,  sig_D3,  sig_E3 } <= 0;
		// else if (coef_en)
		else 
					{sig_An1, sig_Bn1, sig_Cn1, sig_Dn1, sig_En1,
		             sig_A0,  sig_B0,  sig_C0,  sig_D0,  sig_E0,  
		             sig_A1,  sig_B1,  sig_C1,  sig_D1,  sig_E1, 
		             sig_A2,  sig_B2,  sig_C2,  sig_D2,  sig_E2, 
		             sig_A3,  sig_B3,  sig_C3,  sig_D3,  sig_E3 } <=
							{sig_Bn1, sig_Cn1, sig_Dn1,     sig_En1, qa_sig_buf, 
							 sig_B0,  sig_C0,  sig_D0_new,  sig_E0, sig_bit0, 
							 sig_B1,  sig_C1,  sig_D1_new,  sig_E1, sig_bit1,
							 sig_B2,  sig_C2,  sig_D2_new,  sig_E2, sig_bit2,
							 sig_B3,  sig_C3,  sig_D3_new,  sig_E3, sig_bit3  };
	

	wire	sig_B0_new = sig_B0 | B0;
	wire	sig_B1_new = sig_B1 | B1;
	wire	sig_B2_new = sig_B2 | B2;
	wire	sig_B3_new = sig_B3 | B3;
	always @(`CLK_RST_EDGE)
		if (`RST)	{sig2_An1, sig2_Bn1, sig2_Cn1, sig2_Dn1, sig2_En1,
					 sig2_A0,  sig2_B0,  sig2_C0,  sig2_D0,  sig2_E0,  
		             sig2_A1,  sig2_B1,  sig2_C1,  sig2_D1,  sig2_E1, 
		             sig2_A2,  sig2_B2,  sig2_C2,  sig2_D2,  sig2_E2, 
		             sig2_A3,  sig2_B3,  sig2_C3,  sig2_D3,  sig2_E3 } <= 0;
		// else if (coef_en)
		else 		{sig2_An1, sig2_Bn1, sig2_Cn1,
					 sig2_A0,  sig2_B0,  sig2_C0,    
		             sig2_A1,  sig2_B1,  sig2_C1,   
		             sig2_A2,  sig2_B2,  sig2_C2,   
		             sig2_A3,  sig2_B3,  sig2_C3  } <=
							{sig2_Bn1, sig2_Cn1,  qa_sig_buf_cln,
							 sig_B0_new,  sig2_C0,  sig_D0_new, 
							 sig_B1_new,  sig2_C1,  sig_D1_new,
							 sig_B2_new,  sig2_C2,  sig_D2_new,
							 sig_B3_new,  sig2_C3,  sig_D3_new};
	 
	always @(`CLK_RST_EDGE)
		if (`RST)	{sign_An1, sign_Bn1, sign_Cn1, sign_Dn1, sign_En1,
		             sign_A0,  sign_B0,  sign_C0,  sign_D0,  sign_E0,  
		             sign_A1,  sign_B1,  sign_C1,  sign_D1,  sign_E1, 
		             sign_A2,  sign_B2,  sign_C2,  sign_D2,  sign_E2, 
		             sign_A3,  sign_B3,  sign_C3,  sign_D3,  sign_E3 } <= 0;
		// else if (coef_en)
		else
					{sign_An1, sign_Bn1, sign_Cn1, sign_Dn1, sign_En1,
		             sign_A0,  sign_B0,  sign_C0,  sign_D0,  sign_E0,  
		             sign_A1,  sign_B1,  sign_C1,  sign_D1,  sign_E1, 
		             sign_A2,  sign_B2,  sign_C2,  sign_D2,  sign_E2, 
		             sign_A3,  sign_B3,  sign_C3,  sign_D3,  sign_E3 } <=
							{sign_Bn1, sign_Cn1, sign_Dn1, sign_En1, qa_sign_buf, 
							 sign_B0,  sign_C0,  sign_D0,  sign_E0, sign_bit0, 
							 sign_B1,  sign_C1,  sign_D1,  sign_E1, sign_bit1,
							 sign_B2,  sign_C2,  sign_D2,  sign_E2, sign_bit2,
							 sign_B3,  sign_C3,  sign_D3,  sign_E3, sign_bit3  };
	always @(`CLK_RST_EDGE)
		if (`RST)	{ref_A0,  ref_B0,  ref_C0,  ref_D0,  ref_E0,  
		             ref_A1,  ref_B1,  ref_C1,  ref_D1,  ref_E1, 
		             ref_A2,  ref_B2,  ref_C2,  ref_D2,  ref_E2, 
		             ref_A3,  ref_B3,  ref_C3,  ref_D3,  ref_E3 } <= 0;
		// else if (coef_en)
		else
		            {ref_A0,  ref_B0,  ref_C0,  ref_D0,  ref_E0,  
		             ref_A1,  ref_B1,  ref_C1,  ref_D1,  ref_E1, 
		             ref_A2,  ref_B2,  ref_C2,  ref_D2,  ref_E2, 
		             ref_A3,  ref_B3,  ref_C3,  ref_D3,  ref_E3 } <=
							{ref_B0,  ref_C0,  ref_D0,  ref_E0, ref_bit0, 
							 ref_B1,  ref_C1,  ref_D1,  ref_E1, ref_bit1,
							 ref_B2,  ref_C2,  ref_D2,  ref_E2, ref_bit2,
							 ref_B3,  ref_C3,  ref_D3,  ref_E3, ref_bit3  };
							 
	always @(`CLK_RST_EDGE)
		if (`RST)				top_sig_buf <= 0;
		else if (coef_en_d4)	top_sig_buf[col_cnt_d4] <= sig_B3;

	always @(`CLK_RST_EDGE)
		if (`RST)				top_sig_buf_cln <= 0;
		else if (coef_en_d4)	top_sig_buf_cln[col_cnt_d4] <= sig_B3_new;

	always @(`CLK_RST_EDGE)
		if (`RST)				top_sign_buf <= 0;
		else if (coef_en_d4)	top_sign_buf[col_cnt_d4] <= sign_B3;

	// wire		[4:0]	ctx_rlc0, ctx_rlc1, ctx_rlc2;
	// wire				q_rlc0, q_rlc1, q_rlc2;
	// wire		[4:0]	ctx_zc0, ctx_zc1, ctx_zc2, ctx_zc3;
	// wire				q_zc0, q_zc1, q_zc2, q_zc3;
	// wire		[4:0]	ctx_sc0, ctx_sc1, ctx_sc2, ctx_sc3;
	// wire				q_sc0, q_sc1, q_sc2, q_sc3;
	// wire		[4:0]	ctx_mrc0, ctx_mrc1, ctx_mrc2, ctx_mrc3;
	// wire				q_mrc0, q_mrc1, q_mrc2, q_mrc3;

	wire		[4:0]	ctx_rlc0;
	wire				q_rlc0;
	wire		[4:0]	ctx_rlc1;
	wire				q_rlc1;
	wire		[4:0]	ctx_rlc2;
	wire				q_rlc2;

	wire		[4:0]	ctx_zc0;
	wire				q_zc0;
	wire		[4:0]	ctx_zc1;
	wire				q_zc1;
	wire		[4:0]	ctx_zc2;
	wire				q_zc2;
	wire		[4:0]	ctx_zc3;
	wire				q_zc3;

	wire		[4:0]	ctx_sc0;
	wire				q_sc0;
	wire		[4:0]	ctx_sc1;
	wire				q_sc1;
	wire		[4:0]	ctx_sc2;
	wire				q_sc2;
	wire		[4:0]	ctx_sc3;
	wire				q_sc3;

	wire		[4:0]	ctx_mrc0;
	wire				q_mrc0;
	wire		[4:0]	ctx_mrc1;
	wire				q_mrc1;
	wire		[4:0]	ctx_mrc2;
	wire				q_mrc2;
	wire		[4:0]	ctx_mrc3;
	wire				q_mrc3;
	
	zero_coding zc0(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d2& sig_C0), 
		.h1				(!last_col_d2 & sig_E0), 
		.v0				(!first_row_d2 & sig_Dn1), 
		.v1 			(sig_D1), 
		.d0				(!first_col_d2& sig_Cn1),
		.d1				(!last_col_d2 & sig_En1),
		.d2				(!first_col_d2& sig_C1),
		.d3				(!last_col_d2 & sig_E1),
		.d				(D0),
		.ctx			(ctx_zc0),
		.q				(q_zc0)
		);
		
	sign_coding sc0(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d2& sig_C0), 
		.h1				(!last_col_d2 & sig_E0), 
		.v0				(!first_row_d2 & sig_Dn1), 
		.v1 			(sig_D1), 
		
		.sign_h0		(sign_C0), 
		.sign_h1		(sign_E0), 
		.sign_v0		(sign_Dn1), 
		.sign_v1 		(sign_D1), 
		
		.d				(sign_D0),
		.ctx			(ctx_sc0),
		.q				(q_sc0)
		);
	

		
	zero_coding zc1(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d2& sig_C1), 
		.h1				(!last_col_d2 & sig_E1), 
		.v0				(sig_D0_new),    
		.v1 			(sig_D2), 
		.d0				(!first_col_d2& sig_C0),
		.d1				(!last_col_d2 & sig_E0),
		.d2				(!first_col_d2& sig_C2),
		.d3				(!last_col_d2 & sig_E2),
		.d				(D1),
		.ctx			(ctx_zc1),
		.q				(q_zc1)
		);
	sign_coding sc1(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d2& sig_C1), 
		.h1				(!last_col_d2 & sig_E1), 
		.v0				(sig_D0_new),    
		.v1 			(sig_D2), 
		
		.sign_h0		(sign_C1), 
		.sign_h1		(sign_E1), 
		.sign_v0		(sign_D0), 
		.sign_v1 		(sign_D2), 
		
		.d				(sign_D1),
		.ctx			(ctx_sc1),
		.q				(q_sc1)
		);


	zero_coding zc2(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d2& sig_C2), 
		.h1				(!last_col_d2 & sig_E2), 
		.v0				(sig_D1_new),   
		.v1 			(sig_D3), 
		.d0				(!first_col_d2& sig_C1),
		.d1				(!last_col_d2 & sig_E1),
		.d2				(!first_col_d2& sig_C3),
		.d3				(!last_col_d2 & sig_E3),
		.d				(D2),
		.ctx			(ctx_zc2),
		.q				(q_zc2)
		);
	
	sign_coding sc2(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d2& sig_C2), 
		.h1				(!last_col_d2 & sig_E2), 
		.v0				(sig_D1_new),   
		.v1 			(sig_D3), 
		
		.sign_h0		(sign_C2), 
		.sign_h1		(sign_E2), 
		.sign_v0		(sign_D1), 
		.sign_v1 		(sign_D3), 
		
		.d				(sign_D2),
		.ctx			(ctx_sc2),
		.q				(q_sc2)
		);

	
	zero_coding zc3(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d2& sig_C3), 
		.h1				(!last_col_d2 & sig_E3), 
		.v0				(sig_D2_new),   
		.v1 			(1'b0), 		
		.d0				(!first_col_d2& sig_C2),
		.d1				(!last_col_d2 & sig_E2),
		.d2				(1'b0),
		.d3				(1'b0 ),
		.d				(D3),
		.ctx			(ctx_zc3),
		.q				(q_zc3)
		);
		
	sign_coding sc3(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d2& sig_C3), 
		.h1				(!last_col_d2 & sig_E3), 
		.v0				(sig_D2_new),   
		.v1 			(1'b0), 		
		
		.sign_h0		(sign_C3), 
		.sign_h1		(sign_E3), 
		.sign_v0		(sign_D2), 
		.sign_v1 		(1'b0), 
		
		.d				(sign_D3),
		.ctx			(ctx_sc3),
		.q				(q_sc3)
		);	
		

	//-------------------------------------
	mrc mrc0(
		.clk			(clk),
		.rstn			(rstn),
		
		.h0				(!first_col_d4& sig_A0), 
		.h1				(!last_col_d4 & sig_C0), 
		.v0				(!first_row_d4 & sig_Bn1), 
		.v1 			(sig_B1), 
		.d0				(!first_col_d4& sig_An1),
		.d1				(!last_col_d4 & sig_Cn1),
		.d2				(!first_col_d4& sig_A1),
		.d3				(!last_col_d4 & sig_C1),
		.first_time		(ref_B0),
		
		.d				(B0),
		.ctx			(ctx_mrc0),
		.q				(q_mrc0)
		);
	
	mrc mrc1(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig_A1), 
		.h1				(!last_col_d4 & sig_C1), 
		.v0				(sig_B0),    
		.v1 			(sig_B2), 
		.d0				(!first_col_d4& sig_A0),
		.d1				(!last_col_d4 & sig_C0),
		.d2				(!first_col_d4& sig_A2),
		.d3				(!last_col_d4 & sig_C2),
		.first_time		(ref_B1),
		
		.d				(B1),
		.ctx			(ctx_mrc1),
		.q				(q_mrc1)
		);		
			
	mrc mrc2(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig_A2), 
		.h1				(!last_col_d4 & sig_C2), 
		.v0				(sig_B1),   
		.v1 			(sig_B3), 
		.d0				(!first_col_d4& sig_A1),
		.d1				(!last_col_d4 & sig_C1),
		.d2				(!first_col_d4& sig_A3),
		.d3				(!last_col_d4 & sig_C3),
		.first_time		(ref_B2),
		
		.d				(B2),
		.ctx			(ctx_mrc2),
		.q				(q_mrc2)
		);		

	mrc mrc3(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig_A3), 
		.h1				(!last_col_d4 & sig_C3), 
		.v0				(sig_B2),   
		.v1 			(1'b0), 		// vertical casual 
		.d0				(!first_col_d4& sig_A2),
		.d1				(!last_col_d4 & sig_C2),
		.d2				(1'b0),
		.d3				(1'b0 ),
		.first_time		(ref_B3),
		
		.d				(B3),
		.ctx			(ctx_mrc3),
		.q				(q_mrc3)
		);		
		

	//----------------------------------------
	
	wire		[4:0]	cln_ctx_zc0;
	wire				cln_q_zc0;
	wire		[4:0]	cln_ctx_zc1;
	wire				cln_q_zc1;
	wire		[4:0]	cln_ctx_zc2;
	wire				cln_q_zc2;
	wire		[4:0]	cln_ctx_zc3;
	wire				cln_q_zc3;
                        
	wire		[4:0]	cln_ctx_sc0;
	wire				cln_q_sc0;
	wire		[4:0]	cln_ctx_sc1;
	wire				cln_q_sc1;
	wire		[4:0]	cln_ctx_sc2;
	wire				cln_q_sc2;
	wire		[4:0]	cln_ctx_sc3;
	wire				cln_q_sc3;

	RLC RLC(
		.clk			(clk),
		.rstn			(rstn),
		.data_0			(B0),
		.data_1			(B1),
		.data_2			(B2),
		.data_3			(B3),
		
		.q1_en			(rlc1_en),
		.ctx0			(ctx_rlc0),
        .q0				(q_rlc0),
		.ctx1			(ctx_rlc1),
		.q1				(q_rlc1),
		.ctx2			(ctx_rlc2),
	    .q2				(q_rlc2)
		);
	
	zero_coding cln_zc0(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d4& sig2_A0), 
		.h1				(!last_col_d4 & sig_C0), 		// sig2 B C D E = sig
		.v0				(!first_row_d4 & sig2_Bn1), 
		.v1 			(sig_B1), 
		.d0				(!first_col_d4& sig2_An1),
		.d1				(!last_col_d4 & sig2_Cn1),
		.d2				(!first_col_d4& sig2_A1),
		.d3				(!last_col_d4 & sig_C1),
		.d				(B0),
		.ctx			(cln_ctx_zc0),
		.q				(cln_q_zc0)
		);
		
	sign_coding cln_sc0(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig2_A0), 
		.h1				(!last_col_d4 & sig_C0), 
		.v0				(!first_row_d4 & sig2_Bn1), 
		.v1 			(sig_B1), 
		
		.sign_h0		(sign_A0), 
		.sign_h1		(sign_C0), 
		.sign_v0		(sign_Bn1), 
		.sign_v1 		(sign_B1), 
		
		.d				(sign_B0),
		.ctx			(cln_ctx_sc0),
		.q				(cln_q_sc0)
		);
		
	zero_coding cln_zc1(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d4& sig2_A1), 
		.h1				(!last_col_d4 & sig_C1), 
		.v0				(sig_B0_new),    
		.v1 			(sig_B2), 
		.d0				(!first_col_d4& sig2_A0),
		.d1				(!last_col_d4 & sig_C0),
		.d2				(!first_col_d4& sig2_A2),
		.d3				(!last_col_d4 & sig_C2),
		.d				(B1),
		.ctx			(cln_ctx_zc1),
		.q				(cln_q_zc1)
		);
	sign_coding cln_sc1(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig2_A1), 
		.h1				(!last_col_d4 & sig_C1), 
		.v0				(sig_B0_new),    
		.v1 			(sig_B2), 
		
		.sign_h0		(sign_A1), 
		.sign_h1		(sign_C1), 
		.sign_v0		(sign_B0), 
		.sign_v1 		(sign_B2), 
		
		.d				(sign_B1),
		.ctx			(cln_ctx_sc1),
		.q				(cln_q_sc1)
		);

	zero_coding cln_zc2(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d4& sig2_A2), 
		.h1				(!last_col_d4 & sig_C2), 
		.v0				(sig_B1_new),   
		.v1 			(sig_B3), 
		.d0				(!first_col_d4& sig2_A1),
		.d1				(!last_col_d4 & sig_C1),
		.d2				(!first_col_d4& sig2_A3),
		.d3				(!last_col_d4 & sig_C3),
		.d				(B2),
		.ctx			(cln_ctx_zc2),
		.q				(cln_q_zc2)
		);
	
	sign_coding cln_sc2(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig2_A2), 
		.h1				(!last_col_d4 & sig_C2), 
		.v0				(sig_B1_new),   
		.v1 			(sig_B3), 
		
		.sign_h0		(sign_A2), 
		.sign_h1		(sign_C2), 
		.sign_v0		(sign_B1), 
		.sign_v1 		(sign_B3), 
		
		.d				(sign_B2),
		.ctx			(cln_ctx_sc2),
		.q				(cln_q_sc2)
		);

	zero_coding cln_zc3(
		.clk			(clk),
		.rstn			(rstn),
		.band			(band),
		.h0				(!first_col_d4& sig2_A3), 
		.h1				(!last_col_d4 & sig_C3), 
		.v0				(sig_B2_new),   
		.v1 			(1'b0), 		
		.d0				(!first_col_d4& sig2_A2),
		.d1				(!last_col_d4 & sig_C2),
		.d2				(1'b0),
		.d3				(1'b0 ),
		.d				(B3),
		.ctx			(cln_ctx_zc3),
		.q				(cln_q_zc3)
		);
		
	sign_coding cln_sc3(
		.clk			(clk),
		.rstn			(rstn),
		.h0				(!first_col_d4& sig2_A3), 
		.h1				(!last_col_d4 & sig_C3), 
		.v0				(sig_B2_new),   
		.v1 			(1'b0), 		// vertical casual 
		
		.sign_h0		(sign_A3), 
		.sign_h1		(sign_C3), 
		.sign_v0		(sign_B2), 
		.sign_v1 		(1'b0), 
		
		.d				(sign_B3),
		.ctx			(cln_ctx_sc3),
		.q				(cln_q_sc3)
		);	
		


	reg		ref_pass0_en, ref_pass1_en, ref_pass2_en, ref_pass3_en;
	reg		sig_pass0_en, sig_pass1_en, sig_pass2_en, sig_pass3_en;
	reg		cln_pass0_en, cln_pass1_en, cln_pass2_en, cln_pass3_en;


	//---------------------------------------------------------------------

	
	reg		[0:0]		D0_d1, D1_d1, D2_d1, D3_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	{D0_d1, D1_d1, D2_d1, D3_d1} <= 0;
		else 		{D0_d1, D1_d1, D2_d1, D3_d1} <= {D0, D1, D2, D3};
	
	always @(`CLK_RST_EDGE)
		if (`RST)	{sig_pass0_en, sig_pass1_en, sig_pass2_en, sig_pass3_en} <= 0;
		else begin
			sig_pass0_en <= (oth_sig0 & !sig_D0);
			sig_pass1_en <= (oth_sig1 & !sig_D1);
			sig_pass2_en <= (oth_sig2 & !sig_D2);
			sig_pass3_en <= (oth_sig3 & !sig_D3);
		end
	
	reg		sig_pass_zc0_en;
	reg		sig_pass_sc0_en;
	reg		sig_pass_zc1_en;
	reg		sig_pass_sc1_en;
	reg		sig_pass_zc2_en;
	reg		sig_pass_sc2_en;
	reg		sig_pass_zc3_en;
	reg		sig_pass_sc3_en;
	
	always @(*) sig_pass_zc0_en = sig_pass0_en;
	always @(*) sig_pass_sc0_en = sig_pass0_en & D0_d1;
	always @(*) sig_pass_zc1_en = sig_pass1_en;
	always @(*) sig_pass_sc1_en = sig_pass1_en & D1_d1;
	always @(*) sig_pass_zc2_en = sig_pass2_en;
	always @(*) sig_pass_sc2_en = sig_pass2_en & D2_d1;
	always @(*) sig_pass_zc3_en = sig_pass3_en;
	always @(*) sig_pass_sc3_en = sig_pass3_en & D3_d1;
	

	//---------------------------------------------------------
	wire	cln_oth_sig0 =  !first_col_d4& sig2_A0 | !last_col_d4 & sig2_C0 |								 
							!first_row_d4 & sig_Bn1 | sig2_B1
							| !first_col_d4& sig_An1 | !last_col_d4 & sig_Cn1 | !first_col_d4& sig2_A1 | !last_col_d4 & sig2_C1;
	
	wire	cln_oth_sig1 =  !first_col_d4& sig2_A1 	| !last_col_d4 & sig2_C1 
							| sig_B0_new  |  sig2_B2 
							| !first_col_d4& sig2_A0 | !last_col_d4 & sig2_C0  | !first_col_d4& sig2_A2 | !last_col_d4 & sig2_C2;
	
	wire	cln_oth_sig2 =  !first_col_d4& sig2_A2  | !last_col_d4 & sig2_C2 
							|sig_B1_new   |sig2_B3 
							|!first_col_d4& sig2_A1  |!last_col_d4 & sig2_C1 |!first_col_d4& sig2_A3  |!last_col_d4 & sig2_C3 ;

	wire	cln_oth_sig3 =  !first_col_d4& sig2_A3  |!last_col_d4 & sig2_C3 
							|sig_B2_new  |1'b0  		
							|!first_col_d4& sig2_A2 	|!last_col_d4 & sig2_C2 |1'b0 |1'b0 ;
	
	`DELAY4(oth_sig0,0)
	`DELAY4(oth_sig1,0)
	`DELAY4(oth_sig2,0)
	`DELAY4(oth_sig3,0)
	

	wire	rlc_en = !( !first_col_d4&sig2_An1| sig2_Bn1| !last_col_d4 &sig2_Cn1|
						!first_col_d4&sig2_A0| sig2_B0| !last_col_d4 &sig2_C0|
	                    !first_col_d4&sig2_A1| sig2_B1| !last_col_d4 &sig2_C1|
	                    !first_col_d4&sig2_A2| sig2_B2| !last_col_d4 &sig2_C2|
	                    !first_col_d4&sig2_A3| sig2_B3| !last_col_d4 &sig2_C3 );

	always @(`CLK_RST_EDGE)
		if (`RST)	{cln_pass0_en, cln_pass1_en, cln_pass2_en, cln_pass3_en} <= 0;
		else begin
			cln_pass0_en <= rlc_en || (!oth_sig0_d2 & !sig_B0);
			cln_pass1_en <= rlc_en || (!oth_sig1_d2 & !sig_B1);
			cln_pass2_en <= rlc_en || (!oth_sig2_d2 & !sig_B2);
			cln_pass3_en <= rlc_en || (!oth_sig3_d2 & !sig_B3);
		end

	reg		[0:0]		B0_d1, B1_d1, B2_d1, B3_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	{B0_d1, B1_d1, B2_d1, B3_d1} <= 0;
		else 		{B0_d1, B1_d1, B2_d1, B3_d1} <= {B0, B1, B2, B3};
	reg		[0:0]		rlc_en_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	rlc_en_d1 <= 0;
		else 		rlc_en_d1 <= rlc_en;
	
	reg		cln_pass_rlc0_en;
	reg		cln_pass_rlc1_en;
	reg		cln_pass_rlc2_en;
	
	always @(*) cln_pass_rlc0_en = rlc_en_d1;
	always @(*) cln_pass_rlc1_en = rlc_en_d1 & rlc1_en;
	always @(*) cln_pass_rlc2_en = rlc_en_d1 & rlc1_en;
	
	reg		cln_pass_zc0_en;
	reg		cln_pass_sc0_en;
	reg		cln_pass_zc1_en;
	reg		cln_pass_sc1_en;
	reg		cln_pass_zc2_en;
	reg		cln_pass_sc2_en;
	reg		cln_pass_zc3_en;
	reg		cln_pass_sc3_en;

	
	always @(*) cln_pass_zc0_en = rlc_en_d1? 0 : cln_pass0_en;
	always @(*) cln_pass_sc0_en = cln_pass0_en & B0_d1;
	
	always @(*) cln_pass_zc1_en = rlc_en_d1? (B0_d1) :  cln_pass1_en;
	always @(*) cln_pass_sc1_en = cln_pass1_en & B1_d1;
	
	always @(*) cln_pass_zc2_en = rlc_en_d1?  (B0_d1 | B1_d1) :  cln_pass2_en;
	always @(*) cln_pass_sc2_en = cln_pass2_en & B2_d1;
	
	always @(*) cln_pass_zc3_en = rlc_en_d1?  (B0_d1 | B1_d1 | B2_d1) :  cln_pass3_en;
	always @(*) cln_pass_sc3_en = cln_pass3_en & B3_d1;
	

	//--------------------------------------------------------------------------

	`DELAY4(sig_D0, 0)		
	`DELAY4(sig_D1, 0)		
	`DELAY4(sig_D2, 0)		
	`DELAY4(sig_D3, 0)		
	always @(`CLK_RST_EDGE)
		if (`RST)	{ref_pass0_en, ref_pass1_en, ref_pass2_en, ref_pass3_en} <= 0;
		else 		{ref_pass0_en, ref_pass1_en, ref_pass2_en, ref_pass3_en} <= {sig_D0_d2, sig_D1_d2, sig_D2_d2, sig_D3_d2};
	
	//reg		ref_pass0_en, ref_pass1_en, ref_pass2_en, ref_pass3_en;
	reg		ref_pass_zc0_en;
	reg		ref_pass_zc1_en;
	reg		ref_pass_zc2_en;
	reg		ref_pass_zc3_en;
	
	always @(*) ref_pass_zc0_en = ref_pass0_en;
	always @(*) ref_pass_zc1_en = ref_pass1_en;
	always @(*) ref_pass_zc2_en = ref_pass2_en;
	always @(*) ref_pass_zc3_en = ref_pass3_en;



	//-----------------------------------------------------------------------------

	reg	 [9:0]	cln_pass_ens;
	reg	 [6*10-1:0]	cln_pass_ctxds;
	always @(*)
		casex({cln_pass_rlc0_en,cln_pass_zc0_en, cln_pass_zc1_en, cln_pass_zc2_en, cln_pass_zc3_en})  
		5'b1????: begin cln_pass_ens = { cln_pass_rlc0_en, cln_pass_rlc1_en, cln_pass_rlc2_en, 
										                 cln_pass_sc0_en,
										cln_pass_zc1_en, cln_pass_sc1_en,
										cln_pass_zc2_en, cln_pass_sc2_en,
										cln_pass_zc3_en, cln_pass_sc3_en };
						cln_pass_ctxds = { {ctx_rlc0, q_rlc0}, {ctx_rlc1, q_rlc1}, {ctx_rlc2, q_rlc2},
																  {cln_ctx_sc0, cln_q_sc0}, 
										{cln_ctx_zc1, cln_q_zc1}, {cln_ctx_sc1, cln_q_sc1}, 
										{cln_ctx_zc2, cln_q_zc2}, {cln_ctx_sc2, cln_q_sc2},
										{cln_ctx_zc3, cln_q_zc3}, {cln_ctx_sc3, cln_q_sc3} };
				  end
		5'b01???: begin
					cln_pass_ens = {	cln_pass_zc0_en,  cln_pass_sc0_en,
										cln_pass_zc1_en, cln_pass_sc1_en,
										cln_pass_zc2_en, cln_pass_sc2_en,
										cln_pass_zc3_en, cln_pass_sc3_en, 
										2'b0};
					cln_pass_ctxds = {{cln_ctx_zc0, cln_q_zc0}, {cln_ctx_sc0, cln_q_sc0}, 
									{cln_ctx_zc1, cln_q_zc1}, {cln_ctx_sc1, cln_q_sc1}, 
									{cln_ctx_zc2, cln_q_zc2}, {cln_ctx_sc2, cln_q_sc2},
									{cln_ctx_zc3, cln_q_zc3}, {cln_ctx_sc3, cln_q_sc3},
									6'b0, 6'b0 	};	
				  end
		5'b001??: begin
					cln_pass_ens = {	cln_pass_zc1_en, cln_pass_sc1_en,
										cln_pass_zc2_en, cln_pass_sc2_en,
										cln_pass_zc3_en, cln_pass_sc3_en, 
										4'b0};
					cln_pass_ctxds = {{cln_ctx_zc1, cln_q_zc1}, {cln_ctx_sc1, cln_q_sc1}, 
									{cln_ctx_zc2, cln_q_zc2}, {cln_ctx_sc2, cln_q_sc2},
									{cln_ctx_zc3, cln_q_zc3}, {cln_ctx_sc3, cln_q_sc3},
									6'b0, 6'b0, 6'b0, 6'b0	};	
				  end
		5'b0001?: begin
					cln_pass_ens = {	cln_pass_zc2_en, cln_pass_sc2_en,
										cln_pass_zc3_en, cln_pass_sc3_en, 
										6'b0};
					cln_pass_ctxds = {{cln_ctx_zc2, cln_q_zc2}, {cln_ctx_sc2, cln_q_sc2},
									{cln_ctx_zc3, cln_q_zc3}, {cln_ctx_sc3, cln_q_sc3},
									6'b0, 6'b0, 6'b0, 6'b0, 6'b0, 6'b0	};	
				  end
		5'b00001: begin
					cln_pass_ens = {	cln_pass_zc3_en, cln_pass_sc3_en, 
										8'b0};
					cln_pass_ctxds = {{cln_ctx_zc3, cln_q_zc3}, {cln_ctx_sc3, cln_q_sc3},
									6'b0, 6'b0, 6'b0, 6'b0, 6'b0, 6'b0, 6'b0, 6'b0	};	
				  end
		5'b00000: begin cln_pass_ens = 0; cln_pass_ctxds = 0; end
		endcase
	//---------------------------------------------------

	reg	 [7:0]		sig_pass_ens;
	reg	 [6*8-1:0]	sig_pass_ctxds;
	always @(*)
		casex({sig_pass_zc0_en, sig_pass_zc1_en, sig_pass_zc2_en, sig_pass_zc3_en})  
			4'b1???: begin sig_pass_ens = { sig_pass_zc0_en, sig_pass_sc0_en, 
										    sig_pass_zc1_en, sig_pass_sc1_en,
											sig_pass_zc2_en, sig_pass_sc2_en,
											sig_pass_zc3_en, sig_pass_sc3_en };
						   sig_pass_ctxds = {	{ctx_zc0, q_zc0}, {ctx_sc0, q_sc0},
												{ctx_zc1, q_zc1}, {ctx_sc1, q_sc1},
												{ctx_zc2, q_zc2}, {ctx_sc2, q_sc2},
												{ctx_zc3, q_zc3}, {ctx_sc3, q_sc3}  };
					 end
			4'b01??: begin sig_pass_ens = { sig_pass_zc1_en, sig_pass_sc1_en,
											sig_pass_zc2_en, sig_pass_sc2_en,
											sig_pass_zc3_en, sig_pass_sc3_en,
											2'b0 };
						 sig_pass_ctxds = {     {ctx_zc1, q_zc1}, {ctx_sc1, q_sc1},
												{ctx_zc2, q_zc2}, {ctx_sc2, q_sc2},
												{ctx_zc3, q_zc3}, {ctx_sc3, q_sc3}, 
												12'b0};
					 end
			4'b001?: begin sig_pass_ens = { sig_pass_zc2_en, sig_pass_sc2_en,
											sig_pass_zc3_en, sig_pass_sc3_en,
											2'b0, 2'b0 };
						 sig_pass_ctxds = {		{ctx_zc2, q_zc2}, {ctx_sc2, q_sc2},
												{ctx_zc3, q_zc3}, {ctx_sc3, q_sc3}, 
												12'b0, 12'b0};
					 end
			
			4'b0001: begin 	sig_pass_ens = { sig_pass_zc3_en, sig_pass_sc3_en,
											2'b0, 2'b0, 2'b0 };
							sig_pass_ctxds = {	{ctx_zc3, q_zc3}, {ctx_sc3, q_sc3}, 
												12'b0, 12'b0, 12'b0};
					 end
			4'b0000: begin sig_pass_ens = 0; sig_pass_ctxds = 0; end
		endcase

	//-----------------------------------

	reg	 [3:0]		ref_pass_ens;
	reg	 [6*4-1:0]	ref_pass_ctxds;
	always @(*)
		casex({ref_pass_zc0_en, ref_pass_zc1_en, ref_pass_zc2_en, ref_pass_zc3_en})  
			4'b1???: begin ref_pass_ens   = {ref_pass_zc0_en, ref_pass_zc1_en, ref_pass_zc2_en, ref_pass_zc3_en};
						   ref_pass_ctxds = { ctx_mrc0, q_mrc0, 
											  ctx_mrc1, q_mrc1, 
											  ctx_mrc2, q_mrc2, 
											  ctx_mrc3, q_mrc3 };
					 end
			4'b01??: begin ref_pass_ens =  { ref_pass_zc1_en, ref_pass_zc2_en, ref_pass_zc3_en, 1'b0};
						  ref_pass_ctxds ={   ctx_mrc1, q_mrc1, 
											  ctx_mrc2, q_mrc2, 
											  ctx_mrc3, q_mrc3,
											  6'b0 };
					 end
			4'b001?: begin ref_pass_ens =  { ref_pass_zc2_en, ref_pass_zc3_en, 2'b0};
						  ref_pass_ctxds = {  ctx_mrc2, q_mrc2, 
											  ctx_mrc3, q_mrc3,
											 6'b0, 6'b0 };
					 end
			
			4'b0001: begin 	ref_pass_ens = { ref_pass_zc3_en, 3'b0};
							ref_pass_ctxds = {	ctx_mrc3, q_mrc3,
												6'b0, 6'b0, 6'b0};
					 end
			4'b0000: begin ref_pass_ens = 0; ref_pass_ctxds = 0; end
		endcase


	//---------------------------------------------------------------------



	wire					cln_pass_fifo_wr_en = coef_en_d5 && cln_pass_ens!=0;
	wire [(1+5+1)*10-1:0]	cln_pass_fifo_db = { cln_pass_ens,  cln_pass_ctxds };
										
	wire					sig_pass_fifo_wr_en = coef_en_d3 && sig_pass_ens!=0;
	wire [(1+5+1)*8-1:0]	sig_pass_fifo_db = {sig_pass_ens,  sig_pass_ctxds }; 
												
	wire					ref_pass_fifo_wr_en = coef_en_d5 && ref_pass_ens!=0;
	wire [(1+5+1)*4-1:0]	ref_pass_fifo_db = {ref_pass_ens,  ref_pass_ctxds }; 

	reg						cln_pass_fifo_rd_en;
	wire [(1+5+1)*10-1:0]	cln_pass_fifo_qa;
	wire					cln_pass_fifo_empty;
	fifo_fwft_sync #(
		.DEPTH	(64*64),
		.DW		((1+5+1)*10)
		) cln_pass_fifo(
			.clk       		(clk),
			.rstn       	(rstn),
			.wr_en  		(cln_pass_fifo_wr_en),
			.din 			(cln_pass_fifo_db),
			
			.rd_en			(cln_pass_fifo_rd_en),
			.dout			(cln_pass_fifo_qa),

			.full			(cln_pass_fifo_full),
			.empty			(cln_pass_fifo_empty)
		);
	
	reg		[10-1:0]	cln_pass_ens_shift;
	reg		[6*10-1:0]	cln_pass_ctxd_shift;
	
	always @(*) cln_pass_fifo_rd_en = mq_cln_e && (cln_pass_ens_shift==0 || cln_pass_ens_shift==10'h200)  && !cln_pass_fifo_empty;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	{ cln_pass_ens_shift, cln_pass_ctxd_shift} <= 0;
		else if (mq_cln_e && (cln_pass_ens_shift==0 || cln_pass_ens_shift==10'h200)  && !cln_pass_fifo_empty ) begin
				// cln_pass_fifo_rd_en <= 1;
				{cln_pass_ens_shift, cln_pass_ctxd_shift} <= cln_pass_fifo_qa;
		end else if (cln_pass_ens_shift[8]!=0) begin
				cln_pass_ens_shift <= cln_pass_ens_shift << 1;
				cln_pass_ctxd_shift <= cln_pass_ctxd_shift << 6;
		end else if (cln_pass_ens_shift!=0) begin
				// cln_pass_fifo_rd_en <= 0;
				cln_pass_ens_shift <= cln_pass_ens_shift << 2;
				cln_pass_ctxd_shift <= cln_pass_ctxd_shift << 12;
		end
	
	assign			cln_pass_ctxd_en = cln_pass_ens_shift[10-1];
	assign			cln_pass_ctx = cln_pass_ctxd_shift[6*10-1-:5];
	assign			cln_pass_d   = cln_pass_ctxd_shift[6*10-1-:6];
	


	//------------------
	reg						sig_pass_fifo_rd_en;
	wire [(1+5+1)*8-1:0]	sig_pass_fifo_qa;
	wire					sig_pass_fifo_empty;
	fifo_fwft_sync #(
		.DEPTH	(64*64),
		.DW		((1+5+1)*8)
		) sig_pass_fifo(
			.clk       		(clk),
			.rstn       	(rstn),
			.wr_en  		(sig_pass_fifo_wr_en),
			.din 			(sig_pass_fifo_db),
			
			.rd_en			(sig_pass_fifo_rd_en),
			.dout			(sig_pass_fifo_qa),
			.full			(sig_pass_fifo_full),
			.empty			(sig_pass_fifo_empty)
		);
	
	reg		[8-1:0]	sig_pass_ens_shift;
	reg		[6*8-1:0]	sig_pass_ctxd_shift;

	always @(*) sig_pass_fifo_rd_en = mq_sig_e && (sig_pass_ens_shift==0 || sig_pass_ens_shift==8'h80) && !sig_pass_fifo_empty;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	{sig_pass_ens_shift, sig_pass_ctxd_shift} <= 0;
		else if (mq_sig_e && (sig_pass_ens_shift==0 || sig_pass_ens_shift==8'h80) && !sig_pass_fifo_empty ) begin
				// sig_pass_fifo_rd_en <= 1;
				{sig_pass_ens_shift, sig_pass_ctxd_shift} <= sig_pass_fifo_qa;
		end else if (sig_pass_ens_shift[6]!=0) begin
				sig_pass_ens_shift <= sig_pass_ens_shift << 1;
				sig_pass_ctxd_shift <= sig_pass_ctxd_shift << 6;
		end else if (sig_pass_ens_shift!=0) begin
				// sig_pass_fifo_rd_en <= 0;
				sig_pass_ens_shift <= sig_pass_ens_shift << 2;
				sig_pass_ctxd_shift <= sig_pass_ctxd_shift << 12;
		end
	
	assign			sig_pass_ctxd_en = sig_pass_ens_shift[8-1];
	assign			sig_pass_ctx = sig_pass_ctxd_shift[6*8-1-:5];
	assign			sig_pass_d   = sig_pass_ctxd_shift[6*8-1-:6];
	
	//------------------
	reg						ref_pass_fifo_rd_en;
	wire [(1+5+1)*4-1:0]	ref_pass_fifo_qa;
	wire					ref_pass_fifo_empty;
	fifo_fwft_sync #(
		.DEPTH	(64*64),
		.DW		((1+5+1)*4)
		) ref_pass_fifo(
			.clk       		(clk),
			.rstn       	(rstn),
			.wr_en  		(ref_pass_fifo_wr_en),
			.din 			(ref_pass_fifo_db),
			
			.rd_en			(ref_pass_fifo_rd_en),
			.dout			(ref_pass_fifo_qa),
			.full			(ref_pass_fifo_full),
			.empty			(ref_pass_fifo_empty)
		);
	

	
	reg		[4-1:0]		ref_pass_ens_shift;
	reg		[6*4-1:0]	ref_pass_ctxd_shift;

	always @(*) ref_pass_fifo_rd_en = mq_ref_e && (ref_pass_ens_shift==0 || ref_pass_ens_shift == 4'b1000) && !ref_pass_fifo_empty;

	always @(`CLK_RST_EDGE)
		if (`RST)	{ref_pass_ens_shift, ref_pass_ctxd_shift} <= 0;
		else if (mq_ref_e && (ref_pass_ens_shift==0 || ref_pass_ens_shift == 4'b1000) && !ref_pass_fifo_empty ) begin
				// ref_pass_fifo_rd_en <= 1;
				{ref_pass_ens_shift, ref_pass_ctxd_shift} <= ref_pass_fifo_qa;
		end else if (ref_pass_ens_shift[2] != 0) begin
				ref_pass_ens_shift <= ref_pass_ens_shift << 1;
				ref_pass_ctxd_shift <= ref_pass_ctxd_shift << 6;
		end else if (ref_pass_ens_shift!=0) begin
				// ref_pass_fifo_rd_en <= 0;
				ref_pass_ens_shift <= ref_pass_ens_shift << 2;
				ref_pass_ctxd_shift <= ref_pass_ctxd_shift << 12;
		end
	
	assign			ref_pass_ctxd_en = ref_pass_ens_shift[4-1];
	assign			ref_pass_ctx = ref_pass_ctxd_shift[6*4-1-:5];
	assign			ref_pass_d   = ref_pass_ctxd_shift[6*4-1-:6];
	
	
	assign	sig_pass_empty = mq_sig_e && sig_pass_ens_shift==0 && sig_pass_fifo_empty;
	assign	ref_pass_empty = mq_ref_e && ref_pass_ens_shift==0 && ref_pass_fifo_empty;
	assign	cln_pass_empty = mq_cln_e && cln_pass_ens_shift==0 && cln_pass_fifo_empty;
	
`ifdef SIMULATING
	always @(`CLK_EDGE)
		if (sig_pass_fifo_full) begin
			$display("===ERROR====sig_pass_fifo_full====");
			$finish();
		end
	always @(`CLK_EDGE)
		if (ref_pass_fifo_full) begin
			$display("===ERROR====ref_pass_fifo_full====");
			$finish();
		end
	always @(`CLK_EDGE)
		if (cln_pass_fifo_full) begin
			$display("===ERROR====cln_pass_fifo_full====");
			$finish();
		end


`endif
endmodule

