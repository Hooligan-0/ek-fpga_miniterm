/**
 *  EK-Miniterm - SRAM Unit Test
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
module ut_sram_main(
	// Main clock
	input  clk50_i,
	// Memory / SPI interface
	output mem_clk_o,
	output mem_cs_o,
	inout  [1:0] mem_dat_io
);

parameter SIM = "NONE";

// Control signals
wire clk_sys;
wire rst_sys;
// Wishbone signals
wire wb_cyc, wb_we, wb_ack;
wire [16:0] wb_addr;
wire [ 7:0] wb_datr, wb_datw;

// ----------------------------------------------------------------------------
// --                            Clocks and Reset                            --
// ----------------------------------------------------------------------------
clock clocks_u (
	.rst_i      ( 1'b0     ),
	.clk_i      ( clk50_i  ),
	.clk_sys_o  ( clk_sys  ),
	.reset_o    ( rst_sys  )
);

// ----------------------------------------------------------------------------
// --                          Finite State Machine                          --
// ----------------------------------------------------------------------------
fsm_ut_sram fsm_u (
	.rst_i     ( rst_sys       ),
	.wb_clk_i  ( clk_sys       ),
	.wb_cyc_o  ( wb_cyc        ),
	.wb_we_o   ( wb_we         ),
	.wb_ack_i  ( wb_ack        ),
	.wb_addr_o ( wb_addr[16:0] ),
	.wb_datr_i ( wb_datr       ),
	.wb_datw_o ( wb_datw       )
);

// ----------------------------------------------------------------------------
// --                        External SRAM controller                        --
// ----------------------------------------------------------------------------
sram_1c sram_u (
	.rst_i ( rst_sys ),
	.clk_i ( clk_sys ),
	// Wishbone interface
	.wb_clk_i   ( clk_sys       ),
	.wb_cyc_i   ( wb_cyc        ),
	.wb_we_i    ( wb_we         ),
	.wb_addr_i  ( wb_addr[16:0] ),
	.wb_ack_o   ( wb_ack        ),
	.wb_datr_o  ( wb_datr       ),
	.wb_datw_i  ( wb_datw       ),
	// External memory interface
	.mem_clk_o ( mem_clk_o       ),
	.mem_cs_o  ( mem_cs_o        ),
	.mem_dat_io( mem_dat_io[1:0] )
);

endmodule
