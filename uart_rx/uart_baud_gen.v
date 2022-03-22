module uart_baud_gen
#(parameter BAUD_RATE = 9600, CLK_FREQ = 50_000_000)
(
    input i_clk, // INPUT SYSTEM CLK
    input i_rst_n,
    input i_cnt_en,

    output o_read_en,  //READ ENABLE WIRE
    output o_of_clk   //COUNT OF CLK
);

localparam DIV_PARAM = (CLK_FREQ / BAUD_RATE);
localparam WIDTH = $clog2(DIV_PARAM);

reg [WIDTH - 1:0] r_baud_cnt;

wire w_cnt_rst = (DIV_PARAM - 1 == r_baud_cnt);

assign o_of_clk  = w_cnt_rst;
assign o_read_en = (DIV_PARAM/2 == r_baud_cnt);

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n) //RESET
        r_baud_cnt <= 0;
    else if (w_cnt_rst)
        r_baud_cnt <= 0;    
    else if (i_cnt_en) //UART EN
        r_baud_cnt <= r_baud_cnt + 1'b1;
    else 
        r_baud_cnt <= 0;
end
endmodule
