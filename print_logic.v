module print_logic (
    input       i_clk,
    input       i_rst_n,
    input       i_rx_data,
    
    output      o_i2c_scl,
    output      o_i2c_sda //
);

localparam STATE_WAIT = 2'b00, STATE_START = 2'b01,
           STATE_END  = 2'b11, STATE_CNT   = 2'b10;

reg        r_i2c_en;

reg  [1:0] r_state;
reg  [1:0] r_i2c_det;
reg  [1:0] r_uart_det;

reg  [7:0] r_pc;

reg  [7:0] r_start_cnt;
reg  [7:0] r_op_data;

wire       w_uart_clr;
wire       w_i2c_clr;

//////////////////EDGE DETECTOR/////////////////////////////
wire       w_uart_start = ~r_uart_det[1] & r_uart_det[0];
wire       w_uart_end   = ~r_uart_det[0] & r_uart_det[1];

wire       w_i2c_start  = ~r_i2c_det[1] & r_i2c_det[0];
wire       w_i2c_end    = ~r_i2c_det[0] & r_i2c_det[1];
///////////////////////////////////////////////////////////

wire       w_cnt_of     = &r_start_cnt;

wire [7:0] w_rx_data;

reg  [7:0] mem_opcode [95:0];

initial $readmemh("opcodes/lcd_opcode.txt", mem_opcode);

uart_rx_core uart_rx(.i_clk     (i_clk),
                     .i_rst_n   (i_rst_n),
                     .i_rx_data (i_rx_data),
                     .o_rx_data (w_rx_data),
                     .o_bus_clr (w_uart_clr));

iic_master_core i2c_tx(.i_clk       (i_clk),
                       .i_rst_n     (i_rst_n),
                       .i_i2c_en    (r_i2c_en),
                       .i_i2c_sdata (r_op_data),
                       .o_i2c_scl   (o_i2c_scl),
                       .o_i2c_sda   (o_i2c_sda),
                       .o_i2c_busy  (w_i2c_clr));

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_i2c_det <= 2'b00;
    else
        r_i2c_det <= {r_i2c_det[0], w_i2c_clr};
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_uart_det <= 2'b00;
    else
        r_uart_det <= {r_uart_det[0], w_uart_clr};
end

always @(posedge i_clk) begin
    if (r_state == STATE_WAIT)    
        r_op_data <= mem_opcode[r_pc];
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_pc <= 'b0;
    else if (r_state == STATE_CNT) begin
		  r_pc <= r_pc + 1'b1;
	 end
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_start_cnt <= 'b0;
    else if (r_state != STATE_END)
        r_start_cnt <= 'b0;
    else
        r_start_cnt <= r_start_cnt + 1'b1;
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n) begin
        r_state  <= STATE_WAIT;
        r_i2c_en <= 1;
    end
    else begin
        case (r_state)
            STATE_WAIT: begin
					if (r_pc < 96) begin
					r_state <= STATE_START;
					r_i2c_en <= 0;
					end
					else 
						r_pc <= STATE_WAIT;
            end
            STATE_START: begin
                if (w_i2c_end) begin
                    r_state <= STATE_CNT;
                    r_i2c_en <= 1;
                end
            end
            STATE_CNT: begin
                r_state <= STATE_END;
            end
            STATE_END: begin
                if (w_cnt_of)
                    r_state <= STATE_WAIT;
            end
        endcase
    end
end

endmodule
