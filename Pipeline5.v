
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2024 07:00:17
// Design Name: 
// Module Name: pipeline5
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 5-stage pipelined RISC-V processor implementation
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Pipeline5(clk1, clk2);  // Pipeline module with two clock phases

input clk1, clk2;  // Two-phase clock for pipeline stages

// Define pipeline registers and control signals
reg [31:0] PC, IF_ID_IR, IF_ID_NPC;  // Program Counter and IF/ID stage registers
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;  // ID/EX stage registers
reg [2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;  // Pipeline control signal types
reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;  // EX/MEM stage registers
reg EX_MEM_cond;  // Condition for branching in EX stage
reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;  // MEM/WB stage registers

// Define register file and memory
reg [31:0] REG[0:31];  // Register bank with 32 registers
reg [31:0] MEM[0:1024];  // Memory array with 1024 locations

// Define opcodes for various instructions
parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011, 
          SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111, 
          LW = 6'b001000, SW = 6'b001001, ADDI = 6'b001010, SUBI = 6'b001011, 
          SLTI = 6'b001100, BNEQZ = 6'b001101, BEQZ = 6'b001110;

// Define instruction types for pipeline stages
parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, 
          BRANCH = 3'b100, HALT = 3'b101;

// Control flags for halting and branch management
reg HALTED;  // Stops execution after HALT
reg TAKEN_BRANCH;  // Indicates a branch was taken

// Instruction Fetch (IF) Stage: Fetches instructions and increments PC
always @(posedge clk1) begin
    if (!HALTED) begin
        // Check if a branch condition is met
        if (((EX_MEM_IR[31:26] == BEQZ) && EX_MEM_cond) || 
            ((EX_MEM_IR[31:26] == BNEQZ) && !EX_MEM_cond)) begin
            IF_ID_IR <= #2 MEM[EX_MEM_ALUOut];  // Load instruction from branch target
            TAKEN_BRANCH <= #2 1'b1;            // Indicate branch taken
            IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;  // Set next PC value
            PC <= #2 EX_MEM_ALUOut + 1;         // Update PC to branch address
        end else begin
            IF_ID_IR <= #2 MEM[PC];             // Load instruction from current PC
            IF_ID_NPC <= #2 PC + 1;             // Set next PC value
            PC <= #2 PC + 1;                    // Increment PC for next instruction
        end
    end
end

// Instruction Decode (ID) Stage: Decodes the instruction and reads registers
always @(posedge clk2) begin
    if (!HALTED) begin
        ID_EX_A <= #2 (IF_ID_IR[25:21] == 5'b00000) ? 32'b0 : REG[IF_ID_IR[25:21]];  // Read register A
        ID_EX_B <= #2 (IF_ID_IR[20:16] == 5'b00000) ? 32'b0 : REG[IF_ID_IR[20:16]];  // Read register B
        ID_EX_NPC <= #2 IF_ID_NPC;             // Propagate next PC
        ID_EX_IR <= #2 IF_ID_IR;               // Propagate instruction
        ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};  // Sign-extend immediate

        // Determine instruction type based on opcode
        case (IF_ID_IR[31:26])
            ADD, SUB, MUL, AND, OR, SLT: ID_EX_TYPE <= #2 RR_ALU;   // Register-register ALU
            ADDI, SUBI, SLTI: ID_EX_TYPE <= #2 RM_ALU;               // Register-immediate ALU
            LW: ID_EX_TYPE <= #2 LOAD;                               // Load
            SW: ID_EX_TYPE <= #2 STORE;                              // Store
            BNEQZ, BEQZ: ID_EX_TYPE <= #2 BRANCH;                    // Branch
            HLT: ID_EX_TYPE <= #2 HALT;                              // Halt
            default: ID_EX_TYPE <= #2 HALT;                          // Default to halt for invalid opcode
        endcase
    end
end

// Execute (EX) Stage: Performs ALU operations or calculates branch target
always @(posedge clk1) begin
    if (!HALTED) begin
        EX_MEM_TYPE <= #2 ID_EX_TYPE;        // Pass instruction type to next stage
        EX_MEM_IR <= #2 ID_EX_IR;            // Pass instruction to next stage
        TAKEN_BRANCH <= #2 0;                // Reset branch flag

        case (ID_EX_TYPE)
            // Perform register-register ALU operations
            RR_ALU: begin
                case (ID_EX_IR[31:26])
                    ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
                    SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
                    AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
                    OR: EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
                    SLT: EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_B);
                    MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
                    default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;  // Undefined behavior
                endcase
            end
            // Perform register-immediate ALU operations
            RM_ALU: begin
                case (ID_EX_IR[31:26])
                    ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                    SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
                    SLTI: EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_Imm);
                    default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;  // Undefined behavior
                endcase
            end
            // Calculate memory address for load/store
            LOAD, STORE: begin
                EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;  // Base address + offset
                EX_MEM_B <= #2 ID_EX_B;                   // Register value for store
            end
            // Calculate branch target and evaluate branch condition
            BRANCH: begin
                EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;  // Branch target address
                EX_MEM_cond <= #2 (ID_EX_A == 0);           // Evaluate branch condition
            end
        endcase
    end
end

// Memory Access (MEM) Stage: Accesses memory for load/store operations
always @(posedge clk2) begin
    if (!HALTED) begin
        MEM_WB_TYPE <= #2 EX_MEM_TYPE;        // Pass instruction type to next stage
        MEM_WB_IR <= #2 EX_MEM_IR;            // Pass instruction to next stage
        case (EX_MEM_TYPE)
            RR_ALU, RM_ALU: MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;   // Pass ALU result
            LOAD: MEM_WB_LMD <= #2 MEM[EX_MEM_ALUOut];           // Load data from memory
            STORE: if (!TAKEN_BRANCH) MEM[EX_MEM_ALUOut] <= #2 EX_MEM_B;  // Store data to memory
        endcase
    end
end

// Write Back (WB) Stage: Writes results back to registers
always @(posedge clk1) begin
    if (TAKEN_BRANCH == 0) begin  // Prevent further writes if branch was taken
        case (MEM_WB_TYPE)
            RR_ALU: 
                REG[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut;  // Write ALU result to destination register

            RM_ALU: 
                REG[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut;  // Write immediate result to destination register

            LOAD: 
                REG[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;     // Write loaded data to register

            HALT: 
                HALTED <= #2 1'b1;  // Set halt flag to stop further execution
        endcase
    end
end

endmodule
