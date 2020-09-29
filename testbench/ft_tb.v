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
	wire		[`W1:0]		x0         	= itf.x0;
	wire		[`W1:0]		x1         	= itf.x1;
	
	wire					go = itf.go;
	
	initial begin
		itf.init();
		#(`RESET_DELAY)
		#(`RESET_DELAY)
		//itf.start();
		itf.drive();
		#(`RESET_DELAY)
		//itf.drive_a_frame();
		#(500000* `TIME_COEFF)
		$finish();
	end	
	
	wire	[`W1:0]	y0, y1;
	
	wire	[13:0]			aa_src_rom;
	wire	[`W2:0]			qa_src_rom;

	
	src_rom src_rom(
		.clk			(clk),
		.rstn			(rstn),
		.aa				(aa_src_rom),
		.cena			(cena_src_rom),
		.qa				(qa_src_rom)
		);
		
		
	
	
	wire	[7:0]			aa_coeff_buf;
	wire					cena_coeff_buf;
	wire	[7:0]			ab_coeff_buf;
	wire	[`W_WT1P*2-1:0]	db_coeff_buf;
	wire					cenb_coeff_buf;
	wire	[`W_WT1P*8-1:0]	qa_coeff_buf;
	wire	[3:0]			wenb_coeff_buf;
	
	rfdp256x96_wp24 coeff_buf(
		.CLKA   (clk),
		.CENA   (cena_coeff_buf),
		.AA     (aa_coeff_buf),
		.QA     (qa_coeff_buf),
		.CLKB   (clk),
		.WENB   (wenb_coeff_buf),
		.CENB   (cenb_coeff_buf),
		.AB     (ab_coeff_buf),
		.DB     ({4{db_coeff_buf}})
		);
	
		
	ft_53_core ft_53_core(
		.clk	(clk),
		.rstn			(rstn),
		.width			(`DW_WIDTH),
		.go				(go),
		.ndecomp				(1),
		
		.cena_src_buf	(cena_src_rom),
		.aa_src_buf		(aa_src_rom),
		.qa_src_buf		(qa_src_rom),

	
		//.col_start		(col_start),
		//.col_end		(col_end),
		.o_en			(o_en),
		.y0				(y0),
		.y1				(y1),
		
	
		.db_coeff_buf	(db_coeff_buf),
		.cenb_coeff_buf	(cenb_coeff_buf),
		.ab_coeff_buf	(ab_coeff_buf),		
		.wenb_coeff_buf	(wenb_coeff_buf),		

		.ready			(dwt_ready)
		
	);

	
		
		
`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("fsdb/xx.fsdb");
	//$fsdbDumpvars();
	$fsdbDumpvars(3, tb);
	end
`endif
	
endmodule



module src_rom(
	input			clk,
	input			rstn,
	input	[13:0]	aa,
	input			cena,
	output reg		[`W2:0]	qa
	);
	logic [0:`DW_WIDTH*`DW_WIDTH-1][31:0] mem	 = {
 -69, 	 -98, 	 -73, 	  75, 	 -83, 	  23, 	 -58, 	 -17, 		  77, 	  56, 	  15, 	  37, 	  11, 	  25, 	  18, 	  77, 	
  87, 	 122, 	  70, 	 -56, 	 -49, 	 -32, 	  -3, 	 -36, 		 -35, 	  61, 	  50, 	  -5, 	  93, 	 -14, 	-117, 	-104, 	
  16, 	 -62, 	  99, 	  62, 	  89, 	 -87, 	 -83, 	  39, 		  97, 	  60, 	 -52, 	 -20, 	 -42, 	  94, 	 -70, 	 -83, 	
  88, 	-128, 	 -11, 	 -89, 	 -32, 	 115, 	   4, 	  62, 		  48, 	 -74, 	 -71, 	  14, 	  40, 	 -60, 	  38, 	 -72, 	
   7, 	  10, 	 118, 	 -32, 	  51, 	 -92, 	-121, 	  21, 		  96, 	 -45, 	-127, 	 -74, 	 -79, 	 -69, 	 -29, 	-118, 	
 -69, 	  89, 	 -79, 	  28, 	  76, 	  53, 	 -38, 	  -4, 		 107, 	  19, 	-118, 	  19, 	  87, 	  49, 	  76, 	 -34, 	
 -69, 	  66, 	  63, 	 110, 	 102, 	  70, 	   3, 	  71, 		-102, 	   5, 	 125, 	 -53, 	  64, 	 -31, 	 -43, 	 124, 	
 -64, 	-115, 	 -53, 	 119, 	 -91, 	 -78, 	 -78, 	  75, 		  84, 	  74, 	  46, 	 126, 	 -99, 	-117, 	 -14, 	 106, 	

  79, 	-105, 	 120, 	  -2, 	  51, 	 -32, 	  29, 	 -60, 		 -18, 	 108, 	 -85, 	  -9, 	 -24, 	  34, 	-125, 	  41, 	
  47, 	 -50, 	  32, 	  84, 	   0, 	  82, 	  31, 	 -43, 		  29, 	 -50, 	 -45, 	  58, 	 -39, 	  70, 	  37, 	 -88, 	
  93, 	  29, 	  38, 	  16, 	 125, 	 -61, 	  84, 	 -21, 		 -81, 	 127, 	  98, 	  24, 	  33, 	 102, 	 -63, 	 -48, 	
 -76, 	  97, 	 -92, 	  53, 	  51, 	  68, 	-118, 	 -48, 		-110, 	 -35, 	-117, 	 -21, 	 -93, 	  48, 	  19, 	-128, 	
 -51, 	 -71, 	  16, 	 -54, 	  -4, 	 -28, 	  53, 	  43, 		 -29, 	  23, 	 -61, 	-124, 	  -3, 	   4, 	 -44, 	  50, 	
 -27, 	  -7, 	 -25, 	-103, 	 -67, 	 -15, 	 -23, 	 -49, 		  78, 	 -12, 	  58, 	 114, 	 -92, 	 -51, 	 114, 	 -15, 	
  76, 	-116, 	 106, 	 -32, 	 114, 	 -30, 	 124, 	  72, 		 -87, 	 -98, 	-108, 	  21, 	  -9, 	 -69, 	 -99, 	 -18, 	
 -42, 	-128, 	 -11, 	  79, 	  11, 	 -38, 	-103, 	  -6, 		-113, 	 -38, 	-104, 	   7, 	-125, 	 109, 	 -60, 	  80



  };
	
	wire	[7:0] 	row = aa /`DW_WIDTH;
	wire	[7:0] 	col = aa % `DW_WIDTH;
	always @(`CLK_RST_EDGE)
		if (`RST)	qa <= 0;
		else if (!cena)		qa <= { mem[row *2*`DW_WIDTH + col][`W1:0], mem[row *2*`DW_WIDTH + col + `DW_WIDTH ][`W1:0]};
endmodule



interface itf(input clk);
	logic					first_row;
	logic					second_row;
	logic					last_row;
	logic					one_plus_row;
	logic					row_start	;
	logic					row_end	;
	logic					en		;	
	logic		[`W1:0]		x0;
	logic		[`W1:0]		x1;
	logic					go;
	
	
	clocking cb@( `CLK_EDGE);
		output	en;
		//input 	ready;
	endclocking	
	task init();
		en		 <= 0;
		go 		<= 0;
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
	/*
	//task drive_frame(logic [`MAX_PATH*8-1:0]	sequence_name; , int nframe);
	task start();
			logic [0:`DW_WIDTH-1][0:`DW_WIDTH-1][31:0] src = {
 -48, 	 -75, 	-118, 	 -77, 	 -78, 	 -80, 	 -96, 	 -78, 	 -76, 	 -80, 	-118, 	 -78, 	 -75, 	 -75, 	-118, 	  58, 		  51, 	  25, 	  16, 	  25, 	  40, 	  48, 	  48, 	  45, 	  31, 	   0, 	 -13, 	  -3, 	  -3, 	   5, 	   9, 	   9, 	
   6, 	 -13, 	 -16, 	 -21, 	  -9, 	  13, 	  31, 	  33, 	  29, 	  19, 	  19, 	  23, 	  26, 	  15, 	  29, 	  15, 		  16, 	   9, 	  -8, 	  -9, 	 -29, 	 -19, 	  -3, 	   3, 	  23, 	  22, 	  19, 	  27, 	  31, 	  29, 	  41, 	  35, 	
  32, 	  48, 	  51, 	  55, 	  52, 	  52, 	  52, 	  46, 	  34, 	  28, 	  12, 	  13, 	  -1, 	  -6, 	  -2, 	  -4, 		 -13, 	 -16, 	 -21, 	 -17, 	 -18, 	 -26, 	 -22, 	 -27, 	 -29, 	 -28, 	 -21, 	 -18, 	  -7, 	  -5, 	 -10, 	 -21, 	
 -33, 	 -29, 	  10, 	  24, 	  19, 	  -3, 	  -6, 	 -26, 	 -26, 	 -24, 	 -21, 	   2, 	  15, 	  19, 	  -5, 	 -18, 		 -12, 	 -33, 	 -50, 	 -52, 	 -25, 	 -11, 	  -3, 	   5, 	   3, 	   9, 	  15, 	   6, 	   7, 	   3, 	 -39, 	 -40, 	
 -16, 	  15, 	  31, 	  35, 	  34, 	  31, 	  31, 	  27, 	  25, 	  14, 	 -12, 	 -43, 	 -44, 	 -47, 	 -27, 	 -20, 		 -20, 	 -28, 	   1, 	  20, 	  34, 	  28, 	  38, 	  37, 	  23, 	  21, 	   9, 	 -20, 	 -14, 	 -19, 	  -1, 	  -7, 	
  11, 	  17, 	  15, 	  22, 	  27, 	  40, 	  46, 	  46, 	  50, 	  38, 	  42, 	  45, 	  40, 	  46, 	  47, 	  51, 		  48, 	  42, 	  33, 	  27, 	  17, 	  -8, 	  -1, 	  -4, 	 -15, 	  -2, 	   1, 	  19, 	   7, 	 -19, 	 -36, 	 -58, 	
 -58, 	 -57, 	 -43, 	 -21, 	 -19, 	 -12, 	 -27, 	 -39, 	 -40, 	 -38, 	 -38, 	 -33, 	 -21, 	 -20, 	 -24, 	 -28, 		   3, 	  16, 	  28, 	  28, 	  34, 	  19, 	   2, 	 -24, 	 -13, 	  13, 	  30, 	  30, 	  33, 	  30, 	  27, 	  15, 	
   6, 	   2, 	  21, 	  53, 	  43, 	  40, 	  39, 	  41, 	  62, 	  58, 	  54, 	  63, 	  64, 	  52, 	  44, 	  30, 		  30, 	  44, 	  58, 	  62, 	  60, 	  61, 	  62, 	  58, 	  49, 	  46, 	  46, 	  44, 	  46, 	  43, 	  37, 	  38, 	
  39, 	  34, 	  31, 	  22, 	  20, 	  25, 	  28, 	   9, 	 -12, 	  27, 	  34, 	  22, 	  33, 	  30, 	  27, 	  22, 		  30, 	  16, 	  15, 	   7, 	   7, 	 -21, 	  -3, 	  25, 	  22, 	  21, 	  30, 	  43, 	  38, 	  47, 	  52, 	  64, 	
  71, 	  73, 	  76, 	  77, 	  83, 	  84, 	  82, 	  76, 	  82, 	  80, 	  82, 	  82, 	  77, 	  71, 	  75, 	  74, 		  74, 	  70, 	  64, 	  58, 	  70, 	  69, 	  58, 	  59, 	  42, 	  37, 	  43, 	  31, 	  23, 	  13, 	   9, 	   1, 	
  -7, 	 -18, 	 -27, 	 -47, 	 -64, 	 -73, 	 -80, 	 -74, 	 -82, 	 -78, 	 -91, 	 -88, 	 -97, 	 -94, 	 -94, 	  26, 		   3, 	  -9, 	   3, 	  22, 	  46, 	  40, 	  43, 	  42, 	  29, 	  15, 	 -15, 	 -12, 	   5, 	  12, 	   8, 	   9, 	
  -5, 	 -15, 	 -15, 	 -21, 	  -9, 	  11, 	  23, 	  28, 	  26, 	  28, 	  15, 	  24, 	  24, 	  10, 	  28, 	  29, 		  16, 	   9, 	  -7, 	  -3, 	 -27, 	 -16, 	  -3, 	  11, 	  22, 	  20, 	  26, 	  33, 	  31, 	  33, 	  34, 	  31, 	
  37, 	  52, 	  50, 	  52, 	  50, 	  51, 	  42, 	  41, 	  34, 	  25, 	  21, 	  16, 	  10, 	  -3, 	   0, 	  -8, 		 -13, 	 -21, 	 -14, 	 -24, 	 -15, 	 -26, 	 -27, 	 -21, 	 -30, 	 -21, 	 -23, 	 -12, 	  -9, 	  -3, 	  -1, 	 -13, 	
 -30, 	 -38, 	  -1, 	   7, 	  15, 	  -2, 	 -12, 	 -16, 	 -24, 	 -19, 	 -13, 	   8, 	  11, 	  14, 	  -6, 	 -18, 		 -15, 	 -36, 	 -46, 	 -56, 	 -35, 	  -7, 	  11, 	   2, 	   7, 	  10, 	   8, 	   3, 	  -1, 	 -19, 	 -39, 	 -42, 	
 -12, 	  16, 	  24, 	  31, 	  29, 	  21, 	  28, 	  28, 	  26, 	  15, 	 -11, 	 -42, 	 -45, 	 -32, 	 -26, 	 -15, 		 -24, 	 -47, 	 -28, 	   7, 	  23, 	  29, 	  27, 	  22, 	  12, 	   5, 	 -11, 	 -27, 	 -22, 	 -15, 	  -2, 	  -5, 	
   0, 	  22, 	  30, 	  34, 	  40, 	  40, 	  45, 	  50, 	  43, 	  40, 	  40, 	  40, 	  40, 	  39, 	  46, 	  50, 		  49, 	  48, 	  38, 	  29, 	  10, 	  -1, 	  -3, 	  -6, 	  -5, 	   7, 	  15, 	  12, 	  19, 	  -6, 	 -36, 	 -45, 	

 -44, 	 -29, 	 -13, 	 -17, 	 -21, 	 -29, 	 -40, 	 -45, 	 -33, 	 -33, 	 -16, 	  -6, 	   9, 	   3, 	  -8, 	  -9, 		  21, 	  26, 	  41, 	  46, 	  44, 	  27, 	   3, 	 -20, 	   3, 	  21, 	  32, 	  36, 	  34, 	  26, 	  31, 	  11, 	
  -6, 	   9, 	  22, 	  51, 	  37, 	  34, 	  28, 	  43, 	  60, 	  76, 	  68, 	  70, 	  68, 	  53, 	  50, 	  40, 		  34, 	  42, 	  59, 	  65, 	  64, 	  63, 	  62, 	  61, 	  59, 	  51, 	  43, 	  38, 	  39, 	  32, 	  36, 	  34, 	
  32, 	  25, 	  22, 	  27, 	  29, 	  33, 	  35, 	   7, 	  -9, 	  17, 	  23, 	  16, 	  21, 	  19, 	  21, 	  29, 		  32, 	  15, 	  -7, 	 -27, 	 -35, 	 -40, 	  -2, 	  32, 	  40, 	  49, 	  59, 	  70, 	  68, 	  74, 	  73, 	  81, 	
  82, 	  77, 	  86, 	  79, 	  80, 	  76, 	  76, 	  82, 	  79, 	  77, 	  81, 	  70, 	  75, 	  69, 	  70, 	  58, 		  60, 	  47, 	  50, 	  45, 	  60, 	  48, 	  40, 	  28, 	  12, 	  -9, 	  -1, 	 -16, 	 -15, 	 -37, 	 -45, 	 -58, 	
 -41, 	 -48, 	 -68, 	 -75, 	 -87, 	 -75, 	 -88, 	 -76, 	 -82, 	 -90, 	 -89, 	 -85, 	 -78, 	 -73, 	 -83, 	 -32, 		 -55, 	 -28, 	  -2, 	  17, 	  35, 	  36, 	  43, 	  43, 	  28, 	  12, 	 -10, 	  -9, 	  -1, 	   0, 	   5, 	  -7, 	
  -4, 	 -11, 	 -29, 	 -20, 	 -12, 	  12, 	  28, 	  28, 	  22, 	  28, 	  22, 	  16, 	  18, 	   8, 	  34, 	  32, 		  15, 	   0, 	  -3, 	  -1, 	 -21, 	 -19, 	  -2, 	  18, 	  22, 	  23, 	  27, 	  25, 	  32, 	  29, 	  28, 	  29, 	
  30, 	  40, 	  46, 	  55, 	  49, 	  47, 	  38, 	  40, 	  30, 	  22, 	  23, 	  12, 	   9, 	  -6, 	  -9, 	 -16, 		 -21, 	 -15, 	 -19, 	 -30, 	 -14, 	 -24, 	 -23, 	 -27, 	 -33, 	 -15, 	 -26, 	 -21, 	 -18, 	  -5, 	  -7, 	 -20, 	
 -37, 	 -37, 	   3, 	  20, 	   8, 	   3, 	 -27, 	 -36, 	 -27, 	 -16, 	 -14, 	   4, 	  13, 	   5, 	 -12, 	 -16, 		 -25, 	 -27, 	 -59, 	 -65, 	 -45, 	 -13, 	   9, 	   3, 	   8, 	  10, 	   9, 	   2, 	  -4, 	 -18, 	 -61, 	 -53, 	
 -22, 	  11, 	  17, 	  22, 	  24, 	  28, 	  16, 	  28, 	  16, 	  11, 	 -18, 	 -42, 	 -47, 	 -22, 	 -19, 	 -14, 		 -30, 	 -57, 	 -35, 	  -3, 	  15, 	   6, 	  -1, 	   3, 	   3, 	  -3, 	 -23, 	 -28, 	 -17, 	   1, 	  -6, 	  -1, 	
   2, 	  19, 	  26, 	  23, 	  40, 	  44, 	  44, 	  43, 	  40, 	  37, 	  32, 	  28, 	  34, 	  30, 	  40, 	  39, 		  34, 	  40, 	  32, 	  22, 	   2, 	 -15, 	 -14, 	  -7, 	   3, 	   5, 	  22, 	  30, 	  22, 	   5, 	 -27, 	 -33, 	
 -28, 	 -12, 	   8, 	   1, 	 -32, 	 -27, 	 -22, 	 -23, 	  -3, 	   3, 	  15, 	   4, 	  12, 	   7, 	   6, 	  18, 		  23, 	  37, 	  43, 	  40, 	  36, 	  28, 	   7, 	  -9, 	  15, 	  35, 	  47, 	  42, 	  32, 	  39, 	  34, 	  22, 	
  21, 	  30, 	  42, 	  52, 	  34, 	  29, 	  22, 	  50, 	  64, 	  70, 	  68, 	  70, 	  71, 	  56, 	  45, 	  37, 		  28, 	  48, 	  60, 	  62, 	  56, 	  52, 	  58, 	  57, 	  56, 	  42, 	  36, 	  36, 	  29, 	  27, 	  26, 	  22, 	
  28, 	  27, 	  25, 	  20, 	  27, 	  33, 	  28, 	  -9, 	 -16, 	  10, 	  24, 	  18, 	  18, 	  26, 	  30, 	  32, 		  34, 	  30, 	   5, 	 -28, 	   2, 	   4, 	  43, 	  61, 	  64, 	  70, 	  75, 	  76, 	  74, 	  76, 	  76, 	  76, 	
  72, 	  68, 	  71, 	  58, 	  73, 	  70, 	  67, 	  70, 	  65, 	  68, 	  70, 	  63, 	  70, 	  59, 	  56, 	  54, 		  31, 	  29, 	  24, 	  20, 	  15, 	  13, 	  -5, 	 -28, 	 -33, 	 -43, 	 -41, 	 -50, 	 -68, 	 -71, 	 -79, 	 -79, 	
 -84, 	 -88, 	 -85, 	 -82, 	 -81, 	 -79, 	 -88, 	 -76, 	 -76, 	 -77, 	 -76, 	 -59, 	 -70, 	 -77, 	 -78, 	 -60, 		 -68, 	 -39, 	  -5, 	  20, 	  30, 	  38, 	  44, 	  40, 	  21, 	  -6, 	 -22, 	 -21, 	  -2, 	   4, 	  10, 	   3, 	
  -3, 	 -16, 	 -31, 	 -25, 	  -3, 	  12, 	  25, 	  29, 	  20, 	  16, 	  26, 	  18, 	  22, 	  17, 	  25, 	  30, 		  26, 	  -2, 	  -1, 	 -16, 	 -20, 	 -19, 	  -8, 	   9, 	  15, 	  22, 	  31, 	  27, 	  28, 	  25, 	  28, 	  30
			};
			@cb;
			@cb;
			for(int row = 0; row < `DW_WIDTH/2 +1; row++) 
				for(int col = 0; col < `DW_WIDTH; col = col+1) begin
					first_row <= row == 0;
					second_row <= row==1;
					last_row <= row == `DW_WIDTH-1;
					one_plus_row <= row == `DW_WIDTH/2;
					en <= 1;
					row_start <= col == 0;
					row_end <= col == `DW_WIDTH-1;
					x0 <= src[row*2][col];
					x1 <= src[row*2+1][col];
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
			
			
	endtask
	*/
endinterface
