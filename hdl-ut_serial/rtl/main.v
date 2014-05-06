/**
 *  EK-Miniterm - Serial ports Unit Test
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
	input  clk50_i,
	input  clk14_i,
	// UART signals
	input  uart_rx_i,
	output uart_tx_o,
	input  uart_cts_i,
	output uart_rts_o
);

parameter SIM = "NONE";

wire wb_cyc, wb_we;
wire [1:0] wb_addr;
wire [7:0] wb_datr, wb_datw;
wire uart_int;

wire clk_sys, clk_uart;
wire rst_sys;
clock clocks_u (
	.rst_i      ( 1'b0     ),
	.clk_i      ( clk50_i  ),
	.clk2_i     ( clk14_i  ),
	.clk_sys_o  ( clk_sys  ),
	.clk_uart_o ( clk_uart ),
	.reset_o    ( rst_sys  )
);

// ----------------------------------------------------------------------------
// --                          Finite State Machine                          --
// ----------------------------------------------------------------------------
fsm_ut_serial fsm_u (
	.rst_i     ( rst_sys      ),
	.wb_clk_i  ( clk_sys      ),
	.wb_cyc_o  ( wb_cyc       ),
	.wb_we_o   ( wb_we        ),
	.wb_addr_o ( wb_addr[1:0] ),
	.wb_datr_i ( wb_datr      ),
	.wb_datw_o ( wb_datw      ),
	.int_i     ( uart_int     )
);

// ----------------------------------------------------------------------------
// --                        Serial (UART) controller                        --
// ----------------------------------------------------------------------------
uart uart_u (
	.rst_i      ( rst_sys      ),
	// Wishbone interface
	.wb_clk_i   ( clk_sys      ),
	.wb_cyc_i   ( wb_cyc       ),
	.wb_we_i    ( wb_we        ),
	.wb_addr_i  ( wb_addr[1:0] ),
	.wb_datr_o  ( wb_datr      ),
	.wb_datw_i  ( wb_datw      ),
	.wb_int_o   ( uart_int     ),
	// UART interface
	.clk_uart_i ( clk_uart     ),
	.uart_rx    ( uart_rx_i    ),
	.uart_tx    ( uart_tx_o    )
);
assign uart_rts_o = uart_cts_i;

endmodule
