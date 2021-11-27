module ascii_to_digit(input [7:0] ascii, output [6:0] digit);
	assign digit = (ascii == 48) ? 7'b1111110 : (
						(ascii == 49) ? 7'b0110000 : (
						(ascii == 50) ? 7'b1101101 : (
						(ascii == 51) ? 7'b1111001 : (
						(ascii == 52) ? 7'b0110011 : (
						(ascii == 53) ? 7'b1011011 : (
						(ascii == 54) ? 7'b1011111 : (
						(ascii == 55) ? 7'b1110000 : (
						(ascii == 56) ? 7'b1111111 : (
						(ascii == 57) ? 7'b1111011 : (
						(ascii == 0) ? 7'b0000000 : (
						(ascii == 45) ? 7'b0000001 :(
						(ascii == 65) ? 7'b1110111 : ( //A
						(ascii == 66) ? 7'b0011111 : ( //B
						(ascii == 67) ? 7'b1001110 : ( //C
						(ascii == 68) ? 7'b0111101 : ( //D
						(ascii == 69) ? 7'b1001111 : ( //E
						(ascii == 70) ? 7'b1000111 : ( //F
						(ascii == 114) ? 7'b0000101 :( //r
						(ascii == 111) ? 7'b0011101 :  7'b0000000)))))))))))))))))));//o
endmodule


module output_int32_ascii(input clk, input [31:0] value, input error, input div, output [7: 0] digit_channel, output [3:0] cs_out);
	wire [7:0] c0;
	wire [7:0] c1;
	wire [7:0] c2;
	wire [7:0] c3;
	wire [7:0] oc;
	wire [31: 0] v0;
	wire [31: 0] v1;
	wire [31: 0] v2;
	wire [31: 0] v3;
	wire [3: 0] d0;
	wire [3: 0] d1;
	wire [3: 0] d2;
	wire [3: 0] d3;
	reg [3:0]control;
	reg [31:0] clk_cnt;
	wire [31:0] clk_cnt_new;
	wire [3:0]control_new;
	assign v0 = div ? ((value > 9999) ? (value / 10) : value) : (value[31] ? ($unsigned(~value) + 1) : value);
	assign v1 = v0 / 10;
	assign v2 = v0 / 100;
	assign v3 = v0 / 1000;
	assign d0 = v0 - v1 * 10;
	assign d1 = v1 - v2 * 10;
	assign d2 = v2 - v3 * 10;
	assign d3 = v3 % 10;
	assign c0 = d0 + 48;
	assign c1 = error ? 114 : ((d1 || d2 || d3 || div) ? d1 + 48 : 0);
	assign c2 = error ? 114 : ((d2 || d3 || div) ? d2 + 48 : 0);
	assign c3 = error ? 69 : ((d3 || div) ? (d3 + 48) : (value[31] ? 45 :  0));
	assign cs_out = ~control;
	assign digit_channel[0] = div && ((value > 9999) ? control[2] : control[3]) && !error;
	assign oc = control[0] ? c0 : (
					control[1] ? c1 : (
					control[2] ? c2 : c3));
	ascii_to_digit(oc, digit_channel[7:1]);
	
	assign control_new =
							control[0] ? 4'b0010 : (
							control[1] ? 4'b0100 : (
							control[2] ? 4'b1000 : 4'b0001));
	assign clk_cnt_new = $unsigned(clk_cnt) + 1;
	always @ (posedge clk)
	begin
		
		if (clk_cnt >= 10000)
		begin
			control <= control_new;
			clk_cnt <= 0;
		end
		else
			clk_cnt <= clk_cnt_new;
	end
endmodule

