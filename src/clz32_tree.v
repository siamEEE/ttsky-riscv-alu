module clz32_tree (
    input  wire [31:0] data,
    output reg  [5:0]  count
);
    reg [31:0] shifted;

    always @(*) begin
        if (data == 32'b0) begin
            count   = 6'd32;
            shifted = 32'b0;
        end else begin
            count   = 6'd0;
            shifted = data;

            if (shifted[31:16] == 16'b0) begin
                count   = count + 6'd16;
                shifted = shifted << 16;
            end
            if (shifted[31:24] == 8'b0) begin
                count   = count + 6'd8;
                shifted = shifted << 8;
            end
            if (shifted[31:28] == 4'b0) begin
                count   = count + 6'd4;
                shifted = shifted << 4;
            end
            if (shifted[31:30] == 2'b0) begin
                count   = count + 6'd2;
                shifted = shifted << 2;
            end
            if (shifted[31] == 1'b0)
                count = count + 6'd1;
        end
    end
endmodule
