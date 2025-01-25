
`timescale 1ns / 1ps
`include "Pipeline5.v"

module simple_testbench;
    // Clock signals
    reg clk1, clk2;

    // Pipeline registers
    reg [31:0] PC, IF_ID_IR, IF_ID_NPC;  // Program Counter and IF/ID stage registers
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;  // ID/EX stage registers
    reg [2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;  // Pipeline control signal types
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;  // EX/MEM stage registers
    reg EX_MEM_cond;  // Condition for branching in EX stage
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;  // MEM/WB stage registers
    
    // Initialize the signals
    initial begin
        // Initial clock values
        clk1 = 0;
        clk2 = 0;

        // Initialize pipeline registers with arbitrary values for visibility in waveform
        PC = 32'h00000000;
        IF_ID_IR = 32'h280a00c8;
        IF_ID_NPC = 32'h00000004;
        ID_EX_IR = 32'h28020001;
        ID_EX_NPC = 32'h00000008;
        ID_EX_A = 32'h00000001;
        ID_EX_B = 32'h00000002;
        ID_EX_Imm = 32'h00000003;
        EX_MEM_IR = 32'h0e94a000;
        EX_MEM_ALUOut = 32'h00000003;
        EX_MEM_B = 32'h00000020;
        EX_MEM_cond = 1'b0;
        MEM_WB_IR = 32'h3460fffc;
        MEM_WB_ALUOut = 32'h00000030;
        MEM_WB_LMD = 32'h00000040;
        ID_EX_TYPE = 3'b000;
        EX_MEM_TYPE = 3'b001;
        MEM_WB_TYPE = 3'b010;


        // Start VCD file dump
        $dumpfile("simple_pipeline_waveform.vcd");
        $dumpvars(0, clk1, clk2, PC, IF_ID_IR, IF_ID_NPC, 
                  ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm, 
                  EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B, EX_MEM_cond, 
                  MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD, 
                  ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE);

       // Change the values to simulate pipeline flow
#10 PC = 32'h00000004;          // PC increments by 4
#10 IF_ID_IR = 32'h28020001;    // Instruction (e.g., ADDI, adding immediate to register)
#10 IF_ID_NPC = 32'h00000008;   // Next PC value is 0x00000008
#10 ID_EX_IR = 32'h0e94a000;    // Example instruction (SUB or ADD, based on your pipeline logic)
#10 ID_EX_NPC = 32'h0000000C;   // Next PC value after execution of this instruction
#10 ID_EX_A = 32'h00000010;     // Operand A (0x10, 16 in decimal)
#10 ID_EX_B = 32'h00000020;     // Operand B (0x20, 32 in decimal)
#10 ID_EX_Imm = 32'h00000030;   // Immediate value for the operation (0x30, 48 in decimal)
#10 EX_MEM_IR = 32'h3460fffc;   // Executed instruction in EX stage (e.g., ADD or SUB)
#10 EX_MEM_ALUOut = 32'h00000030; // ALU Output after executing ADD: 0x10 + 0x20 = 0x30
#10 EX_MEM_B = 32'h00000040;    // Operand B passed to MEM stage (0x40, 64 in decimal)
#10 EX_MEM_cond = 1'b1;        // Branch condition satisfied (for example, a jump or branch)
#10 MEM_WB_IR = 32'h2542fffe;  // Instruction passed to MEM stage (could be a STORE)
#10 MEM_WB_ALUOut = 32'h00000070; // Final ALU result (after store address calculation)
#10 MEM_WB_LMD = 32'h00000080;  // Loaded data (e.g., value from memory, here it's 0x80)

        // Finish simulation after a while
        #100 $finish;
    end

    // Generate clock signals with a period of 10 time units for each phase
    always #5 clk1 = ~clk1; // Toggle clk1 every 5 time units
    always #5 clk2 = ~clk2; // Toggle clk2 every 5 time units

endmodule
