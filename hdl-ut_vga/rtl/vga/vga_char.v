/**
 *  EK-Miniterm - VGA Unit Test - Character generator module
 *
 * Copyright (C) 2014 Saint-Genest Gwenael <gwen@agilack.fr>
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
 * USA.
 */
`timescale 1ns / 1ps
module vga_char (
	input        clk_i, 
	// pseudo-wishbone signals
	input        wb_clk, 
	input        wb_cyc_i,
	input        wb_we_i, 
	input  [2:0] wb_addr_i,
	input  [7:0] wb_dati, 
	// character io interface
	input  [9:0] current_x_i, 
	input  [9:0] current_y_i, 
	output       active_o, 
	output [2:0] color_o 
);

wire [ 7:0] charcode, ccode_main, ccode_splash;
reg  [ 7:0] cur_char;
reg act = 1'b0;

reg ccode_sel = 1'b1;

assign color_o[0] = cur_char[7];
assign color_o[1] = cur_char[7];
assign color_o[2] = cur_char[7];
assign active_o   = act;

reg [6:0] cursor_x = 7'd0;
reg [4:0] cursor_y = 5'd0;
wire wb_wrb = (wb_cyc_i && wb_we_i && (wb_addr_i[2:0] == 3'b000));

/**
 * Handle pseudo-Wishbone requests
 *
 */
always @(posedge wb_clk)
begin
	if (wb_cyc_i) begin
		if (wb_we_i) begin
			if (wb_addr_i == 3'b000) begin
				if (wb_dati[7:0] == 8'h0D)
					cursor_x <= 7'd0;
				else if (wb_dati[7:0] == 8'h0A)
					cursor_y <= cursor_y + 5'd1;
				else if (cursor_x < 10'd64)
					cursor_x <= cursor_x + 7'd1;
				else begin
					cursor_x <= 7'd0;
					cursor_y <= cursor_y + 5'd1;
				end
			end
			if (wb_addr_i == 3'b001)
				cursor_x[6:0] <= wb_dati[6:0];
			if (wb_addr_i == 3'b011)
				cursor_y[4:0] <= wb_dati[4:0];
			if (wb_addr_i == 3'b110)
				ccode_sel <= wb_dati[0];
		end
	end // wb_cyc
end

/**
 * Convert pixels X-Y into char X-Y (divide by 8)
 *
 */
wire [6:0] char_y;
assign     char_y = current_y_i[9:3];
wire [6:0] char_x;
assign     char_x = current_x_i[9:3];

always @(posedge clk_i)
begin
	if ( (char_x < 64) &&
		  (char_y < 32)   )
		act <= 1'b1;
	else
		act <= 1'b0;
end

// ----------------------------------------------------------------------------
// --                            Character memory                            --
// ----------------------------------------------------------------------------
wire [10:0] ram_addr;
wire [10:0] wb_ramadr;
reg  [ 5:0] char_x_ram;
wire [ 7:0] ram_o;

assign ram_addr  = {   char_y[4:0], char_x_ram[5:0] };
assign wb_ramadr = { cursor_y[4:0],   cursor_x[5:0] };

/**
 * Sync memory access to pixels position
 */
always @(negedge clk_i)
begin
	if (current_x_i[2:0] == 3'b000)
		char_x_ram <= char_x;
	if (current_x_i[2:0] == 3'b100)
		char_x_ram <= char_x + 1;

	if (current_x_i[2:0] == 3'b000)
		cur_char <= ram_o;
	else
		cur_char[7:0] <= {cur_char[6:0], 1'b0};
end

RAMB16_S9_S9 #(
	.INIT_00 ( { 128'h00, 128'h00 } ),
	.INIT_06 ( { 128'h0,       8'h21, 8'h20, 8'h64,
	             8'h6C, 8'h72, 8'h6F, 8'h77, 8'h20,
	             8'h6F, 8'h6C, 8'h6C, 8'h65, 8'h48, 24'h00} )
  ) u_chars_txt_ram (
	// Port A : video access
	.ADDRA ( ram_addr ),
	.CLKA  ( ~clk_i   ),
	.DIA   ( 8'h00    ),
	.DIPA  ( 1'b0     ),
	.DOA   ( ccode_main ),
	.DOPA  (          ),
	.ENA   ( 1'b1     ),
	.WEA   ( 1'b0     ),
	.SSRA  ( 1'b0     ),
	// Port B : wishbone access
	.ADDRB ( wb_ramadr    ),
	.CLKB  ( wb_clk       ),
	.DIB   ( wb_dati[7:0] ),
	.DIPB  ( 1'b0         ),
	.DOB   (              ),
	.DOPB  (              ),
	.ENB   ( wb_wrb       ),
	.WEB   ( wb_wrb       ),
	.SSRB  ( 1'b0         )
);

// _______  _        _______  _       _________ _______  _______ 
//(  ____ \( \      (  ____ \| \    /\\__   __/(  ___  )(  ____ )
//| (    \/| (      | (    \/|  \  / /   ) (   | (   ) || (    )|
//| (__    | |      | (__    |  (_/ /    | |   | |   | || (____)|
//|  __)   | |      |  __)   |   _ (     | |   | |   | ||     __)
//| (      | |      | (      |  ( \ \    | |   | |   | || (\ (   
//| (____/\| (____/\| (____/\|  /  \ \   | |   | (___) || ) \ \__
//(_______/(_______/(_______/|_/    \/   )_(   (_______)|/   \__/
                                                               

RAMB16_S9_S9 #(
	.INIT_04 ( { 128'h20_20_20_5F_20_20_5F_5F_5F_5F_5F_5F_5F_20_20_20, 
					 128'h20_20_20_20_20_5F_20_20_5F_5F_5F_5F_5F_5F_5F_20} ),
	.INIT_05 ( { 128'h00_20_5F_5F_5F_5F_5F_5F_5F_20_20_5F_5F_5F_5F_5F, 
					 128'h5F_5F_20_5F_5F_5F_5F_5F_5F_5F_5F_5F_20_20_20_20} ),
	.INIT_06 ( { 128'h20_20_5C_20_7C_5C_20_5F_5F_5F_5F_20_20_28_20_20,
					 128'h20_20_20_20_5C_20_28_5C_20_5F_5F_5F_5F_20_20_28} ),
	.INIT_07 ( { 128'h00_29_20_5F_5F_5F_5F_20_20_28_29_20_20_5F_5F_5F,
					 128'h20_20_28_2F_5F_5F_20_20_20_5F_5F_5C_5C_2F_20_20} ),
	.INIT_08 ( { 128'h20_5C_20_20_7C_2F_5C_20_20_20_20_28_20_7C_20_20,
					 128'h20_20_20_20_28_20_7C_2F_5C_20_20_20_20_28_20_7C} ),
	.INIT_09 ( { 128'h00_7C_29_20_20_20_20_28_20_7C_7C_20_29_20_20_20,
					 128'h28_20_7C_20_20_20_28_20_29_20_20_20_2F_20_2F_20} ),
	.INIT_0A ( { 128'h5F_28_20_20_7C_20_20_20_20_5F_5F_28_20_7C_20_20,
					 128'h20_20_20_20_7C_20_7C_20_20_20_20_5F_5F_28_20_7C} ),
	.INIT_0B ( { 128'h00_7C_29_5F_5F_5F_5F_28_20_7C_7C_20_7C_20_20_20,
					 128'h7C_20_7C_20_20_20_7C_20_7C_20_20_20_20_2F_20_2F} ),
	.INIT_0C ( { 128'h5F_20_20_20_7C_20_20_20_29_5F_5F_20_20_7C_20_20,
					 128'h20_20_20_20_7C_20_7C_20_20_20_29_5F_5F_20_20_7C} ),
	.INIT_0D ( { 128'h00_29_5F_5F_20_20_20_20_20_7C_7C_20_7C_20_20_20,
					 128'h7C_20_7C_20_20_20_7C_20_7C_20_20_20_20_20_28_20} ),
	.INIT_0E ( { 128'h20_28_20_20_7C_20_20_20_20_20_20_28_20_7C_20_20,
					 128'h20_20_20_20_7C_20_7C_20_20_20_20_20_20_28_20_7C} ),
	.INIT_0F ( { 128'h00_20_20_20_28_20_5C_28_20_7C_7C_20_7C_20_20_20,
					 128'h7C_20_7C_20_20_20_7C_20_7C_20_20_20_20_5C_20_5C} ),
	.INIT_10 ( { 128'h20_2F_20_20_7C_5C_2F_5F_5F_5F_5F_28_20_7C_5C_2F,
					 128'h5F_5F_5F_5F_28_20_7C_5C_2F_5F_5F_5F_5F_28_20_7C} ),
	.INIT_11 ( { 128'h00_5F_5F_5C_20_5C_20_29_20_7C_7C_20_29_5F_5F_5F,
					 128'h28_20_7C_20_20_20_7C_20_7C_20_20_20_5C_20_5C_20} ),
	.INIT_12 ( { 128'h20_20_2F_5F_7C_2F_5F_5F_5F_5F_5F_5F_5F_28_2F_5F,
					 128'h5F_5F_5F_5F_5F_5F_28_2F_5F_5F_5F_5F_5F_5F_5F_28} ),
	.INIT_13 ( { 128'h00_2F_5F_5F_5C_20_20_20_2F_7C_29_5F_5F_5F_5F_5F,
					 128'h5F_5F_28_20_20_20_28_5F_29_20_20_20_2F_5C_20_20} ),
					 //
	.INIT_18 ( { 128'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00,
	             128'h00_00_00_00_00_00_00_00_00_00_00_00_56_00_00_00} ),
					 //
	.INIT_3F ( { 8'h00, 8'h00, 8'h00, 8'h00,  8'h00, 8'h00, 8'h00, 8'h00,
	             8'h00, 8'h00, 8'h00, 8'h00,  8'h00, 8'h00, 8'h00, 8'h00,
					 8'h00, 8'h00, 8'h00, 8'h00,  8'h00, 8'h00, 8'h00, 8'h00,
					 8'h00, 8'h00, 8'h00, 8'h00,  8'h00, 8'h00, 8'h00, 8'h00} )
  ) u_chars_splash_ram (
	// Port A : video access
	.ADDRA ( ram_addr ),
	.CLKA  ( ~clk_i   ),
	.DIA   ( 8'h00    ),
	.DIPA  ( 1'b0     ),
	.DOA   ( ccode_splash ),
	.DOPA  (          ),
	.ENA   ( 1'b1     ),
	.WEA   ( 1'b0     ),
	.SSRA  ( 1'b0     ),
	// Port B : wishbone access
	.ADDRB ( wb_ramadr    ),
	.CLKB  ( wb_clk       ),
	.DIB   ( wb_dati[7:0] ),
	.DIPB  ( 1'b0         ),
	.DOB   (              ),
	.DOPB  (              ),
	.ENB   ( wb_wrb       ),
	.WEB   ( wb_wrb       ),
	.SSRB  ( 1'b0         )
);

assign charcode[7:0] = ccode_sel ? ccode_splash : ccode_main;

// ----------------------------------------------------------------------------
// --                        Charset bitmap converter                        --
// ----------------------------------------------------------------------------
wire [10:0] charmap_addr = { charcode[7:0], current_y_i[2:0] };

parameter C0____ = 64'h00000000_00000000;
parameter C0_L01 = 64'h55AA55AA_55AA55AA;
parameter C0_L20 = 64'h00000000_00000000; // <space>
parameter C0_L21 = 64'h00080008_08080808; // !
parameter C0_L22 = 64'h00000000_00001414; // "
parameter C0_L23 = 64'h0014147F_147F1414; // #
parameter C0_L24 = 64'h00083C0A_1C281E08; // $
parameter C0_L25 = 64'h00002616_08343200; // %
parameter C0_L26 = 64'h003A4446_28102818; // &
parameter C0_L27 = 64'h00000000_00000808; // '
parameter C0_L28 = 64'h00040810_10100804; // (
parameter C0_L29 = 64'h00100804_04040810; // )
parameter C0_L2A = 64'h0008492A_1C2A4908; // '
parameter C0_L2B = 64'h00080808_7F080808; // +
parameter C0_L2C = 64'h08040C0C_00000000; // ,
parameter C0_L2D = 64'h00000000_7F000000; // -
parameter C0_L2E = 64'h000C0C00_00000000; // .
parameter C0_L2F = 64'h00402010_08040201; // /
parameter C0_L30 = 64'h00182424_24241800; // 0
parameter C0_L31 = 64'h001C0808_08081800; // 1
parameter C0_L32 = 64'h003C1008_04043800; // 2
parameter C0_L33 = 64'h001C2202_0C02221C; // 3
parameter C0_L34 = 64'h000E0404_3E24140C; // 4
parameter C0_L35 = 64'h001C2202_3C20203E; // 5
parameter C0_L36 = 64'h001C2222_3C20221C; // 6
parameter C0_L37 = 64'h00101010_0804023E; // 7
parameter C0_L38 = 64'h001C2222_1C22221C; // 8
parameter C0_L39 = 64'h001C2202_1E22221C; // 9
parameter C0_L3A = 64'h00000C0C_000C0C00; // :
parameter C0_L3B = 64'h08040C0C_000C0C00; // ;
parameter C0_L3C = 64'h00040810_20100804; // <
parameter C0_L3D = 64'h0000007F_007F0000; // =
parameter C0_L3E = 64'h00201008_04081020; // >
parameter C0_L3F = 64'h00080008_0402221C; // ?
parameter C0_L40 = 64'h001C202E_2A2E221C; // @
parameter C0_L41 = 64'h00222222_3E22221C; // A
parameter C0_L42 = 64'h003C2222_3C22223C; // B
parameter C0_L43 = 64'h001C2220_2020221C; // C
parameter C0_L44 = 64'h003C2222_2222223C; // D
parameter C0_L45 = 64'h003E2020_3C20203E; // E
parameter C0_L46 = 64'h00202020_3E20203E; // F
parameter C0_L47 = 64'h001C2222_2E20221C; // G
parameter C0_L48 = 64'h00222222_3E222222; // H
parameter C0_L49 = 64'h001C0808_0808081C; // I
parameter C0_L4A = 64'h00182424_0404040E; // J
parameter C0_L4B = 64'h00222224_38242222; // K
parameter C0_L4C = 64'h001E1010_10101010; // L
parameter C0_L4D = 64'h00414141_49556341; // M
parameter C0_L4E = 64'h00222226_2A2A3222; // N
parameter C0_L4F = 64'h001C2222_2222221C; // O
parameter C0_L50 = 64'h00101010_1C12121C; // P
parameter C0_L51 = 64'h061C2222_2222221C; // Q
parameter C0_L52 = 64'h00222428_3C22223C; // R
parameter C0_L53 = 64'h001C2202_1C20221C; // S
parameter C0_L54 = 64'h00080808_0808083E; // T
parameter C0_L55 = 64'h001C2222_22222222; // U
parameter C0_L56 = 64'h00080814_14222222; // V
parameter C0_L57 = 64'h0014142A_2A414141; // W
parameter C0_L58 = 64'h00222214_08142222; // X
parameter C0_L59 = 64'h00080808_08142222; // Y
parameter C0_L5A = 64'h003E2010_0804023E; // Z
parameter C0_L5B = 64'h001C1010_1010101C; // [
parameter C0_L5C = 64'h00010204_08102040; // \
parameter C0_L5D = 64'h001C0404_0404041C; // ]
parameter C0_L5E = 64'h00000000_00221408; // ^
parameter C0_L5F = 64'h7F000000_00000000; // _
parameter C0_L60 = 64'h00000000_00000810; // `
parameter C0_L61 = 64'h001D2222_1E021C00; // a
parameter C0_L62 = 64'h002C1212_121C1010; // b
parameter C0_L63 = 64'h001C2020_201C0000; // c
parameter C0_L64 = 64'h000D1212_120E0202; // d
parameter C0_L65 = 64'h001C203E_221C0000; // e
parameter C0_L66 = 64'h00101010_3810120C; // f
parameter C0_L67 = 64'h1C021E22_221D0000; // g
parameter C0_L68 = 64'h00222222_322C2020; // h
parameter C0_L69 = 64'h00080808_08000800; // i
parameter C0_L6A = 64'h30080808_08000800; // j
parameter C0_L6B = 64'h00242830_28242020; // k
parameter C0_L6C = 64'h00080808_08080818; // l
parameter C0_L6D = 64'h00414149_49B60000; // m
parameter C0_L6E = 64'h00121212_122C0000; // n
parameter C0_L6F = 64'h001C2222_221C0000; // o
parameter C0_L70 = 64'h10101C12_122C0000; // p
parameter C0_L71 = 64'h04041C24_241A0000; // q
parameter C0_L72 = 64'h00202020_302C0000; // r
parameter C0_L73 = 64'h00380418_201C0000; // s
parameter C0_L74 = 64'h00080808_081C0800; // t
parameter C0_L75 = 64'h001A2424_24240000; // u
parameter C0_L76 = 64'h00081422_22222200; // v
parameter C0_L77 = 64'h00225549_41410000; // w
parameter C0_L78 = 64'h00221408_14220000; // x
parameter C0_L79 = 64'h1C020E12_12120000; // y
parameter C0_L7A = 64'h003C1008_043C0000; // z
parameter C0_L7B = 64'h000C1010_2010100C; // {
parameter C0_L7C = 64'h00080808_08080808; // |
parameter C0_L7D = 64'h00300808_04080830; // }
parameter C0_L7E = 64'h00000006_49300000; // ~

