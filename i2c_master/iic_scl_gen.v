module scl_gen (
    input i_clk,
    input i_rst_n,
    input i_cnt_en, 

    output o_scl_clk,
    output o_read_en,
    output o_shift_en //
);

parameter DIVIDER = 1000;
parameter WIDTH = $clog2(DIVIDER);

reg [WIDTH - 1:0] r_div_cnt;

reg [2:0] r_edge_detect;

wire w_of = (r_div_cnt == DIVIDER - 1);

assign o_scl_clk  = (r_div_cnt >= (DIVIDER / 2));
assign o_shift_en =  r_edge_detect[2] & ~r_edge_detect[1];
assign o_read_en  = ~r_edge_detect[2] & r_edge_detect[1];

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_div_cnt <= 'b0;
    else if (~i_cnt_en)
        r_div_cnt <= 'b0;
    else if (w_of)
        r_div_cnt <= 'b0;
    else
        r_div_cnt <= r_div_cnt + 1'b1;
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_edge_detect <= 3'b000;
    else
        r_edge_detect <= {r_edge_detect[1:0], o_scl_clk};
end
    
endmodule
