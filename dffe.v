module dffe(
    q,
    d,
    clk,
    en,
    rst
);
    output reg q;
    input d, clk, en, rst;

    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else if (en)
            q <= d;
    end
endmodule