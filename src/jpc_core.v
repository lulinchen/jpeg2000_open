// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

module jpc_core(
	input					clk,
	input					rstn,
	
	input		[15:0]		pic_width,
	input		[15:0]		pic_height,
	
	input		[2:0]		ndecomp,
	
	input					go,
	input					first_tile_f,
	input					last_tile_f,

	output 					cena_src_buf,
	output 		[13:0]		aa_src_buf,
	input		[`W2:0]		qa_src_buf,

	output reg 				byte_out_f,
	output reg	[7:0]		byte_out,
	
	output reg				busy,
	output reg				pic_ready,

	output reg				ready	
	);


	
	reg							wid_coeff_buf;
	reg							rid_coeff_buf;
	
	wire	[`W_AA_COEFF_BUF:0]	aa_coeff_buf;
	wire						cena_coeff_buf;
	wire	[`W_AB_COEFF_BUF:0]	ab_coeff_buf;
	wire	[`W_WT1P*2-1:0]		db_coeff_buf;
	wire						cenb_coeff_buf;
	wire	[`W_WT1P*8-1:0]		_qa_coeff_buf;
	wire	[3:0]				wenb_coeff_buf;

	`DELAY1(aa_coeff_buf, `W_AA_COEFF_BUF)
	wire	[`W_WT1P*4-1:0]	 qa_coeff_buf = !aa_coeff_buf_d1[0]? 
											{_qa_coeff_buf[`W_WT1P*8-1 -: `W_WT1P], _qa_coeff_buf[`W_WT1P*6-1 -: `W_WT1P], _qa_coeff_buf[`W_WT1P*4-1 -: `W_WT1P], _qa_coeff_buf[`W_WT1P*2-1 -: `W_WT1P] } :
											{_qa_coeff_buf[`W_WT1P*7-1 -: `W_WT1P], _qa_coeff_buf[`W_WT1P*5-1 -: `W_WT1P], _qa_coeff_buf[`W_WT1P*3-1 -: `W_WT1P], _qa_coeff_buf[`W_WT1P*1-1 -: `W_WT1P] } ;
	
	// 128x 128/ 8 *2 =  
	rfdp4096x96_wp24 coeff_buf(
		.CLKA   (clk),
		.CENA   (cena_coeff_buf),
		.AA     ({rid_coeff_buf, aa_coeff_buf[`W_AA_COEFF_BUF:1]}),
		.QA     (_qa_coeff_buf),
		.CLKB   (clk),
		.WENB   (wenb_coeff_buf),
		.CENB   (cenb_coeff_buf),
		.AB     ({wid_coeff_buf, ab_coeff_buf}),
		.DB     ({4{db_coeff_buf}})
		);


	wire	dwt_go;
	wire	dwt_ready;
	reg		dwt_busy;
	reg		dwt_done;
	always @(`CLK_RST_EDGE)
		if (`RST)			dwt_busy <= 0;
		else if (dwt_go)	dwt_busy <= 1;
		else if (dwt_ready)	dwt_busy <= 0;

	assign	dwt_go = go & !dwt_done & !dwt_busy;
	
	always @(*) busy = dwt_busy | dwt_done;

	wire	[0:7][0:3][3:0]		codeblock_numbps;
	
	reg			first_tile_f_dwt;
	reg			last_tile_f_dwt;
	always @(`CLK_RST_EDGE)
		if (`RST)			first_tile_f_dwt <= 0;
		else if(dwt_go)		first_tile_f_dwt <= first_tile_f;
	always @(`CLK_RST_EDGE)
		if (`RST)			last_tile_f_dwt <= 0;
		else if(dwt_go)		last_tile_f_dwt <= last_tile_f;
	
	always @(`CLK_RST_EDGE)
		if (`RST)				wid_coeff_buf <= 0;
		else if (dwt_ready)		wid_coeff_buf <= wid_coeff_buf + 1;
	
	ft_53_core ft_53_core(
		.clk	(clk),
		.rstn			(rstn),
		.width			(`TILE_WIDTH),
		.go				(dwt_go),
		.ndecomp		(ndecomp),
		
		.cena_src_buf	(cena_src_buf),
		.aa_src_buf		(aa_src_buf),
		.qa_src_buf		(qa_src_buf),

		
		.codeblock_numbps	(codeblock_numbps),

		.db_coeff_buf	(db_coeff_buf),
		.cenb_coeff_buf	(cenb_coeff_buf),
		.ab_coeff_buf	(ab_coeff_buf),		
		.wenb_coeff_buf	(wenb_coeff_buf),		

		.ready			(dwt_ready)
		);


	wire		t1_go;
	wire		t1_ready;
	reg			t1_busy;
	reg			t1_done;

	always @(`CLK_RST_EDGE)
		if (`RST)				t1_busy <= 0;
		else if (t1_go) 		t1_busy <= 1;
		else if (t1_ready)		t1_busy <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)				dwt_done <= 0;
		else if (dwt_ready)		dwt_done <= 1;
		else if (t1_go)			dwt_done <= 0;
	
	assign 	t1_go = dwt_done & !t1_busy;
	
	
	wire	[0:7][0:2][7:0]		zero_bitplanes_buf;
	wire	[0:7][0:2][7:0]		pass_num_buf;
	wire	[0:7][0:2][15:0]	codeword_len_buf;

	wire	[3:0]		t1_lvl_cnt;
	wire				t1_lvl_ready;

	wire				mq_byte_out_f;
	wire	[7:0]		mq_byte_out;

	reg			first_tile_f_t1;
	reg			last_tile_f_t1;

	always @(`CLK_RST_EDGE)
		if (`RST)			first_tile_f_t1 <= 0;
		else if(t1_go)		first_tile_f_t1 <= first_tile_f_dwt;
	always @(`CLK_RST_EDGE)
		if (`RST)			last_tile_f_t1 <= 0;
		else if(t1_go)		last_tile_f_t1 <= last_tile_f_dwt;
	always @(`CLK_RST_EDGE)
		if (`RST)				rid_coeff_buf <= 0;
		else if (t1_ready)		rid_coeff_buf <= rid_coeff_buf + 1;
	
	tier1 t1(
		.clk				(clk),
		.rstn				(rstn),

		.go					(t1_go),
		.ndecomp			(ndecomp),
		.codeblock_numbps	(codeblock_numbps),

		.ready_for_next_lvl	(1'b1),

		.aa_coeff_buf		(aa_coeff_buf),
		.cena_coeff_buf		(cena_coeff_buf),
		.qa_coeff_buf		(qa_coeff_buf),


		.zero_bitplanes_buf	(zero_bitplanes_buf),
		.pass_num_buf		(pass_num_buf),
		.codeword_len_buf	(codeword_len_buf),

		.lvl_cnt			(t1_lvl_cnt),
		.lvl_ready			(t1_lvl_ready),

		.byte_out_f			(mq_byte_out_f),
		.byte_out			(mq_byte_out),

		.mq_ready			(mq_ready),
		
		.tile_ready			(t1_ready)
		);

	wire			tier1_fifo_rd;
	wire	[7:0]	tier1_fifo_byte;

	fifo_sync #(
		.DW		(8),
		.DEPTH	(32768)
		) tier1_stream_fifo(
		.clk		(clk),
		.rstn		(rstn),
		
		.din		(mq_byte_out),
		.wr_en		(mq_byte_out_f),

		.rd_en		(tier1_fifo_rd),
		.dout		(tier1_fifo_byte),

		.full		(tier1_fifo_full),
		.empty		(tier1_fifo_empty)
		);

`ifdef SIMULATING
	always @(`CLK_EDGE)
		if (tier1_fifo_full) begin
			$display("===ERROR====tier1_fifo_full====");
			$finish();
		end	
	
`endif

	//-----------------------------------------

	wire		t2_go;
	wire		t2_ready;
	reg			t2_busy;

	always @(`CLK_RST_EDGE)
		if (`RST)				t1_done <= 0;
		else if (t1_ready)		t1_done <= 1;
		else if (t2_go)			t1_done <= 0;
	
	assign t2_go = t1_done & !t2_busy;
	
	always @(`CLK_RST_EDGE)
		if (`RST)				t2_busy <= 0;
		else if (t2_go) 		t2_busy <= 1;
		else if (t2_ready)		t2_busy <= 0;		
	
	reg		[15:0]	tile_cnt;
	reg				main_header_done;

	wire			t2_byte_out_f;
	wire	[ 7:0]	t2_byte_out;

	reg			first_tile_f_t2;
	reg			last_tile_f_t2;

	always @(`CLK_RST_EDGE)
		if (`RST)			first_tile_f_t2 <= 0;
		else if(t2_go)		first_tile_f_t2 <= first_tile_f_t1;
	always @(`CLK_RST_EDGE)
		if (`RST)			last_tile_f_t2 <= 0;
		else if(t2_go)		last_tile_f_t2 <= last_tile_f_t1;
	
	tier2 tier2(
		.clk			(clk),
		.rstn			(rstn),

		.go				(t2_go),
		.tile_cnt		(tile_cnt),
		.ndecomp		(ndecomp),
		
		.main_header_done	(main_header_done),
		


		.t1_fifo_rd		(tier1_fifo_rd),
		.t1_fifo_byte	(tier1_fifo_byte),

		.pass_num_buf_i			(pass_num_buf),
		.zero_bitplanes_buf_i	(zero_bitplanes_buf),
		.codeword_len_buf_i		(codeword_len_buf),

		
		.byte_out_f		(t2_byte_out_f),
		.byte_out		(t2_byte_out),
	
		.ready			(t2_ready)
		);
	
	
	`DELAY1(t2_go, 0)
	always @(`CLK_RST_EDGE)
		if (`RST)							tile_cnt <= 0;
		else if (t2_go_d1 & first_tile_f_t2)tile_cnt <= 0;
		else if (t2_ready) 					tile_cnt <= tile_cnt + 1;	
	
	wire 	main_header_go = t2_go_d1 && first_tile_f_t2;
	wire	header_ready;
	wire 	eoc_go = t2_ready && last_tile_f_t2;
	always @(`CLK_RST_EDGE)
		if (`RST)						main_header_done <= 0;
		else if (main_header_go) 		main_header_done <= 0;
		else if (header_ready)			main_header_done <= 1;

	wire 	            header_data_valid;
    wire       [ 7:0]   header_data_out;

	header_gen header_gen(
		.clk			(clk),
		.rstn			(rstn),
		
		.go				(main_header_go),
		.eoc_go			(eoc_go),
		
		.pic_width		(pic_width),
		.pic_height		(pic_height),

		.ncomps			(1),
		.ndecomp		(ndecomp),

		.data_valid		(header_data_valid),
		.data_out		(header_data_out),

		.ready			(header_ready)
		);


	always @(`CLK_RST_EDGE)
		if (`RST)	byte_out_f <= 0;
		else 		byte_out_f <= header_data_valid | t2_byte_out_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	byte_out <= 0;
		else 		byte_out <= header_data_valid? header_data_out : t2_byte_out;
	`DELAY4(eoc_go, 0)
	always @(`CLK_RST_EDGE)
		if (`RST)	pic_ready <= 0;
		else 		pic_ready <= eoc_go_d4;
	

`ifdef SIMULATING
	reg			doing_dwt;
	reg			doing_t1;	
	reg			doing_t2;

	always @(`CLK_RST_EDGE)
		if (`RST)			doing_dwt <= 0;
		else if (dwt_go)	doing_dwt <= 1;
		else if (dwt_ready)	doing_dwt <= 0;

	always @(`CLK_RST_EDGE)
		if (`RST)				doing_t1 <= 0;
		else if (t1_go) 		doing_t1 <= 1;
		else if (t1_ready)	doing_t1 <= 0;

	always @(`CLK_RST_EDGE)
		if (`RST)			doing_t2 <= 0;
		else if (t2_go)		doing_t2 <= 1;
		else if (t2_ready) 	doing_t2 <= 0;

`endif



endmodule
