/**
 *  EK-Miniterm - SRAM Unit Test - Clocks module
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
module clock(
	input  rst_i,
	input  clk_i,
	output clk_sys_o,
	output reset_o
);

parameter CLK_PERIOD  = 20.0;
parameter CLK_DIVIDER = 5;

wire    ref_clk0;
wire    clkfb;
wire    pll_clk;
wire    pll_locked;

IBUFG bufg_clk_u (
	.I  ( clk_i    ),
	.O  ( clk_main )
);

DCM_SP #(
	.CLKDV_DIVIDE          ( 2                    ),
	.CLKFX_DIVIDE          ( CLK_DIVIDER          ),
	.CLKFX_MULTIPLY        ( 2                    ),
	.CLKIN_DIVIDE_BY_2     ( "FALSE"              ),
	.CLKIN_PERIOD          ( CLK_PERIOD           ),
	.CLKOUT_PHASE_SHIFT    ( "NONE"               ),
	.CLK_FEEDBACK          ( "1X"                 ),
	.DESKEW_ADJUST         ( "SYSTEM_SYNCHRONOUS" ),
	.DFS_FREQUENCY_MODE    ( "LOW"                ),
	.DLL_FREQUENCY_MODE    ( "LOW"                ),
	.DUTY_CYCLE_CORRECTION ( "TRUE"               ),
	.FACTORY_JF            ( 16'hC080             ),
	.PHASE_SHIFT           ( 0                    ),
	.STARTUP_WAIT          ( "TRUE"               )
) pll_adv_u (
	.DSSEN    (             ),
	.CLK0     ( ref_clk0    ),
	.CLK90    (             ),
	.CLK180   (             ),
	.CLK270   (             ),
	.CLK2X    (             ),
	.CLK2X180 (             ),
	.CLKDV    (             ),
	.CLKFX    ( pll_clk     ),
	.CLKFX180 (             ),
	.LOCKED   ( pll_locked  ),
	.PSDONE   (             ),
	.STATUS   (             ),
	.CLKFB    ( clkfb       ),
	.CLKIN    ( clk_main    ),
	.PSCLK    ( 1'b0        ),
	.PSEN     ( 1'b0        ),
	.PSINCDEC ( 1'b0        ),
	.RST      ( rst_i       ) // default : (1'b0)
);

BUFG bufg_feedback_u (
	.I ( ref_clk0 ),
	.O ( clkfb    )
);

BUFG bufg_sys_clk_u (
	.I ( pll_clk   ),
	.O ( clk_sys_o )
);

reg [3:0] rst_wait = 4'b1111;
reg rst;
always @(posedge clk_sys_o)
begin
	if (rst_wait == 4'b0000)
		rst <= 1'b0;
	else begin
		rst <= 1'b1;
		if (pll_locked == 1'b1)
			rst_wait <= rst_wait - 4'd1;
		else
			rst_wait <= 4'b1111;
	end
end

assign reset_o = rst;

endmodule
