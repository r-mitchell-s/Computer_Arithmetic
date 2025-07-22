module booth_multiplier_32bit (
    input  logic clk,
    input  logic reset,
    input  logic start_i,
    output logic done_o,
    input  logic [31:0] op_a_i,
    input  logic [31:0] op_b_i,
    output logic [63:0] result_o
);

    // internal signal declarations
    logic [5:0] counter;
    logic [31:0] M;
    logic [31:0] A, A_add, A_sub;
    logic [32:0] Q;

    // state enumeration
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        DONE
    } state_t;

    // state register declaration
    logic [1:0] state, next_state;

    // state transition and reset handling
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // next_state selection logic
    always_comb begin
        case (state)
            
            // wait on start signal for transition into COMPUTE
            IDLE: next_state = start_i ? COMPUTE : IDLE;

            // wait to complete the 32 rounds
            COMPUTE: next_state = (counter == 6'd31) ? DONE : COMPUTE;

            // just transition back to IDLE
            DONE: next_state = IDLE;

        endcase
    end

    // prepare the add and subtract case values
    assign A_add = A + M;
    assign A_sub = A - M;

    // sequential block to handle registers in each state
    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= '0;
            A       <= '0;
            Q       <= '0;
            M       <= '0;
        end else begin
            case (state)

                // load the operand registers
                IDLE: begin
                    M <= op_a_i;
                    Q <= {op_b_i, 1'b0};
                    A <= '0;
                    counter <= '0;
                end

                // 32 rounds of add/sub and shifting based on lowest Q-bits
                COMPUTE: begin
                    case (Q[1:0])

                        2'b00: begin
                            {A, Q} <= $signed({A, Q}) >>> 1;
                        end
                        2'b01: begin
                            {A, Q} <= $signed({A_add, Q}) >>> 1;
                        end
                        2'b10: begin
                            {A, Q} <= $signed({A_sub, Q}) >>> 1;
                        end
                        2'b11: begin
                            {A, Q} <= $signed({A, Q}) >>> 1;
                        end
                    endcase 

                    // increment the count
                    counter <= counter + 1;
                end
            endcase
        end
    end

    // final output assignments
    assign done_o = (state == DONE);
    assign result_o = (state == DONE) ? {A, Q[32:1]} : '0;

endmodule

module tb_booth_multiplier_32bit;

    // signal declarations
    logic clk = 0;
    logic reset;
    logic start_i;
    logic done_o;
    logic [31:0] op_a_i;
    logic [31:0] op_b_i;
    logic [63:0] result_o;

    // DUT instance
    booth_multiplier_32bit DUT(.clk(clk), .reset(reset), .start_i(start_i), .done_o(done_o), .op_a_i(op_a_i), .op_b_i(op_b_i), .result_o(result_o));

    // clk gen
    always #5 clk = ~clk;

    // dumpfile
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_booth_multiplier_32bit);
    end

    // stimulus gen
    initial begin

        // reset sequence
        reset = 1;
        op_a_i = 0;
        op_b_i = 0;
        start_i = 0;

        // first stimulus
        repeat(2) @(posedge clk);
        reset = 0;
        op_a_i = 32'd4;
        op_b_i = 32'd6;
        start_i = 1;

        repeat(34) @(posedge clk);
        op_a_i = 32'd8;
        op_b_i = 32'd6;

        repeat(34) @(posedge clk);
        op_a_i = -32'd8;
        op_b_i = 32'd6;

        repeat(36) @(posedge clk);
        $finish();
    end
endmodule