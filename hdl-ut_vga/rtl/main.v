/**
 *  EK-Miniterm - VGA Unit Test
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
module main(
	// Main clock
	input  clk50_i,
	// VGA sync signals
	output vga_hs_o,
	output vga_vs_o,
	// VGA data signals
	output vga_red_o,
	output vga_grn_o,
	output vga_blu_o
);

parameter SIM = "NONE";

// Control signals
wire clk_vga;
wire rst_sys;
// VGA Signals
wire [9:0] pos_x;
wire [9:0] pos_y;
wire vga_disp_en, vga_char_en;
wire [2:0] chars_color;

// ----------------------------------------------------------------------------
// --                            Clocks and Reset                            --
// ----------------------------------------------------------------------------
clock clocks_u (
	.rst_i      ( 1'b0     ),
	.clk_i      ( clk50_i  ),
	.clk_vga_o  ( clk_vga  ),
	.reset_o    ( rst_sys  )
);

// ----------------------------------------------------------------------------
// --                          Character generator                           --
// ----------------------------------------------------------------------------
vga_char vga_chars_u (
	.clk_i       ( clk_vga          ),
	// Wishbone bus (not used for this unit-test)
	.wb_clk      ( 1'b0             ),
	.wb_cyc_i    ( 1'b0             ),
	.wb_we_i     ( 1'b0             ),
	.wb_addr_i   ( 3'b0             ),
	.wb_dati     ( 8'h00            ),
	// Cursor position and current pixel datas
	.current_x_i ( pos_x            ),
	.current_y_i ( pos_y            ),
	.active_o    ( vga_char_en      ),
	.color_o     ( chars_color[2:0] )
);
assign vga_red_o = (vga_disp_en & vga_char_en) ? chars_color[0] : 1'b0;
assign vga_grn_o = (vga_disp_en & vga_char_en) ? chars_color[1] : 1'b0;
assign vga_blu_o = (vga_disp_en & vga_char_en) ? chars_color[2] : 1'b0;

// ----------------------------------------------------------------------------
// --                       Generate VGA sync signals                        --
// ----------------------------------------------------------------------------
vga_sync #(
		.H_FP     (   8 ), // Front porch (in pixels-clocks) // 16 > 8
		.H_BP     (  40 ), // Back porch (in pixels-clocks)  // 48 > 40
		.H_PULSE  (  96 ), // HS pulse length (in pixels-clocks)
		.H_PIXELS ( 640 ), // Whole line
		.V_FP     (   2 ), // Vertical front porch (in lines)  // 10 > 2
		.V_BP     (  25 ), // Vertical back porch (in lines)   // 33 > 25
		.V_PULSE  (   2 ), // VS pulse length
		.V_LINES  ( 480 )  // Number of lines
	) sync_u (
		.rst_i   ( rst_sys     ),
		.clk_i   ( clk_vga     ),
		//
		.enable_i( 1'b1        ),
		.valid_o ( vga_disp_en ),
		//
		.pos_x_o ( pos_x       ),
		.pos_y_o ( pos_y       ),
		//
		.sync_vs ( vga_vs_o    ),
		.sync_hs ( vga_hs_o    ) 
);

endmodule
