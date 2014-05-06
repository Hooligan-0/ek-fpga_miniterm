/**
 *  EK-Miniterm - Finite State Machine for UART unit-test
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
module fsm_ut_serial(
	input        rst_i,
	input        wb_clk_i,
	output       wb_cyc_o,
	output       wb_we_o,
	output [1:0] wb_addr_o,
	input  [7:0] wb_datr_i,
	output [7:0] wb_datw_o,
	input        int_i
);

reg [3:0] state;
reg [1:0] wb_addr;
reg [7:0] wb_datw;
reg wb_cyc;
reg wb_we;
assign wb_cyc_o  = wb_cyc;
assign wb_we_o   = wb_we;
assign wb_addr_o = wb_addr;
assign wb_datw_o = wb_datw;

reg [7:0] data_byte;

always @(posedge wb_clk_i)
begin
	if (rst_i == 1'b1) begin
		state   <= 4'd0;
		wb_cyc  <= 1'b0;
		wb_we   <= 1'b0;
		wb_addr <= 2'b00;
	end else begin
		case(state)
			// Idle state, wait for event
			4'b0000: begin
				// If UART interrupt is set
				if (int_i == 1'b1)
					state <= 4'h1;
			end
			
			// RX: start read data transaction
			4'h1: begin
				wb_cyc  <= 1'b1;
				wb_addr <= 5'b00;
				state <= 4'h2;
			end
			// RX: end of read data transaction
			4'h2: begin
				data_byte <= wb_datr_i;
				wb_cyc  <= 1'b0;
				state <= 4'h3;
			end
			
			// TX: start of write back (echo)
			4'h3: begin
				wb_cyc  <= 1'b1;
				wb_we   <= 1'b1;
				wb_addr <= 2'b00;
				wb_datw <= data_byte;
				state <= 4'h4;
			end
			// TX: end of write transaction
			4'h4: begin
				wb_cyc  <= 1'b0;
				wb_we   <= 1'b0;
				state <= 4'h0;
			end
			
			default: begin
				state <= 4'h0;
			end
		endcase
	end
end

endmodule
