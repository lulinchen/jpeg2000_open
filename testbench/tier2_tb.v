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

	
	packet_header	packet_header(
		.clk		(clk),
		.rstn		(rstn),

		.go						(itf.go),
		.zero_bitplanes			(1),
		.pass_num				(22),
		.codeword_len			(4323),

		// .zero_bitplanes			(2),
		// .pass_num				(19),
		// .codeword_len			(3365),

		.pp			()
		);
	
	
		
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

	logic 					go;

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
		go 		<= 0;
		
		// fp = $fopen(sequence_name_0,"r");

		// if (fp == 0) begin
			// errno = $ferror(fp, errinfo);
			// $display("Failed to open file %0s for read.", sequence_name_0);
			// $display("errno: %0d", errno);
			// $display("reason: %0s", errinfo);
			// $finish();
		// end

		// ret = $fscanf(fp, "jpc_encclnpass");
		
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
			go <= 1;
			@cb;
			go <= 0;
			@cb;
			@cb;
		// end
	endtask
	
endinterface
