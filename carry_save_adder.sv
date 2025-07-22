module carry_save_adder (
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,
    input  logic [31:0] op_c_i,
    output logic [31:0] sum_o,
    output logic [31:0] carry_o
);

    // create output vectors from three inputs
    assign sum_o = op_a_i ^ op_b_i ^ op_c_i;
    assign carry_o = (op_a_i & op_b_i) | (op_a_i & op_c_i) | (op_b_i & op_c_i);

endmodule