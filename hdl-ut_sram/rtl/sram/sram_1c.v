`timescale 1ns / 1ps
/**
 *  EK-Miniterm - SRAM controller
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
module sram_1c(
	input  rst_i,
	input  clk_i,
	// Wishbone interface
	input         wb_clk_i,
	input         wb_cyc_i,
	input         wb_we_i,
	output        wb_ack_o,
	input  [16:0] wb_addr_i,
	output [ 7:0] wb_datr_o,
	input  [ 7:0] wb_datw_i,
	//
	output mem_clk_o,
	output mem_cs_o,
	inout  [1:0] mem_dat_io
);

// Global memory registers
reg        pg_good;
reg        pg_dirty;
reg [7:0]  pg_addr;
reg        bram_wb_we = 1'b0;
wire [7:0] bram_wb_do;

// Wishbone
wire wb_rd, wb_wr;
assign wb_rd = (wb_cyc_i && (wb_we_i == 1'b0));
assign wb_wr = (wb_cyc_i && (wb_we_i == 1'b1));

assign wb_datr_o = bram_wb_do[7:0];
reg wb_dirty = 1'b0;

reg wb_ack = 1'b0;
assign wb_ack_o = (wb_cyc_i & wb_ack);

wire wb_pg_good;
assign wb_pg_good = (wb_addr_i[16:9] == pg_addr[7:0]);

reg  refresh = 1'b0;

always @(posedge wb_clk_i)
begin
	if (wb_dirty) begin
		if (pg_dirty)
			wb_dirty <= 1'b0;
	end
	
	// Case of wishbone READ cycle
	if (wb_rd) begin
		if (pg_good && wb_pg_good)
			wb_ack <= 1'b1;
		else
			refresh <= 1'b1;
	// Case of wishbone WRITE cycle
	end else if (wb_wr) begin
		if (pg_good && wb_pg_good) begin
			wb_ack     <= 1'b1;
			bram_wb_we <= 1'b1;
			wb_dirty   <= 1'b1;
			refresh    <= 1'b0;
		end else begin
			refresh <= 1'b1;
		end
	end else begin
		wb_ack     <= 1'b0;
		bram_wb_we <= 1'b0;
		refresh    <= 1'b0;
	end
end

reg mem_cs;
assign mem_cs_o  = mem_cs;

//reg sdi_en = 1'b0; // RFU
reg sdi_rw = 1'b0;
reg spi_start = 1'b0;
reg [7:0] data_tx;
reg [7:0] data_rx;
wire dat_o;
reg spi_run;

reg        bram_we;
reg  [1:0] bram_page;
reg  [8:0] byte_addr;
wire [7:0] bram_do;

reg [3:0] state;
reg       cs_dly;

wire state_wait = spi_run | spi_start;

always @(posedge clk_i)
begin
	if (rst_i == 1'b1) begin
		state      <= 4'h0;
		mem_cs     <= 1'b1;
		spi_start  <= 1'b0;
		cs_dly     <= 1'b0;
		pg_good    <= 1'b0;
		pg_dirty   <= 1'b0;
		pg_addr    <= 8'b0;
		bram_we    <= 1'b0;
		bram_page  <= 2'b00;
	end else begin
	
		if (wb_dirty)
			pg_dirty <= 1'b1;
	
		if (state_wait == 1'b0) begin
			if (cs_dly) begin
				mem_cs <= 1'b1;
				cs_dly <= 1'b0;
			end else begin

			case (state)
				// State Startup - Only used after reset
				4'd0: begin
					state  <= 4'd2;
				end
				
				// State IDLE - Wait for a request
				4'd1: begin
					sdi_rw  <= 1'b0;
					if (refresh) begin
						if (pg_dirty) begin
							state   <= 4'd4;
						end else begin
							if ((wb_pg_good == 1'b0) || (pg_good == 1'b0)) begin
								pg_good <= 1'b0;
								state   <= 4'd7;
							end
						end
					end // if (refresh)
				end
				
				// Write Mode Register
				4'd2: begin
					// Set CS
					mem_cs <= 1'b0;
					// Command WRMR
					data_tx <= 8'h01;
					sdi_rw  <= 1'b1;
					spi_start <= 1'b1;
					state   <= 4'd3;
				end
				// Write Mode Register - value
				4'd3: begin
					// Set sequencial mode
					data_tx   <= 8'h40;
					spi_start <= 1'b1;
					cs_dly    <= 1'b1;
					state     <= 4'd1;
				end
				
				// Write: send Write command
				4'd4: begin
					// Reset the byte counter
					byte_addr <= 9'd2;
					
					sdi_rw  <= 1'b1;
					// Set CS
					mem_cs <= 1'b0;
					// Write command
					data_tx   <= 8'h02;
					spi_start <= 1'b1;
					state     <= 4'd5;
				end
				// Write: send 24bit address
				4'd5: begin
					case (byte_addr[1:0])
						// Addr byte 2
						2'b10: begin
							// Send addr bits 23 to 16
							data_tx   <= {7'b0, pg_addr[7] };
							byte_addr[1:0] <= 2'b01;
						end
						// Addr byte 1
						2'b01: begin
							// Send addr bits 15 to 8
							data_tx   <= {pg_addr[6:0], 1'b0};
							byte_addr[1:0] <= 2'b00;
						end
						// Addr byte 0
						2'b00: begin
							// Send addr bits 7 to 0
							data_tx   <= 8'h00;
							state     <= 4'd6;
						end
					endcase
					spi_start <= 1'b1;
				end
				// Write: send Data byte
				4'd6: begin
					data_tx   <= bram_do[7:0];
					spi_start <= 1'b1;
					byte_addr <= byte_addr + 9'd1;
					if (byte_addr == 9'h1FF) begin
						cs_dly    <= 1'b1;
						pg_dirty  <= 1'b0;
						state     <= 4'd1;
					end
				end

				// Read process
				
				4'd7: begin
					pg_addr <= wb_addr_i[16:9];
					state   <= 4'd8;
				end
				// Send Read command
				4'd8: begin
					// Reset the byte counter
					byte_addr <= 9'd2;
					
					sdi_rw  <= 1'b1;
					// Set CS to start transaction
					mem_cs <= 1'b0;
					// Read command
					data_tx   <= 8'h03;
					spi_start <= 1'b1;
					state     <= 4'd9;
				end
				// Read: send 24bit address
				4'd9: begin
					case (byte_addr[1:0])
						// Addr byte 2
						2'b10: begin
							// Send addr bits 23 to 16
							data_tx   <= {7'b0, pg_addr[7] };
							byte_addr[1:0] <= 2'b01;
						end
						// Addr byte 1
						2'b01: begin
							// Send addr bits 15 to 8
							data_tx   <= {pg_addr[6:0], 1'b0};
							byte_addr[1:0] <= 2'b00;
						end
						// Addr byte 0
						2'b00: begin
							// Send addr bits 7 to 0
							data_tx   <= 8'h00;
							state     <= 4'd10;
						end
					endcase
					spi_start <= 1'b1;
				end
				// Read: send dummy byte
				4'd10: begin
					data_tx   <= 8'h00;
					bram_we   <= 1'b1;
					spi_start <= 1'b1;
					state     <= 4'd11;
				end
				// Read: receive data byte
				4'd11: begin
					spi_start <= 1'b1;
					byte_addr <= byte_addr + 9'd1;
					if (byte_addr == 9'h1FF) begin
						cs_dly  <= 1'b1;
						pg_good <= 1'b1;
						state   <= 4'd1;
						bram_we <= 1'b0;
					end
				end
			endcase
			end // if cs_dly
		// (state_wait == 1'b1)
		end else begin
			// Wait SPI started
			if (spi_start) begin
				if (spi_run) begin
					spi_start <= 1'b0;
				end
			end
		end
	end
end

// ----------------------------------------------------------------------------
// -- Buffer Memory --
// ----------------------------------------------------------------------------
RAMB16_S9_S9 #(
	.INIT_00 ( { 128'h00, 64'h00, 32'h00, 32'hCB_31_55_AA } )
  ) bram_u (
	// Port A : SPI sync
	.ADDRA ( {bram_page, byte_addr} ),
	.CLKA  ( clk_i        ),
	.DIA   ( data_rx[7:0] ),
	.DIPA  ( 1'b0         ),
	.DOA   ( bram_do[7:0] ),
	.DOPA  (              ),
	.ENA   ( 1'b1         ),
	.WEA   ( bram_we      ),
	.SSRA  ( 1'b0         ),
	// Port B : Wishbone access
	.ADDRB ( {bram_page, wb_addr_i[8:0]} ),
	.CLKB  ( wb_clk_i        ),
	.DIB   ( wb_datw_i[7:0]  ),
	.DIPB  ( 1'b0            ),
	.DOB   ( bram_wb_do[7:0] ),
	.DOPB  (                 ),
	.ENB   ( 1'b1            ),
	.WEB   ( bram_wb_we      ),
	.SSRB  ( 1'b0            )
);

// ----------------------------------------------------------------------------
// --                        SPI / SDI  data transfer                        --
// ----------------------------------------------------------------------------
reg [2:0] spi_bit_count;

// TX: Set output datas on falling edges
always @(negedge clk_i)
begin
	if (rst_i == 1'b1) begin
		spi_run <= 1'b0;
	end else begin
		// SPI is idle, wait spi_start signal
		if (spi_run == 1'b0) begin
			spi_bit_count <= 3'b000;
			if (spi_start)
				spi_run <= 1'b1;
		// SPI is busy
		end else begin
			spi_bit_count <= spi_bit_count + 3'd1;
			if (spi_bit_count == 3'b111)
				spi_run <= 1'b0;
		end
	end
end

// RX: Receive data on rising edges
always @(posedge clk_i)
begin
	if (spi_run)
		data_rx <= {data_rx[6:0], mem_dat_io[1]};
end

assign mem_clk_o = spi_run ? clk_i : 1'b0;

assign dat_o = (spi_run == 1'b0) ? 1'bx :
                 (spi_bit_count == 3'b000) ? data_tx[7] :
					  (spi_bit_count == 3'b001) ? data_tx[6] :
					  (spi_bit_count == 3'b010) ? data_tx[5] :
					  (spi_bit_count == 3'b011) ? data_tx[4] :
					  (spi_bit_count == 3'b100) ? data_tx[3] :
					  (spi_bit_count == 3'b101) ? data_tx[2] :
					  (spi_bit_count == 3'b110) ? data_tx[1] :
                 (spi_bit_count == 3'b111) ? data_tx[0] : 1'bx;

assign mem_dat_io[0] = sdi_rw ? dat_o : 1'bz;

endmodule
