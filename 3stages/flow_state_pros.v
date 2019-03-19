`timescale 1ps/1ps

module flow_state_processor (
  input          tx_mem_vld_in,
  input   [31:0] tx_mem_seq0_in,
  input   [31:0] tx_mem_seq1_in,
  input   [63:0] tx_mem_ts0_in,
  input   [63:0] tx_mem_ts1_in,

  input          rx_mem_vld_in,
  input   [31:0] rx_mem_ack0_in,
  input   [31:0] rx_mem_ack1_in,
  input   [31:0] rx_mem_ack2_in,
  input   [63:0] rx_mem_ts0_in,
  input   [63:0] rx_mem_ts1_in,
  input   [63:0] rx_mem_ts2_in,
  
  input   [21:0] id_mem_in,

  // Computed statistics are outputed in local bus format
  //
  output reg         flow_stats_vld_out,
  output reg  [97:0] flow_stats_out,
  //
  input          clk,
  input          rst_n
);
wire [63:0] dertatime_rx;
wire m_axis_dout_tvalid;
wire [63:0] m_axis_dout_tdata;
wire [31:0] r;
wire [31:0] f;
wire [31:0] d;
wire [1:0] l;
wire [9:0] id_in;

wire [31:0] fifo_sqnack_dout;
wire [1:0] fifo_loss_out;
reg fifo_sqnack_rd;
reg [1:0] loss_in;
reg loss_wr;
reg loss_rd;


assign id_in = id_mem_in[9:0];
assign {r,f,d,l} = flow_stats_out;


    always @(posedge clk)begin
        if(!rst_n)begin
            loss_in <= 0;
            loss_wr <= 0;
        end else begin
            if(rx_mem_vld_in)begin
                if(rx_mem_ack2_in == rx_mem_ack1_in && rx_mem_ack1_in == rx_mem_ack0_in)begin
                    loss_in <= 3;
                    loss_wr <= 1;
                end else if(rx_mem_ack2_in == rx_mem_ack1_in)begin
                    loss_in <= 2;
                    loss_wr <= 1;
                end else begin
                    loss_in <= 0;
                    loss_wr <= 1;
                end
            end else begin
                loss_wr <= 0;
            end
        end
    end

	assign dertatime_rx = tx_mem_ts1_in - tx_mem_ts0_in;
	

    div_gen_0 div_inst(
        .aclk(clk),
        .s_axis_divisor_tvalid(tx_mem_vld_in),
        .s_axis_divisor_tdata(dertatime_rx[31:0]),
        .s_axis_dividend_tvalid(tx_mem_vld_in),
        .s_axis_dividend_tdata(tx_mem_seq1_in - tx_mem_seq0_in),
        .m_axis_dout_tvalid(m_axis_dout_tvalid),
        .m_axis_dout_tdata(m_axis_dout_tdata)    //[63:0]
    );

    fifofall #(//
        .C_WIDTH(32),
        .C_MAX_DEPTH_BITS(6)
        ) fifo_in_sqnack_inst
        (// Outputs
        .dout              (fifo_sqnack_dout),
        .full              (),
        .nearly_full       (),
        .empty             (),
      // Inputs
        .din               (tx_mem_seq1_in - rx_mem_ack1_in),
        .wr_en             (rx_mem_vld_in),
        .rd_en             (fifo_sqnack_rd),
      
        .rst               (rst_n),
        .clk               (clk)
    );
    fifofall #(//
        .C_WIDTH(2),
        .C_MAX_DEPTH_BITS(6)
        ) fifo_loss_inst
        (// Outputs
        .dout              (fifo_loss_out),
        .full              (),
        .nearly_full       (),
        .empty             (),
      // Inputs
        .din               (loss_in),
        .wr_en             (loss_wr),
        .rd_en             (loss_rd),
      
        .rst               (rst_n),
        .clk               (clk)
    );
    

    always @(posedge clk)begin
        if(!rst_n)begin
            //out_math_valid <= 0;
            //out_data_id <= 0;
            //fifo_out_id_rd <= 0;
            //out_derta_ack <= 0;
			//fifo_status_in_wr <= 1;
			
            fifo_sqnack_rd <= 0;
			flow_stats_out <= 0;
			flow_stats_vld_out <= 0;
			loss_rd <= 0;
            //{out_send_r,out_send_f} <= 0;
        end else begin
            if(m_axis_dout_tvalid)begin
				//fifo_status_in_wr <= 1;//写入一个结果给输出FIFO
				
                //out_math_valid <= 1;
                //out_data_id <= fifo_out_id_dout;
                //fifo_out_id_rd <= 1;
                //out_derta_ack <= fifo_sqnack_dout;
                fifo_sqnack_rd <= 1;
                flow_stats_vld_out <= 1;
                loss_rd <= 1;
				flow_stats_out <= {m_axis_dout_tdata,fifo_sqnack_dout,fifo_loss_out};
                //{out_send_r,out_send_f} <= m_axis_dout_tdata;
            end else begin
				//fifo_status_in_wr <= 0;
                //out_math_valid <= 0;
                //out_data_id <= 0;
                //fifo_out_id_rd <= 0;
                //out_derta_ack <= 0;
                fifo_sqnack_rd <= 0;
                flow_stats_vld_out <= 0;
				flow_stats_out <= 0;
				loss_rd <= 0;
                //{out_send_r,out_send_f} <= 0;
            end
        end
    end
endmodule // flow_state_processor
