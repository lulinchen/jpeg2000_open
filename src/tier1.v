// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

module tier1(
	input						clk,
	input						rstn,
	
	input						go,
	input		[0:7][0:3][3:0]	codeblock_numbps,  // levl band 
	input		[2:0]			ndecomp,
	
	input						ready_for_next_lvl,
	
	input		[`W_WT1P*4-1:0]	qa_coeff_buf,
	output reg					cena_coeff_buf,
	output reg	[11:0]			aa_coeff_buf,
	
	// signals to tier2 
	output reg		[0:7][0:2][7:0]		zero_bitplanes_buf,
	output reg		[0:7][0:2][7:0]		pass_num_buf,
	output reg		[0:7][0:2][15:0]	codeword_len_buf,

	output reg		[3:0]		lvl_cnt,
	output reg					lvl_ready,

	output reg					byte_out_f,
	output reg	[7:0]			byte_out,

	output reg					mq_ready,

	output reg					tile_ready,

	output					pp
	
	);
	
	reg		[0:7][0:3][3:0]	codeblock_numbps_buf;
	always @(`CLK_RST_EDGE)
		if (`RST)			codeblock_numbps_buf <= 0;
		else if (go) 		codeblock_numbps_buf <= codeblock_numbps;
	


	// reg		[3:0]	lvl_cnt;
	reg		[1:0]	band_cnt;
	
	reg				lvl_e;
	
	reg				lvl_go;
	// reg				lvl_ready;
	wire			lvl_max_f = lvl_cnt == ndecomp;
	
	always @(*) tile_ready = lvl_ready & lvl_max_f;
	

	always @(`CLK_RST_EDGE)
		if (`RST)						lvl_e <= 0;
		else if (go)					lvl_e <= 1;
		else if (lvl_ready & lvl_max_f)	lvl_e <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)			lvl_cnt <= 0;
		else if (lvl_e) 	lvl_cnt <= lvl_ready? (lvl_cnt + 1) : lvl_cnt;
		else 				lvl_cnt <= 0;
	
	reg			doing_lvl;
	always @(`CLK_RST_EDGE)
		if (`RST)				doing_lvl <= 0;
		else if (lvl_go) 		doing_lvl <= 1;
		else if (lvl_ready)		doing_lvl <= 0;

	
	// always @(`CLK_RST_EDGE)
		// if (`RST)	lvl_go <= 0;
		// else 		lvl_go <= go || lvl_ready & !lvl_max_f;
	always @(*) lvl_go = ready_for_next_lvl & !doing_lvl & lvl_e;
	
	
	reg		band_go;
	reg		band_ready;
	wire	[1:0]	band_max = lvl_cnt==0? 0 : 3;
	wire			band_max_f = band_cnt == band_max;
	
	always @(`CLK_RST_EDGE)
		if (`RST)			band_cnt <= 0;
		else if (lvl_go) 	band_cnt <= lvl_cnt==0? 0 : 1;
		else if (band_ready)band_cnt <= band_cnt + 1;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	lvl_ready <= 0;
		else 		lvl_ready <= band_ready & band_max_f;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	band_go <= 0;
		else 		band_go <= lvl_go || band_ready & !band_max_f;
	

	reg		[15:0]				band_len_in_pix;
	always @(*) 
		if (lvl_cnt ==0) 	
			band_len_in_pix = (`TILE_WIDTH*`TILE_WIDTH) >> (ndecomp*2);
		else 
			band_len_in_pix = (`TILE_WIDTH*`TILE_WIDTH) >> ((ndecomp + 1 - lvl_cnt)*2);
	
	reg		[7:0]				band_width_in_pix;
	always @(*) 
		if (lvl_cnt ==0) 	
			band_width_in_pix = (`TILE_WIDTH) >> (ndecomp);
		else 
			band_width_in_pix = (`TILE_WIDTH) >> ((ndecomp + 1 - lvl_cnt));	

	reg				bitplane_go;
	reg				bitplane_ready;
	reg	 	[3:0]	bitplane_cnt;
	wire			bitplane_cnt_max_f = bitplane_cnt == 0;
	
	reg		[3:0]	numbpps;
	always @(*) 	numbpps = lvl_cnt==0? codeblock_numbps_buf[ndecomp-1][band_cnt] : codeblock_numbps_buf[ndecomp-lvl_cnt][band_cnt];
	     
	always @(`CLK_RST_EDGE)
		if (`RST)					bitplane_cnt <= 0;
		else if (band_go) 			bitplane_cnt <= numbpps - 1;
		else if (bitplane_ready)	bitplane_cnt <= bitplane_cnt - 1;
	
	always @(`CLK_RST_EDGE)
		if (`RST)								zero_bitplanes_buf <= 0;
		else if (band_go) 			
			if (lvl_cnt == 0)					 zero_bitplanes_buf[lvl_cnt][band_cnt] <= 9 -numbpps;
			else if (band_cnt==1 || band_cnt==2) zero_bitplanes_buf[lvl_cnt][band_cnt-1] <= 9 + 1  - numbpps;
			else if (band_cnt==3)				 zero_bitplanes_buf[lvl_cnt][band_cnt-1] <= 9 + 2  - numbpps;

	always @(`CLK_RST_EDGE)
		if (`RST)					pass_num_buf <= 0;
		else if (band_go) 			
			if (lvl_cnt == 0)		pass_num_buf[lvl_cnt][band_cnt ]  <= numbpps ==0 ? 0 :  numbpps * 3 -2;
			else					pass_num_buf[lvl_cnt][band_cnt-1] <=  numbpps ==0 ? 0 :  numbpps * 3 -2;
		
	
	// always @(*) 	band_ready = bitplane_ready && bitplane_cnt_max_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	band_ready <= 0;
		else 		band_ready <=  (band_go && numbpps==0) || bitplane_ready && bitplane_cnt_max_f;
	
	// always @(*) bitplane_go = band_go |  bitplane_ready && !bitplane_cnt_max_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	bitplane_go <= 0;
		else 		bitplane_go <= (band_go && numbpps!=0) ||  bitplane_ready && !bitplane_cnt_max_f;
	
	reg				col_e;
	reg		[15:0]	col_cnt;
	`DELAY8(col_cnt, 15)
	
	wire			col_ready = col_e && col_cnt == band_len_in_pix/4 -1;

	// always @(*) 	bitplane_ready = col_cnt == band_len_in_pix/4 -1;

	always @(`CLK_RST_EDGE)
		if (`RST)					col_e <= 0;
		else if (bitplane_go)		col_e <= 1;
		else if (col_ready)			col_e <= 0;
			
	always @(`CLK_RST_EDGE)
		if (`RST)	col_cnt <= 0;
		else 		col_cnt <= col_e? col_cnt + 1 : 0;
	
	reg		[`W_AA_COEFF_BUF:0]			aa_coeff_buf_init;
	always @(*) 
		case(band_cnt)
			2'd0: 	aa_coeff_buf_init = 0;
			2'd1:	aa_coeff_buf_init = `INIT_AA_HL >> (2*(ndecomp - lvl_cnt));
			2'd2:	aa_coeff_buf_init = `INIT_AA_LH >> (2*(ndecomp - lvl_cnt));
			2'd3:	aa_coeff_buf_init = `INIT_AA_HH >> (2*(ndecomp - lvl_cnt));
		endcase

	always @(`CLK_RST_EDGE)
		if (`RST)				aa_coeff_buf <= 0;
		else if (bitplane_go) 	aa_coeff_buf <= aa_coeff_buf_init;
		else if (col_e)			aa_coeff_buf <= aa_coeff_buf + 1;
	
	always @(*) cena_coeff_buf = !col_e;
	
	`DELAY1(qa_coeff_buf, `W_WT1P*4-1)
	`DELAY8(col_e, 0)
	reg		[`W_WT1:0]		coeff0;
	reg		[`W_WT1:0]		coeff1;
	reg		[`W_WT1:0]		coeff2;
	reg		[`W_WT1:0]		coeff3;
	reg						coef_en;
	reg						plane_end;
	reg						first_row;
	reg						first_col;
	reg						last_col;


	reg		[`W_WT1:0]		_coeff0;
	reg		[`W_WT1:0]		_coeff1;
	reg		[`W_WT1:0]		_coeff2;
	reg		[`W_WT1:0]		_coeff3;
	always @(*) {_coeff0, _coeff1, _coeff2, _coeff3} = qa_coeff_buf_d1;
	always @(*) begin
		coeff0 <= _coeff0[`W_WT1]? ( (0-_coeff0) | (1<<`W_WT1) ) : _coeff0;
        coeff1 <= _coeff1[`W_WT1]? ( (0-_coeff1) | (1<<`W_WT1) ) : _coeff1;
        coeff2 <= _coeff2[`W_WT1]? ( (0-_coeff2) | (1<<`W_WT1) ) : _coeff2;
        coeff3 <= _coeff3[`W_WT1]? ( (0-_coeff3) | (1<<`W_WT1) ) : _coeff3;
	end
	

	always @(*) coef_en = col_e_d2;
	always @(*) plane_end = col_ready;
	always @(*) first_row = col_cnt_d2 < band_width_in_pix;
	always @(*) first_col = col_cnt_d2 % band_width_in_pix == 0;			// TODO
	always @(*) last_col  = col_cnt_d2 % band_width_in_pix == (band_width_in_pix - 1);
	
	
	always @(*) bitplane_ready = mq_ready;
	
	reg		mq_sig_e;
	reg		mq_ref_e;
	reg		mq_cln_e;


	wire					sig_pass_ctxd_en;
	wire	[5:0]			sig_pass_ctx;
	wire					sig_pass_d;
	wire					cln_pass_ctxd_en;
	wire	[5:0]			cln_pass_ctx;
	wire					cln_pass_d;
	wire					ref_pass_ctxd_en;
	wire	[5:0]			ref_pass_ctx;
	wire					ref_pass_d;

	bpc bpc(
		.clk			(clk),
		.rstn			(rstn),
		.coeff0			(coeff0),
		.coeff1			(coeff1),
		.coeff2			(coeff2),
		.coeff3			(coeff3),
		.coef_en		(coef_en),

		.first_row		(first_row),
		.first_col		(first_col),
		.last_col		(last_col),

		.band			(band_cnt),
		.bit_pos		(bitplane_cnt),
		
		.mq_sig_e		(mq_sig_e),
		.mq_ref_e		(mq_ref_e),
		.mq_cln_e		(mq_cln_e),

		.sig_pass_empty	(sig_pass_empty	),
		.ref_pass_empty	(ref_pass_empty	),
		.cln_pass_empty	(cln_pass_empty	),

		.sig_pass_ctxd_en	(sig_pass_ctxd_en	),
		.sig_pass_ctx		(sig_pass_ctx		),
		.sig_pass_d			(sig_pass_d			),
		.cln_pass_ctxd_en	(cln_pass_ctxd_en	),
		.cln_pass_ctx		(cln_pass_ctx		),
		.cln_pass_d			(cln_pass_d			),
		.ref_pass_ctxd_en	(ref_pass_ctxd_en	),
		.ref_pass_ctx		(ref_pass_ctx		),
		.ref_pass_d			(ref_pass_d			),

		.pp				()
		);

	`DELAY8(plane_end, 0)


	always @(`CLK_RST_EDGE)
		if (`RST)					mq_sig_e <= 0;
		else if (plane_end_d8) 		mq_sig_e <= 1;
		else if (sig_pass_empty)	mq_sig_e <= 0;
	wire	mq_ref_go = mq_sig_e & sig_pass_empty;
	always @(`CLK_RST_EDGE)
		if (`RST)					mq_ref_e <= 0;
		else if (mq_ref_go) 		mq_ref_e <= 1;
		else if (ref_pass_empty)	mq_ref_e <= 0;
	wire	mq_cln_go = mq_ref_e & ref_pass_empty;
	always @(`CLK_RST_EDGE)
		if (`RST)					mq_cln_e <= 0;
		else if (mq_cln_go) 		mq_cln_e <= 1;
		else if (cln_pass_empty)	mq_cln_e <= 0;
	
	wire	mq_plane_ready = mq_cln_e & cln_pass_empty;
	`DELAY8(mq_plane_ready, 0)
	

	reg				ctxd_en;
	reg		[5:0]	ctx;
	reg				d;	
	always @(*) 
		if (mq_sig_e) begin
			ctxd_en = sig_pass_ctxd_en;
			ctx     = sig_pass_ctx;
			d       = sig_pass_d;
		end else if (mq_ref_e) begin
			ctxd_en = ref_pass_ctxd_en;
			ctx     = ref_pass_ctx;
			d       = ref_pass_d;
		end else if (mq_cln_e) begin
			ctxd_en = cln_pass_ctxd_en;
			ctx     = cln_pass_ctx;
			d       = cln_pass_d;
		end else begin
			ctxd_en = 0;
			ctx     = 0;
			d       = 0;
		end
			
	wire	flush = mq_plane_ready_d2 && bitplane_cnt==0;
	assign mq_ready = mq_plane_ready_d8;
		
	wire	mq_init_f = band_go;

	wire					bytes_out_f;
	wire					bytes_out_len;
	wire	[15:0]			bytes_out;

	mq	mq(
		.clk		(clk),
		.rstn		(rstn),
		.init_f		(mq_init_f),
		.en			(ctxd_en),
		.pass		(8'd0),
		.CX			(ctx),
		.D			(d),
		.flush_f	(flush),

		.bytes_out_f	(bytes_out_f),
		.bytes_out_len	(bytes_out_len),
		.bytes_out		(bytes_out),

		.pp			()
		);

	
	reg		[7:0]	byte_fifo0, byte_fifo1, byte_fifo2, byte_fifo3;
	reg		[3:0]	byte_fifo_cnt;
	
	wire	byte_fifo_rd = byte_fifo_cnt !=0;
	always @(`CLK_RST_EDGE)
		if (`RST)				byte_fifo_cnt <= 0;
		else case({bytes_out_f, byte_fifo_rd})	
			2'b10:	byte_fifo_cnt <= byte_fifo_cnt +  bytes_out_len + 1;
			2'b01:	byte_fifo_cnt <= byte_fifo_cnt - 1;
			2'b11:	byte_fifo_cnt <= byte_fifo_cnt +  bytes_out_len;
			endcase

	always @(`CLK_RST_EDGE)
		if (`RST)	{byte_fifo0, byte_fifo1, byte_fifo2, byte_fifo3} <= 0;
		else if (bytes_out_f)
			{byte_fifo0, byte_fifo1, byte_fifo2, byte_fifo3} <= 
					!bytes_out_len? {bytes_out[15-:8], byte_fifo0, byte_fifo1, byte_fifo2}
								  : {bytes_out[7-:8], bytes_out[15-:8], byte_fifo0, byte_fifo1};
	
	// reg				byte_out_f;
	// reg		[7:0]	byte_out;
	always @(`CLK_RST_EDGE)
		if (`RST)	byte_out_f <= 0;
		else 		byte_out_f <= byte_fifo_rd;
	always @(`CLK_RST_EDGE)
		if (`RST)	byte_out <= 0;
		else case(byte_fifo_cnt)
			default:	byte_out <= byte_fifo0;
				2:		byte_out <= byte_fifo1;
				3:		byte_out <= byte_fifo2;
				4:		byte_out <= byte_fifo3;
			endcase
	

	reg		[15:0]	codeword_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)				codeword_cnt <= 0;
		else if (band_go)		codeword_cnt <= 0;
		else if (byte_out_f)	codeword_cnt <= codeword_cnt + 1;


	// should use code block ready and  code block cnt ,
	// but in  a  band  only have  one  code block
	// reg		[0:2][15:0]	codeword_len_buf;
	always @(`CLK_RST_EDGE)
		if (`RST)				codeword_len_buf <= 0;
		else if (band_ready)	
			if (lvl_cnt ==0 ) codeword_len_buf[lvl_cnt][band_cnt] <= codeword_cnt;
			else 			  codeword_len_buf[lvl_cnt][band_cnt-1] <= codeword_cnt;
	
endmodule
