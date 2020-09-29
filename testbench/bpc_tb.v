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

	wire					first_row  	= itf.first_row;
	wire					second_row 	= itf.second_row;
	wire					last_row 	= itf.last_row;
	wire					one_plus_row 	= itf.one_plus_row;
	wire					row_start	= itf.row_start	;
	wire					row_end	   	= itf.row_end	;
	wire					en		   	= itf.en			;
	wire		[`W_WT1:0]		x0         	= itf.x0;
	wire		[`W_WT1:0]		x1         	= itf.x1;
	wire		[`W_WT1:0]		x2        	= itf.x2;
	wire		[`W_WT1:0]		x3         	= itf.x3;
	
	wire					go = itf.go;


	bpc bpc(
		.clk			(clk),
		.rstn			(rstn),
		.coeff0			(x0),
		.coeff1			(x1),
		.coeff2			(x2),
		.coeff3			(x3),
		.coef_en		(en),

		.first_row		(first_row),
		.first_col		(row_start),
		.last_col		(row_end),

		.first_plane	(1'b0),
		.band			(2'b0),
		.bit_pos		(itf.bit_pos),

		.mq_sig_e		(1'b1),
		.mq_ref_e		(1'b1),
		.mq_cln_e		(1'b1),
	
		.pp				()
	
	);

	
	initial begin
		itf.init();
		#(`RESET_DELAY)
		#(`RESET_DELAY)
		itf.start();
		// itf.drive();
		#(`RESET_DELAY)
		//itf.drive_a_frame();
		#(500* `TIME_COEFF)
		$finish();
	end	
	
	wire	[`W1:0]	y0, y1;
	
	wire	[13:0]			aa_src_rom;
	wire	[`W2:0]			qa_src_rom;

	
	// src_rom src_rom(
		// .clk			(clk),
		// .rstn			(rstn),
		// .aa				(aa_src_rom),
		// .cena			(cena_src_rom),
		// .qa				(qa_src_rom)
		// );
		
		

	
		
		
`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("fsdb/xx.fsdb");
	//$fsdbDumpvars();
	$fsdbDumpvars(3, tb);
	end
`endif
	
endmodule



interface itf(input clk);
	logic					first_row;
	logic					second_row;
	logic					last_row;
	logic					one_plus_row;
	logic					row_start	;
	logic					row_end	;
	logic					en		;	
	logic		[`W_WT1:0]		x0;
	logic		[`W_WT1:0]		x1;
	logic		[`W_WT1:0]		x2;
	logic		[`W_WT1:0]		x3;
	logic					go;

	logic					plane_start;
	logic					plane_end;
	logic		[3:0]		bit_pos;
	
	
	clocking cb@( `CLK_EDGE);
		output	en;
		//input 	ready;
	endclocking	
	task init();
		en		 <= 0;
		go 		<= 0;
		x0 <= 0;
		x1 <= 0;
		x2 <= 0;
		x3 <= 0;
		first_row <= 0;
		second_row <= 0;
		row_start <= 0;
		row_end	<= 0;
		plane_start <= 0;
		plane_end <= 0;
		bit_pos <= 0;
	endtask
	task drive();
		@cb;
		@cb;
		@cb;
		go <= 1;
		@cb;
		go <= 0;
		@cb;
	endtask
	
	//task drive_frame(logic [`MAX_PATH*8-1:0]	sequence_name; , int nframe);
	task start();
			logic [0:`BPC_WIDTH-1][0:`BPC_WIDTH-1][31:0] src = {
			-4416,	-6272,	-4672,	4800,	-5312,	1472,	-3712,	-1088,	
			4928,	3584,	 960,	2368,	 704,	1600,	1152,	4928,	
			5568,	7808,	4480,	-3584,	-3136,	-2048,	-192,	-2304,	
			-2240,	3904,	3200,	-320,	5952,	-896,	-7488,	-6656,	
			1024,	-3968,	6336,	3968,	5696,	-5568,	-5312,	2496,	
			6208,	3840,	-3328,	-1280,	-2688,	6016,	-4480,	-5312,	
			5632,	-8192,	-704,	-5696,	-2048,	7360,	 256,	3968,	
			3072,	-4736,	-4544,	 896,	2560,	-3840,	2432,	-4608
			};
			@cb;
			@cb;
			plane_start <= 1;
			bit_pos<= 7;
			@cb;
			@cb;
			@cb;
			for(int row = 0; row < `BPC_WIDTH/4 ; row++) 
				for(int col = 0; col < `BPC_WIDTH; col = col+1) begin
					first_row <= row == 0;
					second_row <= row==1;
					last_row <= row == `BPC_WIDTH-1;
					one_plus_row <= row == `DW_WIDTH/2;
					en <= 1;
					row_start <= col == 0;
					row_end <= col == `BPC_WIDTH-1;
					x0 <= src[row*4  ][col][31]? (0 - src[row*4  ][col]/64) | 1<<`W_WT1 : src[row*4  ][col]/64;
					x1 <= src[row*4+1][col][31]? (0 - src[row*4+1][col]/64) | 1<<`W_WT1 : src[row*4+1][col]/64;
					x2 <= src[row*4+2][col][31]? (0 - src[row*4+2][col]/64) | 1<<`W_WT1 : src[row*4+2][col]/64;
					x3 <= src[row*4+3][col][31]? (0 - src[row*4+3][col]/64) | 1<<`W_WT1 : src[row*4+3][col]/64;
					
					@cb;
				end
			first_row <= 0;
			second_row <= 0;		
			last_row <= 0;
			one_plus_row <= 0;
			row_start <= 0;
			row_end <= 0;
			en <= 0;
			@cb;
			@cb;
			@cb;
			@cb;
			@cb;
			plane_end <= 1;
			@cb;
			plane_end <= 0;
			@cb;
			@cb;
			@cb;
			@cb;
	endtask
	
endinterface
