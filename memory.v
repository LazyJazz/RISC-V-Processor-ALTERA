module memory(
	input cpu_clk,
	input clk,
	input sig_load,
	input sig_store,
	input [2:0] type,
	input [31:0] addr,
	input[31:0] data,
	output[31:0] q,
	output mem_stall
	);
	reg write_stall;
	
	
	
	wire [31:0] store_byte;
	wire [31:0] store_half;
	wire [31:0] store_word;
	
	wire [31:0] load_byte;
	wire [31:0] load_half;
	wire [31:0] load_word;
	
	reg buffer_sig_load;
	
	wire [31:0] ram_q;
	wire [31:0] store_data;
	
	assign mem_stall = write_stall;
	
	assign store_byte[31:24] = ((addr[1:0] == 2'b11) ? data[7:0]: ram_q[31:24]);
	assign store_byte[23:16] = ((addr[1:0] == 2'b10) ? data[7:0]: ram_q[23:16]);
	assign store_byte[15:8] = ((addr[1:0] == 2'b01) ? data[7:0]: ram_q[15:8]);
	assign store_byte[7:0] = ((addr[1:0] == 2'b00) ? data[7:0]: ram_q[7:0]);
	
	assign store_half[31:16] = (addr[1] ? data[15:0] : ram_q[31:16]);
	assign store_half[15:0] = (addr[1] ? ram_q[15:0] : data[15:0]);
	
	assign store_word = data;
	
	assign load_byte[31:8] = ((!type[2]) && ram_q[7]) ? 24'b111111111111111111111111 : 0;
	assign load_byte[7:0] = ram_q[7:0];
	
	assign load_half[31:16] = ((!type[2]) && ram_q[15]) ? 16'b1111111111111111 : 0;
	assign load_half[15:0] = ram_q[15:0];
	
	assign load_word = ram_q;
	
	assign q = buffer_sig_load ? (
		(type[1:0] == 2'b10) ? load_word: (
		(type[1:0] == 2'b01) ? load_half:
		load_byte
		)
	) : 0;
//	assign q = ram_q;
	
	wire readen;
	wire writeen;
	
	assign readen = sig_load || (sig_store && !write_stall && (type[1:0] != 2'b10));
	
	assign writeen = sig_store && (write_stall || (type[1:0] == 2'b10));
	
	assign store_data = (
		(type[1:0] == 2'b10) ? store_word : (
		(type[1:0] == 2'b01) ? store_half : store_byte
		)
	);
	
	ram
		ram0(
			cpu_clk,
			store_data,
			addr[13:2],readen,
			addr[13:2],writeen,
			ram_q
		);
	
	always @ (posedge cpu_clk)
	begin
		if (sig_store && (type[1:0] != 2'b10) && !write_stall)
			write_stall <= 1;
		else
			write_stall <= 0;
		buffer_sig_load <= sig_load;
	end
endmodule
