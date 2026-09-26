module adder_behavioral_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout
);
    wire [32:0] full_sum;
    assign full_sum = {1'b0, a} + {1'b0, b} + cin;
    assign sum      = full_sum[31:0];
    assign cout     = full_sum[32];
endmodule
