module register(
	input cpu_clk,
	input rst,
	input stall,
	input [4:0] rs1, 
	input [4:0] rs2, 
	input [4:0] rd,
	input [31:0] wb,
	input wb_sig,
	output [31:0] r1,
	output [31:0] r2,
	output [8:0] led_out);
	
	
	reg [31:0] xx[31:0];
	
	//assign led_out[9] = !(!xx[1]);
	assign led_out[8] = !(!xx[2]);
	assign led_out[7] = !(!xx[8]);
	assign led_out[6] = !(!xx[14]);
	assign led_out[5] = !(!xx[15]);
	assign led_out[4] = !(!xx[3]);
	assign led_out[3] = !(!xx[4]);
	assign led_out[2] = !(!xx[5]);
	assign led_out[1] = !(!xx[6]);
	assign led_out[0] = !(!xx[7]);
	
	assign r1 = rs1 ? xx[rs1] : 0;
	assign r2 = rs2 ? xx[rs2] : 0;
	
	always @ (posedge cpu_clk)
	begin
		if (rst)
		begin
			xx[1] <= 32'b11111111111111111111111111111111;
			xx[2] <= 32'h00000FF0;
			xx[3] <= 0;
			xx[4] <= 0;
			xx[5] <= 0;
			xx[6] <= 0;
			xx[7] <= 0;
			xx[8] <= 0;
			xx[9] <= 0;
			xx[10] <= 0;
			xx[11] <= 0;
			xx[12] <= 0;
			xx[13] <= 0;
			xx[14] <= 0;
			xx[15] <= 0;
			xx[16] <= 0;
			xx[17] <= 0;
			xx[18] <= 0;
			xx[19] <= 0;
			xx[20] <= 0;
			xx[21] <= 0;
			xx[22] <= 0;
			xx[23] <= 0;
			xx[24] <= 0;
			xx[25] <= 0;
			xx[26] <= 0;
			xx[27] <= 0;
			xx[28] <= 0;
			xx[29] <= 0;
			xx[30] <= 0;
			xx[31] <= 0;
		end
		else
		begin		
			if (wb_sig && !stall && rd)
				xx[rd] <= wb;
		end
	end
endmodule
