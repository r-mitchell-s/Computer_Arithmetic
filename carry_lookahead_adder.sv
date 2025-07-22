module full_adder (
    input  logic a_i,
    input  logic b_i, 
    input  logic carry_i,
    output logic carry_o,
    output logic sum_o
);

    // combinatorial output logic assignments, save the carry
    assign carry_o = (a_i & b_i) | (a_i & carry_i) | (b_i & carry_i);
    assign sum_o   = a_i ^ b_i ^ carry_i;

endmodule


module carry_lookahead_adder_4bit (
    input  logic [3:0] a_i,
    input  logic [3:0] b_i, 
    input  logic carry_i,
    output logic [3:0] result_o,
    output logic carry_o
);

    // declare the generate and propagate signals
    logic [3:0] G, P;

    // carry signal produced as a result of GP logic
    logic [3:0] C;

    // carry_in logic
    assign C[0] = carry_i;
    assign G = a_i & b_i;
    assign P = a_i ^ b_i;
    assign result_o[0] = P[0] ^ C[0];

    // G and P logic for intermediate FAs
    genvar i;
    generate
        for (i = 1; i < 4; i++) begin
            assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
            assign result_o[i] = P[i] ^ C[i];
        end
    endgenerate

    // output asssignments
    assign carry_o = C[3];

endmodule

module carry_lookahead_adder_32bit (
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,
    output logic [31:0] result_o,
    output logic        overflow_o
);

    // for carry-ins to 4-bit blocks
    logic [7:0] carry_bits;

    // first 4-bit module in the chain
    carry_lookahead_adder_4bit CLA0(.a_i(op_a_i[3:0]). .b_i(op_b_i[3:0]), .carry_i(1'b0), .result_o(result_o[3:0]), .carry_o(carry_bits[0]));

    // generate the next 7 modules
    genvar i;
    generate
        for (i = 1; i < 8; i++) begin
            carry_lookahead_adder_4bit CLAi(.a_i(op_a_i[4 * (i + 1) - 1 : 4 * i]), .b_i(op_b_i[4 * (i + 1) - 1 : 4 * i]), .carry_i(carry_bits[i - 1]), .result_o(result_o[4 * (i + 1) - 1 : 4 * i]), .carry_o(carry_bits[i]));
        end
    endgenerate

    // overflow is based on final carry
    assign overflow_o = carry_bits[7];

endmodule