module output_hex_ascii(input clk, input [31:0] value, output [7: 0] digit_channel, output [3:0] cs_out);
	wire [7:0] c0;
	wire [7:0] c1;
	wire [7:0] c2;
	wire [7:0] c3;
	wire [7:0] oc;
	wire [3: 0] d0;
	wire [3: 0] d1;
	wire [3: 0] d2;
	wire [3: 0] d3;
	reg [3:0]control;
	reg [31:0] clk_cnt;
	wire [31:0] clk_cnt_new;
	wire [3:0]control_new;
	assign d0 = value[3:0];
	assign d1 = value[7:4];
	assign d2 = value[11:8];
	assign d3 = value[15:12];
	assign c0 = (d0 < 10) ? (d0 + 48) : (d0+55);
	assign c1 = (d1 < 10) ? (d1 + 48) : (d1+55);
	assign c2 = (d2 < 10) ? (d2 + 48) : (d2+55);
	assign c3 = (d3 < 10) ? (d3 + 48) : (d3+55);
	assign cs_out = ~control;
	assign digit_channel[0] = 0;
	assign oc = control[0] ? c0 : (
					control[1] ? c1 : (
					control[2] ? c2 : c3));
	ascii_to_digit(oc, digit_channel[7:1]);
	
	assign control_new =
							control[0] ? 4'b0010 : (
							control[1] ? 4'b0100 : (
							control[2] ? 4'b1000 : 4'b0001));
	assign clk_cnt_new = $unsigned(clk_cnt) + 1;
	always @ (posedge clk)
	begin
		
		if (clk_cnt >= 10000)
		begin
			control <= control_new;
			clk_cnt <= 0;
		end
		else
			clk_cnt <= clk_cnt_new;
	end
endmodule

module pc_reg(input cpu_clk, input stall, input [31:0] new_pc, output [31:0] pc, input rst);
	
	reg [31:0] pcnter;
	assign pc = pcnter;
	
	always @ (posedge cpu_clk)
	begin
		if (!stall && !rst)
			pcnter <= new_pc;
		else if (rst)
			pcnter <= 32'h00003ff8;
	end
endmodule

