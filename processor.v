/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
);
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;

    /* YOUR CODE STARTS HERE */
	 wire [31:0] pc_q, pc_next, pc_inc1;
wire [31:0] one32;
assign one32 = 32'd1;

genvar pi;
generate
  for (pi=0; pi<32; pi=pi+1) begin: pc_bits
    dffe pcff(pc_q[pi], pc_next[pi], clock, 1'b1, reset);
  end
endgenerate

wire [31:0] alu_pc_res;
wire alu_pc_neq, alu_pc_lt, alu_pc_ovf;
alu alu_pc(
  .data_operandA(pc_q),
  .data_operandB(one32),
  .ctrl_ALUopcode(5'b00000),
  .ctrl_shiftamt(5'b00000),
  .data_result(alu_pc_res),
  .isNotEqual(alu_pc_neq),
  .isLessThan(alu_pc_lt),
  .overflow(alu_pc_ovf)
);
assign pc_next = alu_pc_res;
assign address_imem = pc_q[11:0];

wire [31:0] instr;
assign instr = q_imem;

wire [4:0] opcode, rd, rs, rt, shamt, funct;
wire [16:0] imm17;
assign opcode = instr[31:27];
assign rd     = instr[26:22];
assign rs     = instr[21:17];
assign rt     = instr[16:12];
assign shamt  = instr[11:7];
assign funct  = instr[6:2];
assign imm17  = instr[16:0];

wire op4,op3,op2,op1,op0;
assign op4=opcode[4]; assign op3=opcode[3]; assign op2=opcode[2]; assign op1=opcode[1]; assign op0=opcode[0];

wire is_rtype, is_addi, is_sw, is_lw;
assign is_rtype = (~op4)&(~op3)&(~op2)&(~op1)&(~op0);
assign is_addi  = (~op4)&(~op3)&( op2)&( op1)&(~op0);
assign is_sw    = (~op4)&(~op3)&( op2)&( op1)&( op0);
assign is_lw    = (~op4)&( op3)&(~op2)&(~op1)&(~op0);

wire [31:0] imm32;
wire imm_sign;
assign imm_sign = imm17[16];
assign imm32 = { {15{imm_sign}}, imm17 };

assign ctrl_readRegA = rs;
assign ctrl_readRegB = is_sw ? rd : rt;

wire f4,f3,f2,f1,f0;
assign f4=funct[4]; assign f3=funct[3]; assign f2=funct[2]; assign f1=funct[1]; assign f0=funct[0];

wire is_add_r, is_sub_r, is_and_r, is_or_r, is_sll_r, is_sra_r;
assign is_add_r = is_rtype & (~f4)&(~f3)&(~f2)&(~f1)&(~f0);
assign is_sub_r = is_rtype & (~f4)&(~f3)&(~f2)&(~f1)&( f0);
assign is_and_r = is_rtype & (~f4)&(~f3)&( f2)&(~f1)&(~f0);
assign is_or_r  = is_rtype & (~f4)&(~f3)&( f2)&(~f1)&( f0);
assign is_sll_r = is_rtype & (~f4)&(~f3)&( f2)&( f1)&(~f0);
assign is_sra_r = is_rtype & (~f4)&(~f3)&( f2)&( f1)&( f0);

wire [31:0] opA, opB;
assign opA = data_readRegA;
assign opB = (is_addi | is_lw | is_sw) ? imm32 : data_readRegB;

wire [4:0] alu_sel_add, alu_sel_sub, alu_sel_and, alu_sel_or, alu_sel_sll, alu_sel_sra;
assign alu_sel_add = 5'b00000;
assign alu_sel_sub = 5'b00001;
assign alu_sel_and = 5'b00010;
assign alu_sel_or  = 5'b00011;
assign alu_sel_sll = 5'b00100;
assign alu_sel_sra = 5'b00101;

wire [4:0] alu_ctrl_r;
assign alu_ctrl_r =
    ({5{is_add_r}} & alu_sel_add) |
    ({5{is_sub_r}} & alu_sel_sub) |
    ({5{is_and_r}} & alu_sel_and) |
    ({5{is_or_r }} & alu_sel_or ) |
    ({5{is_sll_r}} & alu_sel_sll) |
    ({5{is_sra_r}} & alu_sel_sra);

wire [4:0] alu_ctrl;
assign alu_ctrl = is_rtype ? alu_ctrl_r : 5'b00000;

wire [4:0] shift_amt;
assign shift_amt = shamt;

wire [31:0] alu_result;
wire alu_neq, alu_lt, alu_ovf;
alu u_alu(
  .data_operandA(opA),
  .data_operandB(opB),
  .ctrl_ALUopcode(alu_ctrl),
  .ctrl_shiftamt(shift_amt),
  .data_result(alu_result),
  .isNotEqual(alu_neq),
  .isLessThan(alu_lt),
  .overflow(alu_ovf)
);

assign address_dmem = alu_result[11:0];
assign data = data_readRegB;
assign wren = is_sw & ~reset;


wire wr_from_lw, wr_from_alu;
assign wr_from_lw  = is_lw;
assign wr_from_alu = is_rtype | is_addi;

wire [31:0] wb_pre;
assign wb_pre = wr_from_lw ? q_dmem : alu_result;

wire is_addi_ovf, is_add_r_ovf, is_sub_r_ovf;
assign is_addi_ovf = is_addi & alu_ovf;
assign is_add_r_ovf= is_add_r & alu_ovf;
assign is_sub_r_ovf= is_sub_r & alu_ovf;

wire write_rstatus;
assign write_rstatus = is_addi_ovf | is_add_r_ovf | is_sub_r_ovf;

wire [31:0] rstatus_value;
assign rstatus_value =
    ({32{is_add_r_ovf}} & 32'd1) |
    ({32{is_addi_ovf}} & 32'd2) |
    ({32{is_sub_r_ovf}} & 32'd3);

wire [4:0] wb_reg_normal, wb_reg_final;
assign wb_reg_normal = rd;
assign wb_reg_final = write_rstatus ? 5'd30 : wb_reg_normal;

wire [31:0] wb_data_final;
assign wb_data_final = write_rstatus ? rstatus_value : wb_pre;

wire rd_is_zero;
assign rd_is_zero = ~( |wb_reg_final );

wire will_write_normal;
assign will_write_normal = wr_from_lw | wr_from_alu;

assign ctrl_writeEnable = will_write_normal & (~rd_is_zero) & ~reset;
assign ctrl_writeReg    = wb_reg_final;
assign data_writeReg    = wb_data_final;


endmodule