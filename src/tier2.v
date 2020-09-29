// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpc_global.v"

module tier2(
	input					clk,
	input					rstn,
	
	input					go,
	input		[15:0]		tile_cnt,
	input		[2:0]		ndecomp,

	input					main_header_done,

	output reg				t1_fifo_rd,
	input	[7:0]			t1_fifo_byte,

	input	[0:7][0:2][7:0]			pass_num_buf_i,
	input	[0:7][0:2][7:0]			zero_bitplanes_buf_i,
	input	[0:7][0:2][15:0]		codeword_len_buf_i,

	output reg 					byte_out_f,
	output reg	[7:0]			byte_out,

	output reg					ready,
	output					pp
	
	);
	
	
	parameter			LBLCOK_INIT = 3;

	reg						header_o_f;	
	reg		[31:0]			header_o_bits;
	reg		[7:0]			header_o_bits_len;

	reg		[0:7][0:2][7:0]			pass_num_buf;
	reg		[0:7][0:2][7:0]			zero_bitplanes_buf;
	reg		[0:7][0:2][15:0]		codeword_len_buf;

	reg		[0:7][7:0]		header_bytes;

	always @(`CLK_RST_EDGE)
		if (`RST)			pass_num_buf <= 0;
		else if (go) begin
			pass_num_buf <= pass_num_buf_i;
			zero_bitplanes_buf <= zero_bitplanes_buf_i;
			codeword_len_buf <= codeword_len_buf_i;
		end
	reg 	[3:0]   lvl_cnt;
	reg		[1:0]	band_cnt;

	wire	[7:0]			pass_num = pass_num_buf[lvl_cnt][band_cnt];
	wire	[7:0]			zero_bitplanes = zero_bitplanes_buf[lvl_cnt][band_cnt];
	wire	[15:0]			codeword_len = codeword_len_buf[lvl_cnt][band_cnt];
	
	reg		[15:0]			codeword_len_sum;
	
	wire		[4:0]	Lblock = LBLCOK_INIT;
	

	wire	[16+5-1:0]	pass_num_coded = encode_pass_num(pass_num);
	wire	[15:0]		pass_num_bits     = pass_num_coded[15:0];
	wire	[4:0]		pass_num_bits_len = pass_num_coded[16+5-1:16];

	wire	[4:0]		codeword_len_width = codeword_width(codeword_len);
	wire	[2:0]		log2pass_num = log2(pass_num);
	
	wire	[4:0]		Lblock_inc = codeword_len_width > (LBLCOK_INIT + log2pass_num)? 
										codeword_len_width - (LBLCOK_INIT + log2pass_num) : 0 ;

	reg		[7:0]		bits_cnt;
	reg		[3:0]		st;
	wire				packet_go = st==1;
	always @(`CLK_RST_EDGE)
		if (`RST)				bits_cnt <= 0;
		else if (packet_go)		bits_cnt <= 0;
		else if (header_o_f)	bits_cnt <= bits_cnt + header_o_bits_len;
	
	
	reg		[15:0]	t1_fifo_rd_cnt;
	wire	[1:0]	band_cnt_max =  lvl_cnt==0?  0 : 2;
	wire		packet_header_ready = st == 15;
	
	always @(`CLK_RST_EDGE)
		if (`RST) begin	st <= 0;
			header_o_f		 <= 0;
			header_o_bits	 <= 0;
			header_o_bits_len <= 0;
			// t1_fifo_rd <= 0;
			t1_fifo_rd_cnt <= 0; 
		end else begin
			header_o_f		 <= 0;
			header_o_bits	 <= 0;
			header_o_bits_len <= 0;
			// t1_fifo_rd <= 0;
			t1_fifo_rd_cnt <= 0; 

			case(st)
			0:	begin 	
					// codeword_len_sum <= 0;
					band_cnt <= 0;
					lvl_cnt <= 0;
					if (go) begin
						st <= 1;
						codeword_len_sum <= 0;
					end
				end
			1:	begin  // Zero length packet 
					header_o_f 		  <= 1;
					header_o_bits_len <= 1;
					header_o_bits	  <= 1; 
					st <= 2; 
				end
			2: 	begin  // Code-block inclusion always 0 layer    tag tree
					header_o_f 		  <= 1;
					header_o_bits_len <= 1;
					header_o_bits	  <= pass_num==0? 0:1; 
					st <= pass_num==0? 7: 3;
				end
			3:	begin  // zero plane tagtree    // n 0 + 1bit1    tag tree
					header_o_f 		  <= 1;
					header_o_bits_len <= zero_bitplanes+1; 
					header_o_bits	  <= 1; 
					st <= 4;
				end
			4:	begin  // Number of coding passes
					header_o_f 		  <= 1;
					header_o_bits_len <= pass_num_bits_len; 
					header_o_bits	  <= pass_num_bits; 
					st <= 5;
				end
			5:	begin	// LBlock		
					header_o_f 		  <= 1;
					header_o_bits_len <= Lblock_inc + 1; 
					// header_o_bits	  <= Lblock_inc ==0? 0 : {{Lblock_inc{1'b1}} , 1'b0}; 
					header_o_bits	  <= Lblock_inc ==0? 0 :  ( 1 << (Lblock_inc+1)) - 2 ; 
					st <= 6;
				end
			6:	begin
					header_o_f 		  <= 1;
					header_o_bits_len <= Lblock_inc + (LBLCOK_INIT + log2pass_num); 
					header_o_bits	  <= codeword_len; 
					codeword_len_sum <= codeword_len_sum + codeword_len;
					st <= 7;
				end
			7:	begin
					if (band_cnt == band_cnt_max) begin
						st <= 8;
						band_cnt <= 0; 
					end else begin
						band_cnt <= band_cnt + 1; 
						st <= 2;
					end
				end
			8:	begin
					header_o_f 		  <= bits_cnt[2:0] !=0;
					header_o_bits_len <= bits_cnt[2:0] !=0?  8- bits_cnt[2:0] : 0; 
					header_o_bits	  <= 0;
					// if (codeword_len_sum != 0) 
						st <= 9;
					// else
						// st <= 11;
					header_bytes[lvl_cnt] <= bits_cnt[2:0] == 0 ?  bits_cnt >> 3 : (bits_cnt >> 3) + 1;
					codeword_len_sum <= codeword_len_sum + (bits_cnt[2:0] == 0 ?  bits_cnt >> 3 : (bits_cnt >> 3) + 1) ;
				end
			9:	begin
					lvl_cnt <= lvl_cnt + 1;
					if (lvl_cnt == ndecomp)
						st <= 10;
					else
						st <= 1;
				end

			10:	begin
					// t1_fifo_rd <= 1;
					// t1_fifo_rd_cnt <= t1_fifo_rd_cnt + 1; 
					// if (t1_fifo_rd_cnt==codeword_len_sum-1)
						st <= 11;
				end
			11:	begin
					st <= 15;
				end
			15:	begin
					st <= 0;
				end
			endcase
		end

	
	reg		[127:0]	bs_fifo;
	always @(`CLK_RST_EDGE)
		if (`RST)				bs_fifo <= 0;
		else if (header_o_f)  	bs_fifo <= ( bs_fifo << header_o_bits_len) | header_o_bits;
	
	reg		[5:0]	bs_fifo_bits_cnt;
	wire	[5:0]	_bs_fifo_bits_cnt = bs_fifo_bits_cnt + (header_o_f? header_o_bits_len : 0);
	always @(`CLK_RST_EDGE)
		if (`RST)				bs_fifo_bits_cnt <= 0;
		else 					bs_fifo_bits_cnt <= _bs_fifo_bits_cnt >= 8 ? _bs_fifo_bits_cnt - 8 :  _bs_fifo_bits_cnt;
	
	reg				header_byte_f;
	reg		[7:0]	header_byte;
	always @(`CLK_RST_EDGE)
		if (`RST)	header_byte_f <= 0;
		else 		header_byte_f <= _bs_fifo_bits_cnt >= 8;
	
	always @(*) header_byte = bs_fifo >> bs_fifo_bits_cnt;
		
	reg				header_fifo_rd;
	wire [7:0]		header_fifo_byte;
	fifo_sync #(
		.DW		(8),
		.DEPTH	(128)
		) packet_header_fifo(
		.clk		(clk),
		.rstn		(rstn),
		
		.din		(header_byte),
		.wr_en		(header_byte_f),

		.rd_en		(header_fifo_rd),
		.dout		(header_fifo_byte),

		.full		(header_fifo_full),
		.empty		(header_fifo_empty)
		);
	
	reg				tier1_byte_f;
	reg		[7:0]	tier1_byte;
	always @(`CLK_RST_EDGE)
		if (`RST)	tier1_byte_f <= 0;
		else 		tier1_byte_f <= t1_fifo_rd;
	always @(*) tier1_byte = t1_fifo_byte;

	reg				header_fifo_byte_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	header_fifo_byte_f <= 0;
		else 		header_fifo_byte_f <= header_fifo_rd;

	reg		[7:0]	st_out;
	reg 	[3:0]   lvl_cnt_out;
	reg		[1:0]	band_cnt_out;
	reg		[15:0]	byte_cnt;

	wire	[1:0]	band_cnt_out_max =  lvl_cnt_out==0?  0 : 2;
	wire	[15:0]	codeword_len_out = codeword_len_buf[lvl_cnt_out][band_cnt_out];

	// wire	[15:0]	tile_idx = 0;
	wire	[15:0]	tile_part_len = 0;
	
	JpcSotHeader sot_header;
	wire	[0:12-1][7:0]	sot_header_bytes = sot_header;
	assign	sot_header.SOT  =  16'hff90; 
	assign	sot_header.Lsot = 10; 
	assign	sot_header.Isot = tile_cnt; 
	assign	sot_header.Psot = codeword_len_sum + 14;  // tile len
	assign	sot_header.TPsot = 0;  // 
	assign	sot_header.TNsot = 1; 
	
	wire	[15:0]	SOD = 16'hff93; 

	wire	[0: 12+2-1][7:0]	sot_sod_bytes = {sot_header, SOD};

	reg				sot_header_rd;
	reg				sot_byte_f;
	reg		[7:0]	sot_byte;
	
	always @(*) sot_byte_f = sot_header_rd;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	sot_byte <= 0;
		else  		sot_byte <= sot_sod_bytes[byte_cnt];

	reg		packet_header_done;
	wire	st_ouot_go = packet_header_done & main_header_done;
	always @(`CLK_RST_EDGE)
		if (`RST)	packet_header_done <= 0;
		else if (packet_header_ready) 		packet_header_done <= 1;
		else if (st_ouot_go)				packet_header_done <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	st_out <= 0;
		else begin
			header_fifo_rd <= 0;
			t1_fifo_rd <= 0;
			byte_cnt <= 0;
			sot_header_rd <= 0;
			case(st_out)
			0:	begin
					band_cnt_out <= 0;
					lvl_cnt_out <= 0;
					byte_cnt <= 0;
					if (st_ouot_go)
						st_out <= 8;
				end
			8:  begin// read SOT SOD header 
					sot_header_rd <= 1;
					byte_cnt <= byte_cnt + 1;
					if (byte_cnt == 12+2-1)
						st_out <= 9;
				end
			9:	begin
					st_out <= 1;
				end
			1:	begin	// read packet_header 
					header_fifo_rd <= 1;
					byte_cnt <= byte_cnt + 1;
					if ( byte_cnt == header_bytes[lvl_cnt_out]-1)
						st_out <= 2;
				end 
			2: begin
					byte_cnt <= 0;
					if (codeword_len_out !=0 )
						st_out <= 3;
					else 
						st_out <= 4;
			   end
			3: begin	// read t1 fifo
					t1_fifo_rd <= 1;
					byte_cnt <= byte_cnt + 1;
					if ( byte_cnt == codeword_len_out-1)
						st_out <= 4;
			   end 
			4: begin
					if (band_cnt_out == band_cnt_out_max) begin
						st_out <= 5;
						band_cnt_out <= 0; 
					end else begin
						band_cnt_out <= band_cnt_out + 1; 
						st_out <= 3;
					end
				end
			5: begin
					lvl_cnt_out <= lvl_cnt_out + 1;
					band_cnt_out <= 0; 
					if (lvl_cnt_out == ndecomp)
						st_out <= 7;
					else
						st_out <= 1;
			   end 
			7: begin
					st_out <= 0;
			   end
			endcase
		end 

	always @(`CLK_RST_EDGE)
		if (`RST)	ready <= 0;
		else 		ready <= st_out == 7;

	always @(`CLK_RST_EDGE)
		if (`RST)	byte_out_f <= 0;
		else 		byte_out_f <= sot_byte_f | header_fifo_byte_f | tier1_byte_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	byte_out <= 0;
		else 		byte_out <= tier1_byte_f? tier1_byte : ( sot_byte_f? sot_byte :  header_fifo_byte );
	
	
	function	[4:0]	codeword_width(
		input	[15:0]	codeword_len
		);

		begin
			     if (codeword_len[15])	codeword_width = 16;
			else if (codeword_len[14])	codeword_width = 15;
			else if (codeword_len[13])	codeword_width = 14;
			else if (codeword_len[12])	codeword_width = 13;
			else if (codeword_len[11])	codeword_width = 12;
			else if (codeword_len[10])	codeword_width = 11;
			else if (codeword_len[ 9])	codeword_width = 10;
			else if (codeword_len[ 8])	codeword_width =  9;
			else if (codeword_len[ 7])	codeword_width =  8;
			else if (codeword_len[ 6])	codeword_width =  7;
			else if (codeword_len[ 5])	codeword_width =  6;
			else if (codeword_len[ 4])	codeword_width =  5;
			else if (codeword_len[ 3])	codeword_width =  4;
			else if (codeword_len[ 2])	codeword_width =  3;
			else if (codeword_len[ 1])	codeword_width =  2;
			// else if (codeword_len[ 0])	codeword_width = 16;
			else 						codeword_width = 1;
			return codeword_width;
		end
		

	endfunction
	
	function	[2:0]	log2(
		input	[7:0]	n
		);
		
		begin
			if (n >= 128) 
				log2 = 7;
			else if (n >= 64) 
				log2 = 6;
			else if (n>=32)
				log2 = 5;
			else if (n>=16)
				log2 = 4;
			else if (n>=8)
				log2 = 3;
			else if (n>=4)
				log2 = 2;
			else if (n>=2)
				log2 = 1;
			else 
				log2 = 0;
			
			return log2;
		end
	endfunction
	function	[16+5-1:0]	encode_pass_num(
		input	[7:0]	n
		);
		reg		[15:0]	d;
		reg		[4:0]	len;
		begin
			if (n == 1) begin
				d = 0;
				len = 1;
			end else if (n==2) begin
				d = 16'b10;
				len = 2;
			end else if (n <= 5) begin
				d = 4'b1100 | (n - 3);
				len = 4;
			end else if (n <= 36) begin
				d = 9'b1111_00000 | (n - 6);
				len = 9;
			// end else if (n <= 164) begin
			end else begin
				d = 16'b1111_1111_1_0000_000 | (n - 37);
				len = 16;
			end
			encode_pass_num = {len, d};
			return encode_pass_num;
		end
	endfunction 
endmodule
