`timescale 1ns / 1ps
module tb_1;

	reg clk50;
	reg clk14;
	reg uart_rx;

	// Instantiate the Unit Under Test (UUT)
	main #(
		.SIM("ICARUS")
	) uut (
		.clk50_i   ( clk50   ),
		.clk14_i   ( clk14   ),
		// UART interface
		.uart_rx_i ( uart_rx ),
		.uart_tx_o (         ),
		.uart_cts_i( 1'b1    ),
		.uart_rts_o(         )
	);

	initial begin
		uart_rx  = 1;
		#5 clk50 = 0;
		#5 clk14 = 0;

		// Send the first test-byte : 0x55
		#1000;
		uart_tx_115(8'h55);
		// Wait 1 byte and half for TX echo
		#86800
		#43400
		
		// Send the second test-byte : 0xAA
		uart_tx_115(8'hAA);
		// Send the third test-byte : 0x31 (without pause)
		uart_tx_115(8'h31);
		
		#100000
		// Send a buggus char
		uart_rx = 0;
		#86800
		uart_rx = 1;
		
		#100000;
		$finish;
	end
	
	always begin
		#10 clk50 = 0;
		#10 clk50 = 1;
	end
	
	always begin
		#33.9 clk14 = 0;
		#33.9 clk14 = 1;
	end

task uart_tx_115;
	input [7:0] data;
	begin
		$display("[%0d] Send %1x", $time, data);
		// Start bit
		uart_rx = 0;
		// Data bits
		#8680 uart_rx = data[0];
		#8680 uart_rx = data[1];
		#8680 uart_rx = data[2];
		#8680 uart_rx = data[3];
		#8680 uart_rx = data[4];
		#8680 uart_rx = data[5];
		#8680 uart_rx = data[6];
		#8680 uart_rx = data[7];
		// Stop bit
		#8680 uart_rx = 1;
		// Wait one bit to finish Stop bit
		#8680;
	end
endtask

task uart_tx_921;
	begin
		// Start bit
		#1085 uart_rx = 0;
		// Data bits
		#1085 uart_rx = 1; // DB0
		#1085 uart_rx = 0;
		#1085 uart_rx = 1;
		#1085 uart_rx = 0;
		#1085 uart_rx = 1;
		#1085 uart_rx = 0;
		#1085 uart_rx = 1;
		#1085 uart_rx = 0;
		// ...
		#1085 uart_rx = 1; // Stop bit
	end
endtask

endmodule

