// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"


`define SOC_MARKER 	16'hff4f
`define SIZ_MARKER 	16'hff51
`define	COD_MARKER 	16'hff52
`define	QCD_MARKER 	16'hff5C
`define	SOT_MARKER 	16'hff90
`define	SOD_MARKER 	16'hff93
`define	EOC_MARKER 	16'hffD9
 

typedef struct packed {
    logic [ 15:0] 	SIZ;
    logic [ 15:0] 	Lsiz;

    logic [ 15:0] 	Rsiz;

    logic [ 31:0] 	Xsiz;
    logic [ 31:0] 	Ysiz;

    logic [ 31:0] 	XOsiz;
    logic [ 31:0] 	YOsiz;
 
	logic [ 31:0] 	XTsiz;
    logic [ 31:0] 	YTsiz;
	
	logic [ 31:0] 	XTOsiz;
    logic [ 31:0] 	YTOsiz;

    logic [ 15:0] 	Csiz;

    logic [  7:0] 	Ssiz0;
    logic [  7:0] 	XRsiz0;
    logic [  7:0] 	YRsiz0;

	logic [  7:0] 	Ssiz1;
    logic [  7:0] 	XRsiz1;
    logic [  7:0] 	YRsiz1;

	logic [  7:0] 	Ssiz2;
    logic [  7:0] 	XRsiz2;
    logic [  7:0] 	YRsiz2;
} JpcSizHeader;

typedef struct packed {
    logic [ 15:0] 	COD;
    logic [ 15:0] 	Lcod;

	logic [  7:0]	Scod;
	logic [ 31:0] 	SGcod;

	// logic [ 39:0] 	SPcod;

	logic [ 7:0] 	Ndecomp_cod;
	logic [ 7:0] 	CodeblockWidth_cod;
	logic [ 7:0] 	CodeblockHeight_cod;
	logic [ 7:0] 	CodeblockStyle_cod;
	logic [ 7:0] 	Tansform_cod;

} JpcCodHeader;

typedef struct packed {
    logic [ 15:0] 	QCD;
    logic [ 15:0] 	Lqcd;

	logic [  7:0]	Sqcd;
	logic [  7:0] 	SPqcd0;
	logic [  7:0] 	SPqcd1;
	logic [  7:0] 	SPqcd2;
	logic [  7:0] 	SPqcd3;
	logic [  7:0] 	SPqcd4;
	logic [  7:0] 	SPqcd5;
	logic [  7:0] 	SPqcd6;
	logic [  7:0] 	SPqcd7;
	logic [  7:0] 	SPqcd8;
	logic [  7:0] 	SPqcd9;
	logic [  7:0] 	SPqcd10;
	logic [  7:0] 	SPqcd11;
	logic [  7:0] 	SPqcd12;		// max decomp = 4 
	logic [  7:0] 	SPqcd13;		
	logic [  7:0] 	SPqcd14;		
	logic [  7:0] 	SPqcd15;		// max decomp = 5 

} JpcQcdHeader;

typedef struct packed {
    logic [ 15:0] 	SOT;
    logic [ 15:0] 	Lsot;

    logic [ 15:0] 	Isot;
    logic [ 31:0] 	Psot;		

	logic [  7:0]	TPsot;		// tile part index
	logic [  7:0]	TNsot;		// total number of tile part
} JpcSotHeader;


module header_gen(
	input					clk,
	input					rstn,
	input					go,
	input					eoc_go,

	input		[`W_PW:0]	pic_width,
	input		[`W_PH:0]	pic_height,

	input		[7:0]		ncomps,		
	input		[3:0]		ndecomp,

	output reg 	        	data_valid,
    output reg	[ 7:0]  	data_out,

	output				 	ready
	);
	

	JpcSizHeader siz_header;
	JpcCodHeader cod_header;
	JpcQcdHeader qcd_header;
	JpcSotHeader sot_header;

	assign	siz_header.SIZ = `SIZ_MARKER;
	assign	siz_header.Lsiz = 41; 	// for one component 
	assign	siz_header.Rsiz = 0;

	assign	siz_header.Xsiz = pic_width;
	assign	siz_header.Ysiz = pic_height;

	assign	siz_header.XOsiz = 0;
	assign	siz_header.YOsiz = 0;
	
	assign	siz_header.XTsiz = `TILE_WIDTH;		// tile size
	assign	siz_header.YTsiz = `TILE_WIDTH;

	assign	siz_header.XTOsiz = 0;
	assign	siz_header.YTOsiz = 0;

	assign	siz_header.Csiz = 1; 		// one component
	
	assign	siz_header.Ssiz0 = 7; 		// component depth minus 1 
	assign	siz_header.XRsiz0 = 1; 
	assign	siz_header.YRsiz0 = 1; 


	assign	cod_header.COD = `COD_MARKER; 
	assign	cod_header.Lcod = 12;   // 
	assign	cod_header.Scod = 8'h0; 	// Entropy coder, precincts with PPx = 15 and PPy = 15  only one precinct
	assign	cod_header.SGcod = 32'h00_0001_00; 		// progress order__ layer number __ RCT
	// assign	cod_header.SPcod = `COD_MARKER; 
	assign	cod_header.Ndecomp_cod	 		=  ndecomp;
	assign	cod_header.CodeblockWidth_cod 	= 8'd4;		 //64;   2^(n+2)
	assign	cod_header.CodeblockHeight_cod 	= 8'd4; 		//64;
	assign	cod_header.CodeblockStyle_cod 	= 8'h08;
	assign	cod_header.Tansform_cod 		= 8'd1;

	// qaunt 
	assign	qcd_header.QCD     = `QCD_MARKER; 
	assign	qcd_header.Lqcd    = 3 + 1 + 3*(ndecomp); 
	assign	qcd_header.Sqcd    = 8'h40; 		// NO quant   2 guard bits 
	assign	qcd_header.SPqcd0  = 8'd8  << 3 ; 
	assign	qcd_header.SPqcd1  = 8'd9  << 3 ;  
	assign	qcd_header.SPqcd2  = 8'd9  << 3 ;  
	assign	qcd_header.SPqcd3  = 8'd10 << 3 ;   
	assign	qcd_header.SPqcd4  = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd5  = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd6  = 8'd10 << 3 ;  
	assign	qcd_header.SPqcd7  = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd8  = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd9  = 8'd10 << 3 ;  
	assign	qcd_header.SPqcd10 = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd11 = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd12 = 8'd10 << 3 ;  
	assign	qcd_header.SPqcd13 = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd14 = 8'd9  << 3 ; 
	assign	qcd_header.SPqcd15 = 8'd10 << 3 ;  


	// tile header 
	wire	[31:0]	Psot = 0;

	assign	sot_header.SOT = `SOT_MARKER; 
	assign	sot_header.Lsot = 10; 
	assign	sot_header.Isot = 0; 
	assign	sot_header.Psot = Psot;  // tile len
	assign	sot_header.TPsot = 0;  // 
	assign	sot_header.TNsot = 1; 


	wire	[0:49-1][7:0]	siz_header_bytes = siz_header;
	wire	[0:14-1][7:0]	cod_header_bytes = cod_header;
	wire	[0:21-1][7:0]	qcd_header_bytes = qcd_header;
	wire	[0:12-1][7:0]	sot_header_bytes = sot_header;
	
	reg		[3:0]	st;
	reg		[5:0]	byte_cnt;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	st <= 0;
		else begin
			byte_cnt <= 0;
			data_valid <= 0;
            data_out <= 0;
			case(st)
			0:	if(go)
					st <= 1;
				else if (eoc_go)
					st <= 13;
			1:	begin		//SOC
					data_valid <= 1;
                    data_out <= 8'hFF;
					st <= st + 1;
				end
			2:	begin		//SOC
					data_valid <= 1;
                    data_out <= 8'h4f;
					st <= st + 1;
				end
			3:   begin		// SIZ
					data_valid <= 1;
                    data_out <= siz_header_bytes[byte_cnt];
					byte_cnt <= byte_cnt + 1;
					if (byte_cnt==(siz_header.Lsiz+2-1))
						st <= st + 1;
				end
			4:	begin
					st <= st + 1;
				end
			5:	begin		//COD
					data_valid <= 1;
                    data_out <= cod_header_bytes[byte_cnt];
					byte_cnt <= byte_cnt + 1;
					if (byte_cnt==(cod_header.Lcod+2-1))
						st <= st + 1;
				end
			6:	begin
					st <= st + 1;
				end
			7:	begin		//QCD
					data_valid <= 1;
                    data_out <= qcd_header_bytes[byte_cnt];
					byte_cnt <= byte_cnt + 1;
					if (byte_cnt== (qcd_header.Lqcd+2-1))
						st <= st + 1;
				end

			8:	begin
					// st <= st + 1;
					st <= 15;   // skip SOT  and SOD
				end
			9:	begin		//SOT
					data_valid <= 1;
                    data_out <= sot_header_bytes[byte_cnt];
					byte_cnt <= byte_cnt + 1;
					if (byte_cnt== (sot_header.Lsot+2-1))
						st <= st + 1;
				end
			
			10:	begin		//
					
					st <= st + 1;
				end
			11:	begin		// SOD
					data_valid <= 1;
                    data_out <= 8'hFF;
					st <= st + 1;
				end
			12:	begin		
					data_valid <= 1;
                    data_out <= 8'h93;
					st <= 15;
				end
			13:	begin					// EOC
					data_valid <= 1;
                    data_out <= 8'hFF;
					st <= st + 1;
				end
			14:	begin		
					data_valid <= 1;
                    data_out <= 8'hD9;
					st <= st + 1;
				end
			15:	begin		
				st <= 0;
			end
			
			endcase

		end

	assign ready = st == 15;

endmodule
