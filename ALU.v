
module alu(
	input [31:0] in1,
	input [31:0] in2,
	input [6:0] opcode,
	input [2:0] funct3,
	input [6:0] funct7,
	output [31:0] res
	);
	
	wire [31:0] addv;
	
	assign addv = in1 + in2;
	
	wire [31:0] Ires [7:0];
	wire [31:0] slli [31:0];
	
	wire [31:0] srxi [31:0];
	wire [31:0] inf [31:0];
	
	wire [31:0] srxisig;
	assign srxisig = ((funct7[5] && in1[31]) ? 32'b11111111111111111111111111111111 : 0);
	
	assign Ires[0] = in1 + in2; //ADDI
	assign Ires[1] = slli[in2[4:0]]; //SLLI
	assign Ires[2] = ($signed(in1)<$signed(in2)); //SLTI
	assign Ires[3] = ($unsigned(in1)<$unsigned(in2)); //SLTIU
	assign Ires[4] = (in1 ^ in2); //XORI
	assign Ires[5] = srxi[in2[4:0]]; //SRXI
	assign Ires[6] = (in1 | in2); //ORI
	assign Ires[7] = (in1 & in2); //ANDI
	
	wire [31:0] Rres [7:0];
	
	assign Rres[0] = (funct7[5] ? (in1 - in2) : (in1 + in2)); //ADD SUB
	assign Rres[1] = slli[in2[4:0]]; //SLL
	assign Rres[2] = ($signed(in1)<$signed(in2)); //SLT
	assign Rres[3] = ($unsigned(in1)<$unsigned(in2)); //SLTU
	assign Rres[4] = (in1 ^ in2); //XOR
	assign Rres[5] = srxi[in2[4:0]]; //SRX
	assign Rres[6] = (in1 | in2); //OR
	assign Rres[7] = (in1 & in2); //AND
	
	wire [31:0] MULDIVres [3:0];
	wire [63:0] u64in1;
	wire [63:0] s64in1;
	wire [63:0] u64in2;
	wire [63:0] s64in2;
	assign u64in1[31:0] = in1;
	assign u64in1[63:32] = 0;
	assign u64in2[31:0] = in2;
	assign u64in2[63:32] = 0;
	assign s64in1[31:0] = in1;
	assign s64in1[63:32] = (in1[31] ? 32'hffffffff : 0);
	assign s64in2[31:0] = in2;
	assign s64in2[63:32] = (in2[31] ? 32'hffffffff : 0);
	
	wire [63:0] prodss;
	wire [63:0] prodsu;
	wire [63:0] produu;
	assign prodss = $signed(s64in1) * $signed(s64in2);
	assign prodsu = $signed(s64in1) * $unsigned(u64in2);
	assign produu = $unsigned(u64in1) * $unsigned(u64in2);
	wire [31:0] divres;
	wire [31:0] remres;
//	assign divres = $signed(in1) / $signed(in2);
//	assign divures = $unsigned(in1) / $unsigned(in2);
//	assign remres = $signed(in1) % $signed(in2);
//	assign remures = $unsigned(in1) % $unsigned(in2);
	wire [31:0] dividend;
	wire [31:0] divisor;
	
	assign divres = $unsigned(dividend) / $unsigned(divisor);
	assign remres = $unsigned(dividend) - $unsigned(divres) * $unsigned(divisor);
	wire dividend_neg;
	wire divisor_neg;
	assign dividend_neg = in1[31] && !funct3[0];
	assign divisor_neg = in2[31] && !funct3[0];
	assign dividend = dividend_neg ? -in1 : in1;
	assign divisor = divisor_neg ? -in2 : in2;
	wire [31:0] divremres;
	assign divremres = (
		funct3[1] ?
		((dividend_neg) ? -remres : remres) :
		((dividend_neg ^ divisor_neg) ? -divres : divres)
		);
	
	
//	assign divres = 0;
//	assign divures = 0;
//	assign remres = 0;
//	assign remures = 0;
	
	assign MULDIVres[0] = produu[31:0]; //MUL
	assign MULDIVres[1] = prodss[63:32]; //MULH
	assign MULDIVres[2] = prodsu[63:32]; //MULHSU
	assign MULDIVres[3] = produu[63:32]; //MULHU
	
	
	wire [31:0] Bres [7:0];
	
	assign Bres[0] = (in1 == in2);
	assign Bres[1] = (in1 != in2);
	assign Bres[2] = 0; //SLT
	assign Bres[3] = 0; //SLTU
	assign Bres[4] = ($signed(in1) < $signed(in2));
	assign Bres[5] = ($signed(in1) >= $signed(in2));
	assign Bres[6] = ($unsigned(in1) < $unsigned(in2));
	assign Bres[7] = ($unsigned(in1) >= $unsigned(in2));
	
	
	assign res = ((opcode == 7'b0000011 || opcode == 7'b0100011) ? addv : ( //Load and Store
		(opcode == 7'b0010011) ? Ires[funct3] : ( //Immediate Computation
		(opcode == 7'b0110011) ? (funct7[0] ? (funct3[2] ? divremres : MULDIVres[funct3[1:0]]) : Rres[funct3]) : ( //Rtype Computation
		(opcode == 7'b1100011) ? Bres[funct3] : ( //Btype 
			0
		)
		)
		)
	));
		
	/*** SRXI ***/
	assign srxi[0] = in1;
	assign srxi[1][31-1:0] = in1[31:1]; assign srxi[1][31] = srxisig[31];
	assign srxi[2][31-2:0] = in1[31:2]; assign srxi[2][31:32 - 2] = srxisig[31: 32 - 2];
	assign srxi[3][31-3:0] = in1[31:3]; assign srxi[3][31:32 - 3] = srxisig[31: 32 - 3];
	assign srxi[4][31-4:0] = in1[31:4]; assign srxi[4][31:32 - 4] = srxisig[31: 32 - 4];
	assign srxi[5][31-5:0] = in1[31:5]; assign srxi[5][31:32 - 5] = srxisig[31: 32 - 5];
	assign srxi[6][31-6:0] = in1[31:6]; assign srxi[6][31:32 - 6] = srxisig[31: 32 - 6];
	assign srxi[7][31-7:0] = in1[31:7]; assign srxi[7][31:32 - 7] = srxisig[31: 32 - 7];
	assign srxi[8][31-8:0] = in1[31:8]; assign srxi[8][31:32 - 8] = srxisig[31: 32 - 8];
	assign srxi[9][31-9:0] = in1[31:9]; assign srxi[9][31:32 - 9] = srxisig[31: 32 - 9];
	assign srxi[10][31-10:0] = in1[31:10]; assign srxi[10][31:32 - 10] = srxisig[31: 32 - 10];
	assign srxi[11][31-11:0] = in1[31:11]; assign srxi[11][31:32 - 11] = srxisig[31: 32 - 11];
	assign srxi[12][31-12:0] = in1[31:12]; assign srxi[12][31:32 - 12] = srxisig[31: 32 - 12];
	assign srxi[13][31-13:0] = in1[31:13]; assign srxi[13][31:32 - 13] = srxisig[31: 32 - 13];
	assign srxi[14][31-14:0] = in1[31:14]; assign srxi[14][31:32 - 14] = srxisig[31: 32 - 14];
	assign srxi[15][31-15:0] = in1[31:15]; assign srxi[15][31:32 - 15] = srxisig[31: 32 - 15];
	assign srxi[16][31-16:0] = in1[31:16]; assign srxi[16][31:32 - 16] = srxisig[31: 32 - 16];
	assign srxi[17][31-17:0] = in1[31:17]; assign srxi[17][31:32 - 17] = srxisig[31: 32 - 17];
	assign srxi[18][31-18:0] = in1[31:18]; assign srxi[18][31:32 - 18] = srxisig[31: 32 - 18];
	assign srxi[19][31-19:0] = in1[31:19]; assign srxi[19][31:32 - 19] = srxisig[31: 32 - 19];
	assign srxi[20][31-20:0] = in1[31:20]; assign srxi[20][31:32 - 20] = srxisig[31: 32 - 20];
	assign srxi[21][31-21:0] = in1[31:21]; assign srxi[21][31:32 - 21] = srxisig[31: 32 - 21];
	assign srxi[22][31-22:0] = in1[31:22]; assign srxi[22][31:32 - 22] = srxisig[31: 32 - 22];
	assign srxi[23][31-23:0] = in1[31:23]; assign srxi[23][31:32 - 23] = srxisig[31: 32 - 23];
	assign srxi[24][31-24:0] = in1[31:24]; assign srxi[24][31:32 - 24] = srxisig[31: 32 - 24];
	assign srxi[25][31-25:0] = in1[31:25]; assign srxi[25][31:32 - 25] = srxisig[31: 32 - 25];
	assign srxi[26][31-26:0] = in1[31:26]; assign srxi[26][31:32 - 26] = srxisig[31: 32 - 26];
	assign srxi[27][31-27:0] = in1[31:27]; assign srxi[27][31:32 - 27] = srxisig[31: 32 - 27];
	assign srxi[28][31-28:0] = in1[31:28]; assign srxi[28][31:32 - 28] = srxisig[31: 32 - 28];
	assign srxi[29][31-29:0] = in1[31:29]; assign srxi[29][31:32 - 29] = srxisig[31: 32 - 29];
	assign srxi[30][31-30:0] = in1[31:30]; assign srxi[30][31:32 - 30] = srxisig[31: 32 - 30];
	assign srxi[31][0] = in1[31:31]; assign srxi[31][31:32 - 31] = srxisig[31: 32 - 31];
	/*** SLLI ***/
	assign slli[0] = in1;
	assign slli[1][31: 1] = in1[31 - 1:0]; assign slli[1][0] = 0;
	assign slli[2][31: 2] = in1[31 - 2:0]; assign slli[2][1:0] = 0;
	assign slli[3][31: 3] = in1[31 - 3:0]; assign slli[3][2:0] = 0;
	assign slli[4][31: 4] = in1[31 - 4:0]; assign slli[4][3:0] = 0;
	assign slli[5][31: 5] = in1[31 - 5:0]; assign slli[5][4:0] = 0;
	assign slli[6][31: 6] = in1[31 - 6:0]; assign slli[6][5:0] = 0;
	assign slli[7][31: 7] = in1[31 - 7:0]; assign slli[7][6:0] = 0;
	assign slli[8][31: 8] = in1[31 - 8:0]; assign slli[8][7:0] = 0;
	assign slli[9][31: 9] = in1[31 - 9:0]; assign slli[9][8:0] = 0;
	assign slli[10][31: 10] = in1[31 - 10:0]; assign slli[10][9:0] = 0;
	assign slli[11][31: 11] = in1[31 - 11:0]; assign slli[11][10:0] = 0;
	assign slli[12][31: 12] = in1[31 - 12:0]; assign slli[12][11:0] = 0;
	assign slli[13][31: 13] = in1[31 - 13:0]; assign slli[13][12:0] = 0;
	assign slli[14][31: 14] = in1[31 - 14:0]; assign slli[14][13:0] = 0;
	assign slli[15][31: 15] = in1[31 - 15:0]; assign slli[15][14:0] = 0;
	assign slli[16][31: 16] = in1[31 - 16:0]; assign slli[16][15:0] = 0;
	assign slli[17][31: 17] = in1[31 - 17:0]; assign slli[17][16:0] = 0;
	assign slli[18][31: 18] = in1[31 - 18:0]; assign slli[18][17:0] = 0;
	assign slli[19][31: 19] = in1[31 - 19:0]; assign slli[19][18:0] = 0;
	assign slli[20][31: 20] = in1[31 - 20:0]; assign slli[20][19:0] = 0;
	assign slli[21][31: 21] = in1[31 - 21:0]; assign slli[21][20:0] = 0;
	assign slli[22][31: 22] = in1[31 - 22:0]; assign slli[22][21:0] = 0;
	assign slli[23][31: 23] = in1[31 - 23:0]; assign slli[23][22:0] = 0;
	assign slli[24][31: 24] = in1[31 - 24:0]; assign slli[24][23:0] = 0;
	assign slli[25][31: 25] = in1[31 - 25:0]; assign slli[25][24:0] = 0;
	assign slli[26][31: 26] = in1[31 - 26:0]; assign slli[26][25:0] = 0;
	assign slli[27][31: 27] = in1[31 - 27:0]; assign slli[27][26:0] = 0;
	assign slli[28][31: 28] = in1[31 - 28:0]; assign slli[28][27:0] = 0;
	assign slli[29][31: 29] = in1[31 - 29:0]; assign slli[29][28:0] = 0;
	assign slli[30][31: 30] = in1[31 - 30:0]; assign slli[30][29:0] = 0;
	assign slli[31][31: 31] = in1[31 - 31:0]; assign slli[31][30:0] = 0;
	
endmodule

