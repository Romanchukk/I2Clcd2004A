module iic_master_core(
    input i_clk,
    input i_rst_n,
    input i_i2c_en,

    input [7:0] i_i2c_sdata,

    output o_i2c_scl,
    output o_i2c_sda,
    output o_i2c_busy //
);

localparam [6:0] SADDR = 7'h27; // 0x27 SLAVE ADDRESS

localparam STATE_IDLE = 3'b000, STATE_START = 3'b001,
           STATE_ADDR = 3'b010, STATE_RW = 3'b011,
           STATE_ACK_ADDR = 3'b100, STATE_DATA = 3'b101,
           STATE_ACK_DATA = 3'b110, STATE_END = 3'b111;

reg r_cnt_en;
//reg r_scl_en;
reg r_i2c_busy;
reg r_sda_en;

reg [2:0] r_en_det;

reg [2:0] r_state;
reg [3:0] r_bit_cnt;

reg [7:0] r_data;
reg [7:0] r_shift;

reg [7:0] r_start_cnt;


wire w_scl;
wire w_i2c_read;
wire w_i2c_shift;

wire w_start_i2c = r_en_det[2] & ~r_en_det[1];

assign o_i2c_scl  = (r_cnt_en) ? w_scl : 1'b1;
assign o_i2c_sda  = (r_sda_en) ? r_shift[7] : 1'b1;    
assign o_i2c_busy = r_i2c_busy;
 
scl_gen scl_inst(.i_clk(i_clk),
                 .i_rst_n(i_rst_n),
                 .i_cnt_en(r_cnt_en),
                 .o_scl_clk(w_scl),
                 .o_read_en(w_i2c_read),
                 .o_shift_en(w_i2c_shift));

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_en_det <= 3'b111;
    else
        r_en_det <= {r_en_det[1:0], i_i2c_en};
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n)
        r_data <= 'b0;
    else if (r_state == STATE_IDLE)
        r_data <= i_i2c_sdata;
end

always @(posedge i_clk, negedge i_rst_n) begin
    if (~i_rst_n) begin
        r_state <= STATE_IDLE;
        r_cnt_en <= 0;
        r_sda_en <= 0;
        r_i2c_busy <= 0;
    end
    else begin
        case (r_state)
            STATE_IDLE: begin
                if (w_start_i2c) begin
                    r_state <= STATE_START;
                    r_sda_en <= 1;
                    r_shift <= {SADDR, 1'b0};
                    r_i2c_busy <= 1;
                end
                else begin
                    r_cnt_en <= 0;
                    r_start_cnt <= 0;
                    r_bit_cnt <= 0;
                    r_sda_en <= 0;
                    r_i2c_busy <= 0;
                end
            end
            STATE_START: begin
                if (&r_start_cnt) begin
                    r_state <= STATE_ADDR;
                    r_cnt_en <= 1;
                    r_start_cnt <= r_start_cnt + 1'b1;
                end
                else begin
                    r_start_cnt <= r_start_cnt + 1'b1;
                end
            end
            STATE_ADDR: begin
                if (r_bit_cnt == 7) begin
                    r_state <= STATE_RW;
                    r_bit_cnt <= 0;
                end
                else begin
                    if (w_i2c_shift) begin
                        r_bit_cnt <= r_bit_cnt + 1'b1;
                        r_shift <= {r_shift[6:0], 1'b0};
                    end
                end
            end
            STATE_RW:
                if (w_i2c_shift) begin
                    r_state <= STATE_ACK_ADDR;
                    r_sda_en <= 0;
                    r_shift <= {r_shift[6:0], 1'b0};
                end
            STATE_ACK_ADDR:
                if (w_i2c_shift) begin
                    r_state <= STATE_DATA;
                    r_shift <= r_data;
                    r_sda_en <= 1; 
                end
            STATE_DATA: begin
                if (r_bit_cnt == 8) begin
                    r_state <= STATE_ACK_DATA;
                    r_bit_cnt <= 0;
                    r_sda_en <= 0;
                end
                else begin
                    if (w_i2c_shift) begin
                        r_bit_cnt <= r_bit_cnt + 1'b1;
                        r_shift <= {r_shift[6:0], 1'b0};
                    end
                end
            end
            STATE_ACK_DATA: begin
                if (w_i2c_shift) begin
                    r_state <= STATE_END;
                    r_sda_en <= 1;
                end
            end
            STATE_END: begin
                if (&r_start_cnt && ~r_cnt_en) begin
                    r_state <= STATE_IDLE;
                    r_start_cnt <= 0;
                    r_sda_en <= 1;
                end
                else if (w_i2c_read) begin
                    r_cnt_en <= 0;
                end 
                else if (~r_cnt_en) begin  
                    r_start_cnt <= r_start_cnt + 1'b1;
                end
            end 
        endcase
    end
end
    
endmodule
