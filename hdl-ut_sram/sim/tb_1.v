`timescale 1ns / 1ps
module tb_1;

	reg clk50;
	wire mem_cs;
	wire mem_clk;
	wire [1:0] mem_dat;

	// Instantiate the Unit Under Test (UUT)
	ut_sram_main #(
		.SIM("ISIM")
	) uut (
		.clk50_i   ( clk50   ),
		//
		.mem_clk_o ( mem_clk ),
		.mem_cs_o  ( mem_cs  ),
		.mem_dat_io( mem_dat )
	);

	initial begin
		#5 clk50 = 0;
		
		#1000000;
		$finish;
	end
	
	// Generate a 50MHz clock
	always begin
		#10 clk50 = 0;
		#10 clk50 = 1;
	end
	
	reg dat_o = 1'b0;
	assign mem_dat[1] = dat_o;
	
	always @(posedge mem_clk)
	begin
		if (mem_cs == 1'b0) begin
			dat_o <= ~dat_o;
		end
	end
	
	/*
	RAMB16_S9_S9 #(
		.INIT_00 ( { 128'h00, 64'h00, 32'h00, 32'hCB_31_55_AA } )
	) bram_u (
		.ADDRA ( {bram_page, byte_addr} ),
		.CLKA  ( clk_i     ),
		.DIA   ( 8'h00     ),
		.DIPA  ( 1'b0      ),
		.DOA   ( bram_do   ),
		.DOPA  (          ),
		.ENA   ( 1'b1     ),
		.WEA   ( bram_we  ),
		.SSRA  ( 1'b0     )
	);
	*/

endmodule

