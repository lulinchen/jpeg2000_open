// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

`define	MAX_PATH			256
module tb();

	parameter  FRAME_WIDTH = 112;
	parameter  FRAME_HEIGHT = 48;
	parameter  SIM_FRAMES = 2;
	reg						rstn;
	reg						clk;
	reg						ee_clk;
	
	wire		rstn_ee = rstn;
	initial begin
		rstn = `RESET_ACTIVE;
		#(`RESET_DELAY); 
		$display("T%d rstn done#############################", $time);
		rstn = `RESET_IDLE;
	end
	
	initial begin
		clk = 1;
		forever begin
			clk = ~clk;
			#(`CLK_PERIOD_DIV2);
		end
	end
	
	initial begin
		ee_clk = 1;
		forever begin
			ee_clk = ~ee_clk;
			#(`EE_CLOCK_PERIOD_DIV2);
		end
	end
	
	reg		gt_ref_clk;
	initial begin
		gt_ref_clk = 1;
		forever begin
			gt_ref_clk = ~gt_ref_clk;
			#(`GT_REF_CLOCK_PERIOD_DIV2);
		end
	end
	
	reg			[15:0]			frame_width_0;
	reg			[15:0]			frame_height_0;
	reg			[31:0]			pic_to_sim;
	reg		[`MAX_PATH*8-1:0]	sequence_name_0;

	itf itf(clk);

	
	initial begin
		itf.init("mq.log");
		#(`RESET_DELAY)
		#(`RESET_DELAY)
		itf.start();
		// itf.drive();
		#(`RESET_DELAY)
		//itf.drive_a_frame();
		#(500* `TIME_COEFF)
		$finish();
	end	
	
	wire				bytes_out_f;
	wire				bytes_out_len;
	wire		[15:0]	bytes_out;

	
	mq	mq(
		.clk		(clk),
		.rstn		(rstn),
		.en			(itf.en),
		.pass		(8'd0),
		.CX			(itf.ctx),
		.D			(itf.bit_d),
		.flush_f	(itf.flush),

		.bytes_out_f	(bytes_out_f),
		.bytes_out_len	(bytes_out_len),
		.bytes_out		(bytes_out),

		.pp			()
		);
	
	reg		[7:0]	data_out_d1, data_out_d2, data_out_d3, data_out_d4, data_out_d5;
	always @(`CLK_RST_EDGE)
		if (`RST)	{data_out_d1, data_out_d2, data_out_d3, data_out_d4, data_out_d5} <= 0;
		else if (bytes_out_f) 		
			{data_out_d1, data_out_d2, data_out_d3, data_out_d4, data_out_d5} <= 
				bytes_out_len? {bytes_out[7-:8] , bytes_out[15-:8] , data_out_d1, data_out_d2, data_out_d3}
						: {bytes_out[15-:8] , data_out_d1, data_out_d2, data_out_d3, data_out_d4};

	reg		[15:0]	pic_data_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)					pic_data_cnt <= 0;
		else if (bytes_out_f) 		pic_data_cnt <= pic_data_cnt + 1 + bytes_out_len;
	
	reg		[`MAX_PATH*8-1:0]	pic_dsc = "enc.jpc";
	integer						fds_pic_dsc;
	initial
		fds_pic_dsc = $fopen(pic_dsc, "wb");
	always @(`CLK_EDGE)
		if (bytes_out_f && pic_data_cnt[1:0]==3)
			$fwrite(fds_pic_dsc, "%u", { bytes_out[15-:8] , data_out_d1, data_out_d2, data_out_d3});
		else if (bytes_out_f && bytes_out_len &&  pic_data_cnt[1:0]==2)
			$fwrite(fds_pic_dsc, "%u", { bytes_out[7-:8] , bytes_out[15-:8] , data_out_d1, data_out_d2});
	
	final begin
		if (pic_data_cnt[1:0]==1)
			$fwrite(fds_pic_dsc, "%u", {  8'h00,8'h00,8'h00, data_out_d1});
		else if (pic_data_cnt[1:0]==2)
			$fwrite(fds_pic_dsc, "%u", { 8'h00,8'h00, data_out_d1 , data_out_d2});
		else if (pic_data_cnt[1:0]==3)
			$fwrite(fds_pic_dsc, "%u", { 8'h00, data_out_d1, data_out_d2, data_out_d3});		
	end


	reg		A_err, C_err, CT_err;
	always @(`CLK_RST_EDGE)
		if (`RST)	{A_err, C_err, CT_err }<= 0;
		else if (itf.en) begin
			A_err <= itf.AREG != mq.A;
			C_err <= itf.CREG != mq.C;
			CT_err <= itf.CTREG != mq.CT;
		end
		
`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("fsdb/xx.fsdb");
	//$fsdbDumpvars();
	$fsdbDumpvars(3, tb);
	end
`endif
	
endmodule



interface itf(input clk);
	logic		[15:0]		AREG;
	logic		[31:0]		CREG;
	logic		[31:0]		CTREG;
	logic		[6:0]		IND;
	logic		[15:0]		MPS	;
	logic		[15:0]		QEVAL	;

	logic		[7:0]		ctx;
	logic		[7:0]		bit_d;

	logic		[7:0]		pass;
		
	logic					en;	
	logic 		[31:0]		bit_cnt;

	logic					flush;	
	
	string 					tmps;

	integer    fp;
	integer						errno;
	reg			[640-1:0]		errinfo;
	integer					ret;

	clocking cb@( `CLK_EDGE);
		output	en;
		//input 	ready;
	endclocking	
	task init(input		[`MAX_PATH*8-1:0]	sequence_name_0);
		integer						errno;
		reg			[640-1:0]		errinfo;
		integer					ret;
		en		 <= 0;
		flush 	 <= 0;
		// go 		<= 0;
		
		fp = $fopen(sequence_name_0,"r");

		if (fp == 0) begin
			errno = $ferror(fp, errinfo);
			$display("Failed to open file %0s for read.", sequence_name_0);
			$display("errno: %0d", errno);
			$display("reason: %0s", errinfo);
			$finish();
		end

		ret = $fscanf(fp, "jpc_encclnpass");
		
	endtask
	
	
	task read_bit();
		ret = $fscanf(fp, "setcurctx: %d\n", ctx);
		ret = $fscanf(fp, "jpc_mqenc_putbit_func: %d, %d \n" , bit_cnt,  bit_d);
		ret = $fscanf(fp, "AREG = %04x, CREG = %08x, CTREG = %d\n",	  AREG, CREG, CTREG);
		ret = $fscanf(fp, "IND = %02d, MPS = %d, QEVAL = %04x\n", IND, MPS, QEVAL);
	endtask
	
	
	task start();
			@cb;
			@cb;
			@cb;
			@cb;
		for (int p=0 ; p< 50; p++) begin
			ret = $fscanf(fp, "pass: %d\n", pass);
			if (ret!=1) 	break;
			$display("pass %d ", p);

			ret = $fscanf(fp, "end %s\n", tmps);
			//$display("%d, %s ", ret, tmps);
			while(ret==0) begin
				read_bit();
				en <= 1;
				@cb;
				en <= 0;
				@cb;
				@cb;
				@cb;
				@cb;
				ret = $fscanf(fp, "end %s\n", tmps);
			end

			
			
		end 

		flush <= 1;
		@cb;
		flush <= 0;
		@cb;
		@cb;
		@cb;	
		// for(int i=0; i<72; i++) begin
			// read_bit();		
			// en <= 1;
			// @cb;
			// en <= 0;
			// @cb;
			// @cb;
			// @cb;
			// @cb;
		// end
	endtask
	
endinterface
