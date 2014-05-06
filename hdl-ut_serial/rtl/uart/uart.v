/**
 *  EK-Miniterm - UART
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
module uart(
	input  rst_i,
	input  wb_clk_i,
	input  wb_cyc_i,
	input  wb_we_i,
	input  [1:0] wb_addr_i,
	input  [7:0] wb_datw_i,
	output [7:0] wb_datr_o,
	input  clk_uart_i,
	input  uart_rx,
	output uart_tx,
	output wb_int_o
);

reg cfg_spd = 1'b0;

wire uart_clk;
reg run = 1'b0;
reg [1:0] step = 2'b0;
reg [2:0] bit_cnt = 3'd0;
reg [7:0] rx_byte = 8'h00;
reg [7:0] rx_fifo0= 8'h00;
reg rx_full;

reg       tx_run   = 1'b0;
reg       tx_start = 1'b0;
reg [7:0] tx_fifo0 = 8'h00;

wire wb_rd, wb_wr;
assign wb_datr_o[7:0] = rx_fifo0[7:0];
assign wb_int_o       = rx_full;
assign wb_rd = (wb_cyc_i & (wb_we_i == 1'b0));
assign wb_wr = (wb_cyc_i & (wb_we_i == 1'b1));

reg wb_step = 1'b0;
always @(posedge wb_clk_i)
begin
	if (rst_i) begin
		rx_full <= 1'b0;
	end
	if (wb_rd == 1'b1) begin
		rx_full <= 1'b0;
	end
	if (wb_wr == 1'b1) begin
		if (wb_addr_i == 2'b00) begin
			tx_fifo0 <= wb_datw_i;
			tx_start <= 1'b1;
		end
		if (wb_addr_i == 2'b01) begin
			 cfg_spd <= wb_datw_i[0];
		end
	end
	if (tx_start && tx_run)
		tx_start <= 1'b0;
	if (wb_step == 1'b0) begin
		if (run == 1'b1)
			wb_step <= 1'b1;
	end else begin
		if (run == 1'b0) begin
			if (uart_rx == 1'b1)
				rx_full <= 1'b1;
			wb_step <= 1'b0;
		end
	end
end

reg clk_8M = 1'b0;
always @(posedge clk_uart_i)
begin
	clk_8M <= ~clk_8M;
end

reg [5:0] clk_uart_hs = 6'h0;
always @(posedge clk_8M)
begin
	if (rst_i == 1'b1) begin
		run <= 1'b0;
		clk_uart_hs <= 6'h0;
	end else begin
		if (run == 1'b0) begin
			if (uart_rx == 1'b0)
				run <= 1'b1;
			clk_uart_hs <= 6'd0;
		end else begin
			if ((step == 2'b00) & (uart_clk == 1'b1))
			begin
				run <= 1'b0;
				rx_fifo0 <= rx_byte;
			end
			clk_uart_hs <= clk_uart_hs + 6'd1;
		end
	end
end

assign uart_clk = cfg_spd ?
                      clk_uart_hs[2] : // 921600
                      clk_uart_hs[5];  // 115200

always @(posedge uart_clk)
begin
	if (step == 2'b00) begin
		step <= 2'b01;
		rx_byte <= 8'h00;
	end else if (step == 2'b01) begin
		if (bit_cnt == 3'b111)
			step <= 2'b10;
		bit_cnt <= bit_cnt + 3'd1;
		rx_byte <= { uart_rx, rx_byte[7:1]};
	end else if (step == 2'b10) begin
		step     <= 2'b00;
	end
end

// ----------------------------------------------------------------------------
// --                                TX  side                                --
// ----------------------------------------------------------------------------
reg [7:0] tx_data    = 8'h00;
reg [3:0] tx_clk_hs  = 4'h0;
reg [1:0] tx_step    = 2'h0;
reg [2:0] tx_bit_cnt = 3'd0;
reg       tx_end;
reg       tx_out = 1'b1;
wire      tx_clk_4x;

always @(posedge clk_8M)
begin
	if (rst_i == 1'b1) begin
		tx_end <= 1'b0;
		tx_clk_hs <= 4'h0;
	end else begin
		if (tx_step == 2'b10)
			tx_end <= 1'b1;
		if (tx_end && (tx_step == 2'b00))
			tx_run <= 1'b0;
		if (tx_run == 1'b0) begin
			if (tx_start == 1'b1) begin
				tx_run <= 1'b1;
			end else begin
				tx_clk_hs <= 4'd0;
				tx_end    <= 1'b0;
			end
		end else begin
			tx_clk_hs <= tx_clk_hs + 4'd1;
		end
	end
end

assign tx_clk_4x = cfg_spd ?
                  tx_clk_hs[0] : // 921600
                  tx_clk_hs[3];  // 115200

assign uart_tx = (tx_run == 1'b0) ? 1'b1 : tx_out;

reg [1:0] tx_clk_step = 2'b0;

always @(posedge tx_clk_4x)
begin
	tx_clk_step <= tx_clk_step + 2'd1;
	
	if (tx_step == 2'b00) begin
		tx_step    <= 2'b01;
		tx_bit_cnt <= 3'd0;
		tx_data    <= tx_fifo0;
		// Set out to LOW for start bit
		tx_out     <= 1'b0;
	end else if (tx_step == 2'b01) begin
		if (tx_clk_step == 2'b00) begin
			if (tx_bit_cnt == 3'b111)
				tx_step <= 2'b10;
			tx_bit_cnt <= tx_bit_cnt + 3'd1;
			tx_out  <= tx_data[0];
			tx_data <= { 1'b0, tx_data[7:1] };
		end
	end else if (tx_step == 2'b10) begin
		if (tx_clk_step == 2'b00) begin
			tx_step     <= 2'b00;
			tx_clk_step <= 2'b00;
		end
	end
end

endmodule
