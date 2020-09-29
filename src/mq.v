// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

module mq(
	input					clk,
	input					rstn,
	
	input					init_f,
	input					en,
	input	[1:0]			pass,
	input	[4:0]			CX,	//0~18
	input					D,
		
	input					flush_f,
	
	output reg				bytes_out_f,
	output reg				bytes_out_len,
	output reg	[15:0]		bytes_out,

	output					pp
	
	);
	
	parameter INT_INDEX_CX0    = 7'd6;	
	parameter INT_INDEX_CX1    = 7'd8;	
	parameter INT_INDEX_CX2_17 = 7'd0;	
	parameter INT_INDEX_CX18   = 7'd92;	
	
	parameter [19*7-1:0]	INT_INDEX_CX = { INT_INDEX_CX0, INT_INDEX_CX1, {16{INT_INDEX_CX2_17}}, INT_INDEX_CX18};
	reg		[0:18][6:0]	index_cx_sp;
	reg		[0:18][6:0]	index_cx_mrp;
	reg		[0:18][6:0]	index_cx_cp;
	reg		[0:2][0:18][6:0] index_cx_passes;		
	

	reg		[6:0]	index;
	always @(*) index = index_cx_passes[pass][CX];
	
	wire		[15:0]	Qe;		
	wire		[6:0]	NMPS;		
	wire		[6:0]	NLPS;
	
	wire				MPS = index[0];
	Qe_table Qe_table(
		.clk		(clk),
		.rstn		(rstn),
		.index		(index),
		.Qe		(Qe),		
		.NMPS		(NMPS),		
		.NLPS		(NLPS)

		);

	wire	D_is_MPS = D== MPS;


	reg		[15:0]	A;	// 16 bits	length
	// reg		[27:0]	C;  // 28 bits	 start
	
	// A - Qe  or Qe
	// then shift
	reg		[3:0]	A_sub_Qe_cnt;
	wire	[15:0]	A_sub_Qe = A - Qe;
	reg		[15:0]	A_sub_Qe_shift;	
	always @(*) 
		if (A_sub_Qe[15])		begin	A_sub_Qe_shift = A_sub_Qe;			A_sub_Qe_cnt <= 0; end 
		else if (A_sub_Qe[14])	begin	A_sub_Qe_shift = A_sub_Qe << 1;     A_sub_Qe_cnt <= 1; end 
		else if (A_sub_Qe[13])	begin	A_sub_Qe_shift = A_sub_Qe << 2;     A_sub_Qe_cnt <= 2; end 
		else if (A_sub_Qe[12])	begin	A_sub_Qe_shift = A_sub_Qe << 3;     A_sub_Qe_cnt <= 3; end 
		else					begin	A_sub_Qe_shift = A_sub_Qe << 4;     A_sub_Qe_cnt <= 4; end 
	reg		[3:0]	Qe_cnt;
	reg		[15:0]	Qe_shift;
	always @(*) 
		if 		(Qe[15])	begin	Qe_shift = Qe;			Qe_cnt <= 0;  end
		else if (Qe[14])	begin	Qe_shift = Qe << 1;     Qe_cnt <= 1;  end
		else if (Qe[13])	begin	Qe_shift = Qe << 2;     Qe_cnt <= 2;  end
		else if (Qe[12])	begin	Qe_shift = Qe << 3;     Qe_cnt <= 3;  end
		else if (Qe[11])	begin	Qe_shift = Qe << 4;     Qe_cnt <= 4;  end
		else if (Qe[10])	begin	Qe_shift = Qe << 5;     Qe_cnt <= 5;  end
		else if (Qe[ 9])	begin	Qe_shift = Qe << 6;     Qe_cnt <= 6;  end
		else if (Qe[ 8])	begin	Qe_shift = Qe << 7;     Qe_cnt <= 7;  end
		else if (Qe[ 7])	begin	Qe_shift = Qe << 8;     Qe_cnt <= 8;  end
		else if (Qe[ 6])	begin	Qe_shift = Qe << 9;     Qe_cnt <= 9;  end
		else if (Qe[ 5])	begin	Qe_shift = Qe << 10;    Qe_cnt <= 10; end
		else if (Qe[ 4])	begin	Qe_shift = Qe << 11;    Qe_cnt <= 11; end
		else if (Qe[ 3])	begin	Qe_shift = Qe << 12;    Qe_cnt <= 12; end
		else if (Qe[ 2])	begin	Qe_shift = Qe << 13;    Qe_cnt <= 13; end
		else if (Qe[ 1])	begin	Qe_shift = Qe << 14;    Qe_cnt <= 14; end
		else if (Qe[ 0])	begin	Qe_shift = Qe << 15;    Qe_cnt <= 15; end
		else				begin   Qe_shift = Qe;			Qe_cnt <= 0;  end
	reg		[3:0]	shift_cnt;
	// always @(`CLK_RST_EDGE)
		// if (`RST)							shift_cnt <= 0;
		// else if (en) 
			// if (D_is_MPS ^ MPS_switch_f) 	shift_cnt <= A_sub_Qe_cnt;
			// else 							shift_cnt <= Qe_cnt;
	wire	MPS_switch_f = A < Qe*2;
	wire	upper_range_sel = D_is_MPS ^ MPS_switch_f;
	
	wire	[6:0]	index_next = D_is_MPS? NMPS : NLPS;

	always @(*) shift_cnt = D_is_MPS ^ MPS_switch_f? A_sub_Qe_cnt : Qe_cnt;
	
	always @(`CLK_RST_EDGE)
		if (`RST)							A <= 16'h8000;
		else if (init_f)					A <= 16'h8000;
		else if (en) 
			if (D_is_MPS ^ MPS_switch_f) 	A <= A_sub_Qe_shift;
			else 							A <= Qe_shift;

	reg		[15:0]	C16;
	wire	[16:0]	C_plus_Qe = C16 + Qe;
	wire	[16:0]	C16_temp = (D_is_MPS ^ MPS_switch_f)? C_plus_Qe : C16;

	reg				carry_C16;
	always @(`CLK_RST_EDGE)
		if (`RST)		C16 <= 0;
		else if (init_f)C16 <= 0;
		else if (en) 	C16 <= C16_temp << shift_cnt;

	wire			renorm = D_is_MPS & A_sub_Qe < 16'h8000 || !D_is_MPS;
	wire			update_index_f = renorm;
	

	always @(`CLK_RST_EDGE)
		if (`RST)			index_cx_passes <= {3{INT_INDEX_CX}};
		else if (init_f)	index_cx_passes <= {3{INT_INDEX_CX}};
		else if (en & update_index_f) 	
					index_cx_passes[pass][CX] <= index_next;

	reg		[11:0]	C12;
	wire	[11:0]	C12_temp = C12 + C16_temp[16];

	reg		[7:0]	B;
	reg		[3:0]	CT;
	reg		[27:0]	C;

	wire	[16:0]	Temp = C[15:0] + A;  // Temp must > 0x08000
	wire			Temp_larger = Temp[16];   // Temp <= 0x0ffff    Temp > 0x0ffff
	wire	[27:0]	C_to_flush = Temp_larger? {C[27:16], 16'hffff} : {C[27:16], 16'h7fff};
	// reg		[27:0]	C_to_flush;
	// always @(`CLK_RST_EDGE)
		// if (`RST)					C_to_flush <= 0;
		// else if (Temp_larger) 		C_to_flush <= {C[27:16], 16'hffff};
		// else						C_to_flush <= {C[27:16], 16'hefff};	
	


	wire	[27:0]	C_temp = {C[27:16], 16'h0} + C16_temp;

	reg		[7:0]	byteout1;
	wire			byteout1_f = CT <= shift_cnt || flush_f;
	wire	[27:0]	C_temp_shit1 = ~flush_f? C_temp << CT : C_to_flush << CT;
	reg		[4:0]	CT1;
	reg		[7:0]	B1;
	reg		[27:0]	C1;
	
	always @(*) begin
		CT1 = 0;
		C1 = C_temp;
		B1 = B;
		if (byteout1_f) begin
			if (B==8'hFF) begin
				CT1 = 7;
				B1 = C_temp_shit1[20+:8];
				C1 = C_temp_shit1 & 28'hfffff;
			end else if (B==8'hFE && C_temp_shit1[27]) begin
				CT1 = 7;
				B1 = {1'b0, C_temp_shit1[20+:7]};
				C1 = C_temp_shit1 & 28'hfffff;
			end else begin
				B1 = C_temp_shit1[19+:8];
				CT1 = 8;
				C1 = C_temp_shit1 & 28'h7ffff;
			end
		end
	end

	always @(*)  begin
		byteout1 = B;
		if (byteout1_f) 
			if (B==8'hFF) 
				byteout1 = B;
			else if (C_temp_shit1[27])
				byteout1 = B + 1;
	end
		
	
	reg		[7:0]	byteout2;
	wire			byteout2_f = (CT+CT1) <= shift_cnt || flush_f;
	wire	[27:0]	C1_shit = C1 << CT1;
	reg		[4:0]	CT2;
	reg		[7:0]	B2;
	reg		[27:0]	C2;

	always @(*) begin
		CT2 = 0;
		C2 = C1;
		B2 = B1;
		if (byteout2_f) begin
			if (B1==8'hFF) begin
				CT2 = 7;
				B2 = C1_shit[20+:8];
				C2 = C1_shit & 28'hfffff;
			end else if (B1==8'hFE && C1_shit[27]) begin
				CT2 = 7;
				B2 = {1'b0, C1_shit[20+:7]};
				C2 = C1_shit & 28'hfffff;
			end else begin
				B2 = C1_shit[19+:8];
				CT2 = 8;
				C2 = C1_shit & 28'h7ffff;
			end
		end
	end
	always @(*)  begin
		byteout2 = B1;
		if (byteout2_f)
			if (B1==8'hFF) 
				byteout2 = B1;
			else if (C1_shit[27])
				byteout2 = B1 + 1;
	end

	always @(`CLK_RST_EDGE)
		if (`RST)			C <= 0;
		else if (init_f)	C <= 0;
		else if (en)
			if (byteout2_f)		C <= C2 << (shift_cnt -  (CT+CT1));
			else if (byteout1_f)C <= C2 << (shift_cnt -  CT);
			else				C <= C2 << shift_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)			CT <= 12;
		else if (init_f)	CT <= 12;
		else if (en) begin
			if (byteout1_f)
				CT <= (CT+CT1+CT2) - shift_cnt;
			else
				CT <= CT - shift_cnt;
		end

	always @(`CLK_RST_EDGE)
		if (`RST)				B <= 0;
		else if (init_f)		B <= 0;
		else if (en | flush_f)	B <= B2;


	`DELAY1(flush_f, 0)

	reg		first_outed;
	always @(`CLK_RST_EDGE)
		if (`RST)									first_outed <= 0;
		else if (init_f)							first_outed <= 0;
		else if (en&& (byteout1_f | byteout2_f)) 	first_outed <= 1;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	bytes_out_f <= 0;
		else 		bytes_out_f <= (en || flush_f) && (byteout1_f & first_outed | byteout2_f) || flush_f_d1 && B != 8'hff;
	always @(`CLK_RST_EDGE)
		if (`RST)					bytes_out <= 0;
		else if (flush_f_d1)		bytes_out <= {B, byteout2};
		else if ((en || flush_f) && (byteout1_f & first_outed | byteout2_f) )		bytes_out <= first_outed?  {byteout1, byteout2} : {byteout2, 8'h00}; 
	always @(`CLK_RST_EDGE)
		if (`RST)	bytes_out_len <= 0;
		else 		bytes_out_len <= byteout2_f?  first_outed : 0;
	
	
	
`ifdef SIMULATING
	reg		B_eq_ff, B_eq_fe;
	always @(`CLK_RST_EDGE)
		if (`RST)	{B_eq_ff, B_eq_ff} <= 0;
		else begin
			B_eq_ff <= B == 8'hff;
			B_eq_fe <= B == 8'hfe;
		end
	
`endif


endmodule


module Qe_table(
	input					clk,
	input					rstn,
	input			[6:0]	index,
	output reg		[15:0]	Qe,		
	output reg		[6:0]	NMPS,		
	output reg		[6:0]	NLPS
	);

	// always @(`CLK_EDGE)
	always @(*)
		case(index)
		default:begin        Qe=16'b0;   	NMPS=0; 	NLPS=0;  	end
			0:	begin        Qe=16'h5601;	NMPS=2; 	NLPS=3;  	end
			1:	begin        Qe=16'h5601;	NMPS=3; 	NLPS=2;  	end
			2:	begin        Qe=16'h3401;	NMPS=4; 	NLPS=12; 	end
			3:	begin        Qe=16'h3401;	NMPS=5; 	NLPS=13; 	end
			4:	begin        Qe=16'h1801;	NMPS=6; 	NLPS=18; 	end
			5:	begin        Qe=16'h1801;	NMPS=7; 	NLPS=19; 	end
			6:	begin        Qe=16'h0ac1;	NMPS=8; 	NLPS=24; 	end
			7:	begin        Qe=16'h0ac1;	NMPS=9; 	NLPS=25; 	end
			8:	begin        Qe=16'h0521;	NMPS=10;	NLPS=58; 	end
			9:	begin        Qe=16'h0521;	NMPS=11;	NLPS=59; 	end
			10:	begin        Qe=16'h0221;	NMPS=76;	NLPS=66; 	end
			11:	begin        Qe=16'h0221;	NMPS=77;	NLPS=67; 	end
			12:	begin        Qe=16'h5601;	NMPS=14;	NLPS=13; 	end
			13:	begin        Qe=16'h5601;	NMPS=15;	NLPS=12; 	end
			14:	begin        Qe=16'h5401;	NMPS=16;	NLPS=28; 	end
			15:	begin        Qe=16'h5401;	NMPS=17;	NLPS=29; 	end
			16:	begin        Qe=16'h4801;	NMPS=18;	NLPS=28; 	end
			17:	begin        Qe=16'h4801;	NMPS=19;	NLPS=29; 	end
			18:	begin        Qe=16'h3801;	NMPS=20;	NLPS=28; 	end
			19:	begin        Qe=16'h3801;	NMPS=21;	NLPS=29; 	end
			20:	begin        Qe=16'h3001;	NMPS=22;	NLPS=34; 	end
			21:	begin        Qe=16'h3001;	NMPS=23;	NLPS=35; 	end
			22:	begin        Qe=16'h2401;	NMPS=24;	NLPS=36; 	end
			23:	begin        Qe=16'h2401;	NMPS=25;	NLPS=37; 	end
			24:	begin        Qe=16'h1c01;	NMPS=26;	NLPS=40; 	end
			25:	begin        Qe=16'h1c01;	NMPS=27;	NLPS=41; 	end
			26:	begin        Qe=16'h1601;	NMPS=58;	NLPS=42; 	end
			27:	begin        Qe=16'h1601;	NMPS=59;	NLPS=43; 	end
			28:	begin        Qe=16'h5601;	NMPS=30;	NLPS=29; 	end
			29:	begin        Qe=16'h5601;	NMPS=31;	NLPS=28; 	end
			30:	begin        Qe=16'h5401;	NMPS=32;	NLPS=28; 	end
			31:	begin        Qe=16'h5401;	NMPS=33;	NLPS=29; 	end
			32:	begin        Qe=16'h5101;	NMPS=34;	NLPS=30; 	end
			33:	begin        Qe=16'h5101;	NMPS=35;	NLPS=31; 	end
			34:	begin        Qe=16'h4801;	NMPS=36;	NLPS=32; 	end
			35:	begin        Qe=16'h4801;	NMPS=37;	NLPS=33; 	end
			36:	begin        Qe=16'h3801;	NMPS=38;	NLPS=34; 	end
			37:	begin        Qe=16'h3801;	NMPS=39;	NLPS=35; 	end
			38:	begin        Qe=16'h3401;	NMPS=40;	NLPS=36; 	end
			39:	begin        Qe=16'h3401;	NMPS=41;	NLPS=37; 	end
			40:	begin        Qe=16'h3001;	NMPS=42;	NLPS=38; 	end
			41:	begin        Qe=16'h3001;	NMPS=43;	NLPS=39; 	end
			42:	begin        Qe=16'h2801;	NMPS=44;	NLPS=38; 	end
			43:	begin        Qe=16'h2801;	NMPS=45;	NLPS=39; 	end
			44:	begin        Qe=16'h2401;	NMPS=46;	NLPS=40; 	end
			45:	begin        Qe=16'h2401;	NMPS=47;	NLPS=41; 	end
			46:	begin        Qe=16'h2201;	NMPS=48;	NLPS=42; 	end
			47:	begin        Qe=16'h2201;	NMPS=49;	NLPS=43; 	end
			48:	begin        Qe=16'h1c01;	NMPS=50;	NLPS=44; 	end
			49:	begin        Qe=16'h1c01;	NMPS=51;	NLPS=45; 	end
			50:	begin        Qe=16'h1801;	NMPS=52;	NLPS=46; 	end
			51:	begin        Qe=16'h1801;	NMPS=53;	NLPS=47; 	end
			52:	begin        Qe=16'h1601;	NMPS=54;	NLPS=48; 	end
			53:	begin        Qe=16'h1601;	NMPS=55;	NLPS=49; 	end
			54:	begin        Qe=16'h1401;	NMPS=56;	NLPS=50; 	end
			55:	begin        Qe=16'h1401;	NMPS=57;	NLPS=51; 	end
			56:	begin        Qe=16'h1201;	NMPS=58;	NLPS=52; 	end
			57:	begin        Qe=16'h1201;	NMPS=59;	NLPS=53; 	end
			58:	begin        Qe=16'h1101;	NMPS=60;	NLPS=54; 	end
			59:	begin        Qe=16'h1101;	NMPS=61;	NLPS=55; 	end
			60:	begin        Qe=16'h0ac1;	NMPS=62;	NLPS=56; 	end
			61:	begin        Qe=16'h0ac1;	NMPS=63;	NLPS=57; 	end
			62:	begin        Qe=16'h09c1;	NMPS=64;	NLPS=58; 	end
			63:	begin        Qe=16'h09c1;	NMPS=65;	NLPS=59; 	end
			64:	begin        Qe=16'h08a1;	NMPS=66;	NLPS=60; 	end
			65:	begin        Qe=16'h08a1;	NMPS=67;	NLPS=61; 	end
			66:	begin        Qe=16'h0521;	NMPS=68;	NLPS=62; 	end
			67:	begin        Qe=16'h0521;	NMPS=69;	NLPS=63; 	end
			68:	begin        Qe=16'h0441;	NMPS=70;	NLPS=64; 	end
			69:	begin        Qe=16'h0441;	NMPS=71;	NLPS=65; 	end
			70:	begin        Qe=16'h02a1;	NMPS=72;	NLPS=66; 	end
			71:	begin        Qe=16'h02a1;	NMPS=73;	NLPS=67; 	end
			72:	begin        Qe=16'h0221;	NMPS=74;	NLPS=68; 	end
			73:	begin        Qe=16'h0221;	NMPS=75;	NLPS=69; 	end
			74:	begin        Qe=16'h0141;	NMPS=76;	NLPS=70; 	end
			75:	begin        Qe=16'h0141;	NMPS=77;	NLPS=71; 	end
			76:	begin        Qe=16'h0111;	NMPS=78;	NLPS=72; 	end
			77:	begin        Qe=16'h0111;	NMPS=79;	NLPS=73; 	end
			78:	begin        Qe=16'h0085;	NMPS=80;	NLPS=74; 	end
			79:	begin        Qe=16'h0085;	NMPS=81;	NLPS=75; 	end
			80:	begin        Qe=16'h0049;	NMPS=82;	NLPS=76; 	end
			81:	begin        Qe=16'h0049;	NMPS=83;	NLPS=77; 	end
			82:	begin        Qe=16'h0025;	NMPS=84;	NLPS=78; 	end
			83:	begin        Qe=16'h0025;	NMPS=85;	NLPS=79; 	end
			84:	begin        Qe=16'h0015;	NMPS=86;	NLPS=80; 	end
			85:	begin        Qe=16'h0015;	NMPS=87;	NLPS=81; 	end
			86:	begin        Qe=16'h0009;	NMPS=88;	NLPS=82; 	end
			87:	begin        Qe=16'h0009;	NMPS=89;	NLPS=83; 	end
			88:	begin        Qe=16'h0005;	NMPS=90;	NLPS=84; 	end
			89:	begin        Qe=16'h0005;	NMPS=91;	NLPS=85; 	end
			90:	begin        Qe=16'h0001;	NMPS=90;	NLPS=86; 	end
			91:	begin        Qe=16'h0001;	NMPS=91;	NLPS=87; 	end
			92:	begin        Qe=16'h5601;	NMPS=92;	NLPS=92; 	end
			93:	begin        Qe=16'h5601;	NMPS=93;	NLPS=93; 	end
		endcase
endmodule
