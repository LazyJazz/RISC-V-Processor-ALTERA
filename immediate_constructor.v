module immediate_constructor(input [31:0] inst, output [31:0] imm32);
	wire [31:0] Iimm;
	wire [31:0] Simm;
	wire [31:0] Bimm;
	wire [31:0] Uimm;
	wire [31:0] Jimm;
	wire Itype;
	wire Stype;
	wire Btype;
	wire Utype;
	wire Jtype;
	
	assign Itype = (inst[6:0] == 7'b0010011) ||
						(inst[6:0] == 7'b0000011) ||
						(inst[6:0] == 7'b1100111);
	assign Stype = (inst[6:0] == 7'b0100011);
	assign Btype = (inst[6:0] == 7'b1100011);
	assign Utype = (inst[6:0] == 7'b0010111) ||
						(inst[6:0] == 7'b0110111);
	assign Jtype = (inst[6:0] == 7'b1101111);
	
	assign Iimm[10:0] = inst[30:20];
	assign Iimm[31:11] = inst[31] ? 21'b111111111111111111111 : 21'b000000000000000000000;
	
	assign Simm[4:0] = inst[11:7];
	assign Simm[10:5] = inst[30:25];
	assign Simm[31:11] = Iimm[31:11];
	
	assign Bimm[0] = 0;
	assign Bimm[4:1] = inst[11:8];
	assign Bimm[10:5] = inst[30:25];
	assign Bimm[11] = inst[7];
	assign Bimm[31:12] = Iimm[31:12];
	
	assign Uimm[11:0] = 0;
	assign Uimm[31:12] = inst[31:12];
	
	assign Jimm[0] = 0;
	assign Jimm[10:1] = inst[30:21];
	assign Jimm[11] = inst[20];
	assign Jimm[19:12] = inst[19:12];
	assign Jimm[31:20] = Iimm[31:20];
	
	assign imm32 = Itype ? Iimm : (
		Stype ? Simm: (
		Btype ? Bimm: (
		Utype ? Uimm: (
		Jtype ? Jimm: 0
	)
	)
	)
	);
endmodule