RAMB16_S9 #(
	.INIT_00 ( {C0____, C0____, C0____, C0____} ),
	.INIT_01 ( {C0____, C0____, C0____, C0____} ),
	.INIT_02 ( {C0____, C0____, C0____, C0____} ),
	.INIT_03 ( {C0____, C0____, C0____, C0____} ),
	.INIT_04 ( {C0____, C0____, C0____, C0____} ),
	.INIT_05 ( {C0____, C0____, C0____, C0____} ),
	.INIT_06 ( {C0____, C0____, C0____, C0____} ),
	.INIT_07 ( {C0____, C0____, C0____, C0____} ),
	.INIT_08 ( {C0_L23, C0_L22, C0_L21, C0_L20} ),
	.INIT_09 ( {C0_L27, C0_L26, C0_L25, C0_L24} ),
	.INIT_0A ( {C0_L2B, C0_L2A, C0_L29, C0_L28} ),
	.INIT_0B ( {C0_L2F, C0_L2E, C0_L2D, C0_L2C} ),
	.INIT_0C ( {C0_L33, C0_L32, C0_L31, C0_L30} ),
	.INIT_0D ( {C0_L37, C0_L36, C0_L35, C0_L34} ),
	.INIT_0E ( {C0_L3B, C0_L3A, C0_L39, C0_L38} ),
	.INIT_0F ( {C0_L3F, C0_L3E, C0_L3D, C0_L3C} ),
	.INIT_10 ( {C0_L43, C0_L42, C0_L41, C0_L40} ),
	.INIT_11 ( {C0_L47, C0_L46, C0_L45, C0_L44} ),
	.INIT_12 ( {C0_L4B, C0_L4A, C0_L49, C0_L48} ),
	.INIT_13 ( {C0_L4F, C0_L4E, C0_L4D, C0_L4C} ),
	.INIT_14 ( {C0_L53, C0_L52, C0_L51, C0_L50} ),
	.INIT_15 ( {C0_L57, C0_L56, C0_L55, C0_L54} ),
	.INIT_16 ( {C0_L5B, C0_L5A, C0_L59, C0_L58} ),
	.INIT_17 ( {C0_L5F, C0_L5E, C0_L5D, C0_L5C} ),
	.INIT_18 ( {C0_L63, C0_L62, C0_L61, C0_L60} ),
	.INIT_19 ( {C0_L67, C0_L66, C0_L65, C0_L64} ),
	.INIT_1A ( {C0_L6B, C0_L6A, C0_L69, C0_L68} ),
	.INIT_1B ( {C0_L6F, C0_L6E, C0_L6D, C0_L6C} ),
	.INIT_1C ( {C0_L73, C0_L72, C0_L71, C0_L70} ),
	.INIT_1D ( {C0_L77, C0_L76, C0_L75, C0_L74} ),
	.INIT_1E ( {C0_L7B, C0_L7A, C0_L79, C0_L78} ),
	.INIT_1F ( {C0____, C0_L7E, C0_L7D, C0_L7C} )
  ) u_charmap_ram (
	.ADDR ( charmap_addr ),
	.CLK  ( ~clk_i       ),
	.DI   ( 8'h00        ),
	.DIP  ( 1'b0         ),
	.DO   ( ram_o        ),
	.DOP  (              ),
	.EN   ( 1'b1         ),
	.WE   ( 1'b0         ),
	.SSR  ( 1'b0         )
);

endmodule
