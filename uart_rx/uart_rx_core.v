module uart_rx_core (
    input i_clk,
    input i_rst_n,
    input i_rx_data,

    output [7:0] o_rx_data, 
    output o_bus_clr //
);

localparam STATE_IDLE = 2'b00, STATE_START = 2'b01,
           STATE_DATA = 2'b10, STATE_END = 2'b11;

reg r_cnt_en;
reg r_uart_clr;

reg [1:0] r_rx_sync;
reg [1:0] r_state;

reg [3:0] r_bit_cnt;

reg [7:0] r_rx_data;
reg [7:0] r_rx_shift;

wire w_read_en;
wire w_bit_add;

wire w_rx_bit = r_rx_sync[1];

assign o_rx_data = r_rx_data;
assign o_busy    = r_uart_clr;

uart_baud_gen #(.BAUD_RATE(9600)) gen(.i_clk(i_clk),
									  .i_rst_n(i_rst_n),
									  .i_cnt_en(r_cnt_en),
									  .o_read_en(w_read_en),
									  .o_of_clk(w_bit_add));

always @(posedge i_clk) begin
    r_rx_sync <= {r_rx_sync[0], i_rx_data};
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_bit_cnt <= 'b0;
    else if (~r_cnt_en)
        r_bit_cnt <= 'b0;
    else if (w_bit_add)
        r_bit_cnt <= r_bit_cnt + 1'b1;
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_rx_data <= 'b0;
    else if (&r_state)
        r_rx_data <= r_rx_shift;
end

always @(posedge i_clk) begin
    if (r_state == STATE_DATA & w_read_en)
        r_rx_shift <= {w_rx_bit, r_rx_shift[7:1]};
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n) begin
        r_state <= STATE_IDLE;
        r_uart_clr <= 1'b0;
    end
    else begin
        case (r_state)
            STATE_IDLE: begin
                if (~w_rx_bit) begin
                    r_state <= STATE_START;
                    r_uart_clr <= 1'b1;
                end
            end
            STATE_START: begin
                if (r_bit_cnt == 1)
                    r_state <= STATE_DATA;
            end
            STATE_DATA: begin
                if (r_bit_cnt == 9)
                    r_state <= STATE_END;
            end 
            STATE_END: begin
                if (r_bit_cnt == 10) begin
                    r_state <= STATE_IDLE;
                    r_uart_clr <= 1'b0;
                end
            end
        endcase
    end
end

always @* begin
    case (r_state)
        STATE_IDLE: begin
            r_cnt_en <= 1'b0;
        end
        STATE_START: begin
            r_cnt_en <= 1'b1;
        end
    endcase
end
 
endmodule