module sig_translate(
	input [31:0] inst,
	output sig_load,
	output sig_store,
	output sig_jump,
	output sig_branch,
	output sig_wb,
	output Itype,
	output Stype,
	output Btype,
	output Utype,
	output Jtype,
	output Rtype);
	
	
	assign Itype = (inst[6:0] == 7'b0010011) ||
						(inst[6:0] == 7'b0000011) ||
						(inst[6:0] == 7'b1100111);
	assign Stype = (inst[6:0] == 7'b0100011);
	assign Btype = (inst[6:0] == 7'b1100011);
	assign Utype = (inst[6:0] == 7'b0010111) ||
						(inst[6:0] == 7'b0110111);
	assign Jtype = (inst[6:0] == 7'b1101111);
	assign Rtype = (inst[6:0] == 7'b0110011);
	
	assign sig_load = (inst[6:0] == 7'b0000011);
	assign sig_store = (inst[6:0] == 7'b0100011);
	assign sig_jump = (inst[6:0] == 7'b1101111) || (inst[6:0] == 7'b1100111);
	assign sig_branch = (inst[6:0] == 7'b1100011);
	assign sig_wb = Rtype || Itype || Utype || Jtype;
endmodule 

module RISC_V_Processor(switch_in, button_in, led_out, cs_out, decimal_out, digit_out,clk);
	output [7: 0] digit_out;
	output [3: 0] decimal_out;
	output [9: 0] led_out;
	output [3: 0] cs_out;
	input [7: 0] switch_in;
	input [3: 0] button_in;
	wire [31:0] __rubish;
	input clk;
	//register
	//	reg0(button_in[3], 0, switch_in[4:0], switch_in[4:0], switch_in[4:0], switch_in, button_in[2], led_out, __rubish);
/****Define CPU Clock Speed****/
	reg [31:0] clock32;
	wire [31:0] clock32_new;
	wire cpu_clk;
	assign clock32_new = clock32 + 1;
	assign cpu_clk = clock32[0];
/******************************/
	reg [15:0] state; // 0: IF 1:ID 2:EX 3:MEM 4:WB
	wire [15:0] new_state;

	wire rst;
	assign rst = (clock32 < 256);//button_in[0];
	wire is_end;
	
	reg init_bit;
	reg [31:0] led_word;
	
	
/******Mem Bus******/
	wire mem_load;
	wire mem_store;
	wire [2:0] mem_type;
	wire [31:0] mem_addr;
	wire [31:0] mem_data;
	wire [31:0] mem_out;
	wire mem_stall;
/*******************/
		
/***digit module***/
	wire[31:0] digit_write;
	output_hex_ascii
		out_number(clk, digit_write, digit_out, cs_out);
/******************/



/****PC Reg****/

	wire [31:0] pc_new;
	wire [31:0] pc;
	wire [31:0] pc_4;
	wire pc_stall;
	
	assign pc_stall = (state != 4);
	
	pc_reg
		pcreg0(cpu_clk, pc_stall, pc_new, pc, rst);
	assign pc_4 = pc + 4;

/**************/


/***********************IF Stage************************/

// This stage acquire actions on memory.
	reg [31:0] if_pc;
	reg [31:0] if_pc_4;


	always @ (posedge cpu_clk)
	begin
		if (state == 0)
		begin
			if_pc <= pc;
			if_pc_4 <= pc_4;
		end
	end
/*******************************************************/

/***********************ID Stage************************/

/*** Register Module ***/
	wire reg_stall;
	wire [4:0] reg_rs1;
	wire [4:0] reg_rs2;
	wire [4:0] reg_rd;
	wire [31:0] reg_wb;
	wire reg_sig_wb;
	wire [31:0] reg_r1;
	wire [31:0] reg_r2;
	
//	reg [31:0] xx[31:0];
//	assign reg_r1 = xx[reg_rs1];
//	assign reg_r2 = xx[reg_rs2];
	
	assign reg_stall = (state != 4);
	
	register
		reg0(cpu_clk, rst, reg_stall, reg_rs1, reg_rs2, reg_rd, reg_wb, reg_sig_wb, reg_r1, reg_r2);
		
/***********************/

	wire id_wire_sig_load;
	wire id_wire_sig_store;
	wire id_wire_sig_jump;
	wire id_wire_sig_branch;
	wire id_wire_sig_wb;
	reg id_sig_load;
	reg id_sig_store;
	reg id_sig_jump;
	reg id_sig_branch;
	reg id_sig_wb;
	wire id_wire_Itype;
	wire id_wire_Stype;
	wire id_wire_Btype;
	wire id_wire_Utype;
	wire id_wire_Jtype;
	wire id_wire_Rtype;
	reg id_Itype;
	reg id_Stype;
	reg id_Btype;
	reg id_Utype;
	reg id_Jtype;
	reg id_Rtype;
	wire [31:0] id_wire_inst;
	wire [31:0] id_wire_imm;
	wire [6:0] id_wire_opcode;
	wire [4:0] id_wire_rs1;
	wire [4:0] id_wire_rs2;
	wire [4:0] id_wire_rd;
	wire [31:0] id_wire_r1;
	wire [31:0] id_wire_r2;
	reg [31:0] id_reg_r1;
	reg [31:0] id_reg_r2;
	reg [4:0] id_rs1;
	reg [4:0] id_rs2;
	reg [4:0] id_rd;
	reg [31:0] id_inst;
	reg [31:0] id_imm;
	reg [31:0] id_pc;
	reg [31:0] id_pc_4;
	
	sig_translate
		st0(id_wire_inst, id_wire_sig_load, id_wire_sig_store, id_wire_sig_jump, id_wire_sig_branch, id_wire_sig_wb,
	id_wire_Itype,
	id_wire_Stype,
	id_wire_Btype,
	id_wire_Utype,
	id_wire_Jtype,
	id_wire_Rtype);
	
	assign id_wire_inst = mem_out;
	assign id_wire_opcode = id_wire_inst[6:0];
	assign id_wire_rd = id_wire_inst[11:7];
	assign id_wire_rs1 = id_wire_inst[19:15];
	assign id_wire_rs2 = id_wire_inst[24:20];
	assign reg_rs1 = id_wire_rs1;
	assign reg_rs2 = id_wire_rs2;
	assign id_wire_r1 = reg_r1;
	assign id_wire_r2 = reg_r2;

	
/***Immediate Decode***/
	immediate_constructor
		id_immc(id_wire_inst, id_wire_imm);
/**********************/


	always @ (posedge cpu_clk)
	begin
		if (state == 1)
		begin
			id_sig_load <= id_wire_sig_load;
			id_sig_store <= id_wire_sig_store;
			id_sig_jump <= id_wire_sig_jump;
			id_sig_branch <= id_wire_sig_branch;
			id_sig_wb <= id_wire_sig_wb;
			id_Itype <= id_wire_Itype;
			id_Stype <= id_wire_Stype;
			id_Btype <= id_wire_Btype;
			id_Utype <= id_wire_Utype;
			id_Jtype <= id_wire_Jtype;
			id_Rtype <= id_wire_Rtype;
			id_pc <= if_pc;
			id_pc_4 <= if_pc_4;
			id_rs1 <= id_wire_rs1;
			id_rs2 <= id_wire_rs2;
			id_rd <= id_wire_rd;
			id_reg_r1 <= id_wire_r1;
			id_reg_r2 <= id_wire_r2;
			id_inst <= id_wire_inst;
			id_imm <= id_wire_imm;
		end
	end
	
/*******************************************************/
	
/***********************EX Stage************************/
// Signal Decoding
	reg ex_sig_load;
	reg ex_sig_store;
	reg ex_sig_jump;
	reg ex_sig_branch;
	reg ex_sig_wb;
	reg ex_Itype;
	reg ex_Stype;
	reg ex_Btype;
	reg ex_Utype;
	reg ex_Jtype;
	reg ex_Rtype;
	
	reg [31:0] ex_pc;
	reg [31:0] ex_pc_4;
		
/***ALU Module***/
	wire [31:0] ex_wire_alu_in1;
	wire [31:0] ex_wire_alu_in2;
	wire [31:0] ex_wire_alu_res;
	reg [31:0] ex_alu_res;
	alu
		alu0(ex_wire_alu_in1, ex_wire_alu_in2, id_inst[6:0], id_inst[14:12], id_inst[31:25], ex_wire_alu_res);
/****************/
	reg [4:0] ex_rs1;
	reg [4:0] ex_rs2;
	reg [4:0] ex_rd;
	reg [31:0] ex_inst;
	reg [31:0] ex_imm;
	reg [31:0] ex_reg_r1;
	reg [31:0] ex_reg_r2;
	
	assign ex_wire_alu_in1 = id_reg_r1;
	assign ex_wire_alu_in2 = (
		(id_Btype || id_Rtype) ? id_reg_r2 :
		id_imm
	);
	
	always @ (posedge cpu_clk)
	begin
		if (state == 2)
		begin
			ex_sig_load <= id_sig_load;
			ex_sig_store <= id_sig_store;
			ex_sig_jump <= id_sig_jump;
			ex_sig_branch <= id_sig_branch;
			ex_sig_wb <= id_sig_wb;
			ex_Itype <= id_Itype;
			ex_Stype <= id_Stype;
			ex_Btype <= id_Btype;
			ex_Utype <= id_Utype;
			ex_Jtype <= id_Jtype;
			ex_Rtype <= id_Rtype;
			ex_alu_res <= ex_wire_alu_res;
			ex_imm <= id_imm;
			ex_inst <= id_inst;
			ex_rd <= id_rd;
			ex_rs1 <= id_rs1;
			ex_rs2 <= id_rs2;
			ex_reg_r1 <= id_reg_r1;
			ex_reg_r2 <= id_reg_r2;
			ex_pc <= id_pc;
			ex_pc_4 <= id_pc_4;
		end
	end
/*******************************************************/
	
/***********************MEM Stage************************/
// Memory Module
	memory
		mem0(cpu_clk, clk, 
		mem_load, //sig_load
		mem_store, //sig_store
		mem_type, //type
		mem_addr, //addr
		mem_data, //data
		mem_out, //mem read result
		mem_stall //is mem stall
		);
		
	assign mem_load = (
		(state <= 1) ? (
			1
		) : 
		(
			id_sig_load && !(mem_addr[31:14])
		)
	);
	
	assign mem_store = (id_sig_store && !(mem_addr[31:14]) && ((state == 3) || (state == 2)));
	
	assign mem_data = id_reg_r2;
	
	assign mem_addr = (
		(state <= 1) ? (
			pc
		) : 
		(
			id_reg_r1 + id_imm
		)
	);
	
	assign mem_type = (
		(state <= 1) ? 3'b010 : id_inst[14:12]
	);
	
	wire [6:0] mem_wire_opcode;
	wire [31:0] mem_wire_pc_new;
	wire [4:0] mem_wire_reg_rd;
	wire [31:0] mem_wire_reg_wb;
	wire mem_wire_reg_sig_wb;
	reg [31:0] mem_pc_new;
	reg [4:0] mem_reg_rd;
	reg [31:0] mem_reg_wb;
	reg mem_reg_sig_wb;
	
	assign mem_wire_opcode = ex_inst[6:0];
	assign mem_wire_pc_new = (
		ex_sig_jump ? (
			(ex_sig_jump && ex_Itype) ? 
			(ex_reg_r1 + ex_imm):
			(ex_pc + ex_imm)
		):
		(
		ex_sig_branch ? (
			ex_alu_res ? (ex_pc + ex_imm) : (ex_pc_4)
		) : ex_pc_4
		)
	);
	
	assign mem_wire_reg_sig_wb = ex_sig_wb;
	assign mem_wire_reg_rd = ex_inst[11:7];
	assign mem_wire_reg_wb = (
		(mem_wire_opcode == 7'b0110111) ? (ex_imm) : //LUI
		(
		(mem_wire_opcode == 7'b0010111) ? (ex_pc + ex_imm) : //AUIPC
		(
		(ex_sig_jump) ? (ex_pc_4) : //JAL return pc+4
		(
		(ex_sig_load) ? (mem_out) : // Load instructions
		(ex_wire_alu_res) // Rtype or Itype
		)
		)
		)
	);
	
	always @ (posedge cpu_clk)
	begin
		if (state == 3)
		begin
			mem_pc_new <= mem_wire_pc_new;
			mem_reg_rd <= mem_wire_reg_rd;
			mem_reg_wb <= mem_wire_reg_wb;
			mem_reg_sig_wb <= mem_wire_reg_sig_wb;
			if (mem_addr == 32'h00004000 && ex_sig_store)
			begin
				led_word <= mem_data;
			end
		end
	end
/*********************/

/*******************************************************/


/***********************WB Stage************************/
	assign reg_rd = mem_reg_rd;
	assign reg_wb = mem_reg_wb;
	assign reg_sig_wb = mem_reg_sig_wb;
	assign pc_new = mem_pc_new;
//	always @ (posedge cpu_clk)
//	begin
//		if (state == 4 && reg_sig_wb && reg_rd)
//		begin
//			xx[reg_rd] <= reg_wb;
//		end
//	end
/*******************************************************/


//	assign led_out[2:0] = state[2:0];
//	assign led_out[7:3] = mem_reg_rd;
//	assign led_out[8] = reg_sig_wb && (!reg_stall);
	assign led_out[7:0] = (
		switch_in[1] ?
		(switch_in[0] ? (led_word[31:24]) : (led_word[23:16])):
		(switch_in[0] ? (led_word[15:8]) : (led_word[7:0]))
	);
	assign led_out[9] = cpu_clk;

//	assign digit_write[7:0] = (
//	(switch_in[3:0] == 4'b0000) ? id_inst[7:0] : (
//	(switch_in[3:0] == 4'b0001) ? reg_r1[7:0] : (
//	(switch_in[3:0] == 4'b0010) ? reg_r2[7:0] : (
//	(switch_in[3:0] == 4'b0011) ? mem_reg_wb[7:0] : (
//	(switch_in[3:0] == 4'b0100) ? reg_rs1 : (
//	(switch_in[3:0] == 4'b0101) ? reg_rs2 : (
//	(switch_in[3:0] == 4'b0110) ? mem_reg_rd : (
//	(switch_in[3:0] == 4'b0111) ? pc :(
//	(switch_in[3:0] == 4'b1000) ? ex_wire_alu_in1 :(
//	(switch_in[3:0] == 4'b1001) ? ex_wire_alu_in2 :(
//	(switch_in[3:0] == 4'b1010) ? ex_alu_res :(
//	(switch_in[3:0] == 4'b1011) ? mem_addr :(
//	(switch_in[3:0] == 4'b1100) ? mem_data :(
//	(switch_in[3:0] == 4'b1101) ? mem_out :(
//	(switch_in[3:0] == 4'b1110) ? mem_wire_opcode :(
//	(switch_in[3:0] == 4'b1111) ? ex_imm : 0
//	))))))))))))))));
//	assign digit_write[15:8] = (
//	(switch_in[7:4] == 4'b0000) ? id_inst[7:0] : (
//	(switch_in[7:4] == 4'b0001) ? reg_r1[7:0] : (
//	(switch_in[7:4] == 4'b0010) ? reg_r2[7:0] : (
//	(switch_in[7:4] == 4'b0011) ? mem_reg_wb[7:0] : (
//	(switch_in[7:4] == 4'b0100) ? reg_rs1 : (
//	(switch_in[7:4] == 4'b0101) ? reg_rs2 : (
//	(switch_in[7:4] == 4'b0110) ? mem_reg_rd : (
//	(switch_in[7:4] == 4'b0111) ? pc :(
//	(switch_in[7:4] == 4'b1000) ? ex_wire_alu_in1 :(
//	(switch_in[7:4] == 4'b1001) ? ex_wire_alu_in2 :(
//	(switch_in[7:4] == 4'b1010) ? ex_alu_res :(
//	(switch_in[7:4] == 4'b1011) ? mem_addr :(
//	(switch_in[7:4] == 4'b1100) ? mem_data :(
//	(switch_in[7:4] == 4'b1101) ? mem_out :(
//	(switch_in[7:4] == 4'b1110) ? mem_wire_opcode :(
//	(switch_in[7:4] == 4'b1111) ? ex_imm : 0
//	))))))))))))))));
	assign digit_write[15:0] = (
	(switch_in == 0) ? led_word[15:0]: (
	(switch_in == 1) ? led_word[31:16]: (
	(switch_in == 2) ? pc: 0
	)
	
	));
	
	assign is_end = (pc == 32'b11111111111111111111111111111111);
	
//	assign led_out[1:0] = state;
//	assign led_out[2] = reg_sig_wb;
//	assign led_out[3] = (reg_buff_sig_wb && !reg_stall);
//	assign led_out[4] = sig_wb;
//	assign led_out[5] = sig_branch;
//	assign led_out[6] = sig_jump;
//	assign led_out[7] = sig_store;
//	assign led_out[8] = sig_load;
//	assign led_out[9] = cpu_clk;
//	assign led_out[6:0] = inst[6:0];
	
	
	
//	assign reg_rs1 = inst[19:5];
//	assign reg_rs2 = inst[24:20];
	
	
	always @ (posedge clk)
	begin
		if (button_in[0])
		begin
			clock32 <= 0;
		end
		else
		begin
			clock32[30:0] <= clock32_new[30:0];
			if (clock32 > 100)
			begin
				clock32[31] <= 1;
			end
		end
	end
	
	assign new_state = (state + 1) % 5;
	
	assign decimal_out = state;
	
	wire stage_stall;
	assign stage_stall = mem_stall;
	
	always @ (negedge cpu_clk)
	begin
		if (rst)
		begin
			state = 0;
		end
		else if (!is_end)
		begin
			if (!stage_stall)
				state <= new_state;
		end
	end
endmodule
