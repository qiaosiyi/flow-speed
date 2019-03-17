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

reg [31:0] tx_mem_seq1_in_last [0:127];
reg [63:0] tx_mem_ts1_in_last [0:127];

assign id_in = id_mem_in[9:0];
assign {r,f,d,l} = flow_stats_out;


    always @(posedge clk)begin
        if(!rst_n)begin
            tx_mem_seq1_in_last[ 0 ] <= 0; tx_mem_seq1_in_last[ 1 ] <= 0; tx_mem_seq1_in_last[ 2 ] <= 0; tx_mem_seq1_in_last[ 3 ] <= 0; tx_mem_seq1_in_last[ 4 ] <= 0; tx_mem_seq1_in_last[ 5 ] <= 0; tx_mem_seq1_in_last[ 6 ] <= 0; tx_mem_seq1_in_last[ 7 ] <= 0; tx_mem_seq1_in_last[ 8 ] <= 0; tx_mem_seq1_in_last[ 9 ] <= 0; tx_mem_seq1_in_last[ 10 ] <= 0; tx_mem_seq1_in_last[ 11 ] <= 0; tx_mem_seq1_in_last[ 12 ] <= 0; tx_mem_seq1_in_last[ 13 ] <= 0; tx_mem_seq1_in_last[ 14 ] <= 0; tx_mem_seq1_in_last[ 15 ] <= 0; tx_mem_seq1_in_last[ 16 ] <= 0; tx_mem_seq1_in_last[ 17 ] <= 0; tx_mem_seq1_in_last[ 18 ] <= 0; tx_mem_seq1_in_last[ 19 ] <= 0; tx_mem_seq1_in_last[ 20 ] <= 0; tx_mem_seq1_in_last[ 21 ] <= 0; tx_mem_seq1_in_last[ 22 ] <= 0; tx_mem_seq1_in_last[ 23 ] <= 0; tx_mem_seq1_in_last[ 24 ] <= 0; tx_mem_seq1_in_last[ 25 ] <= 0; tx_mem_seq1_in_last[ 26 ] <= 0; tx_mem_seq1_in_last[ 27 ] <= 0; tx_mem_seq1_in_last[ 28 ] <= 0; tx_mem_seq1_in_last[ 29 ] <= 0; tx_mem_seq1_in_last[ 30 ] <= 0; tx_mem_seq1_in_last[ 31 ] <= 0; tx_mem_seq1_in_last[ 32 ] <= 0; tx_mem_seq1_in_last[ 33 ] <= 0; tx_mem_seq1_in_last[ 34 ] <= 0; tx_mem_seq1_in_last[ 35 ] <= 0; tx_mem_seq1_in_last[ 36 ] <= 0; tx_mem_seq1_in_last[ 37 ] <= 0; tx_mem_seq1_in_last[ 38 ] <= 0; tx_mem_seq1_in_last[ 39 ] <= 0; tx_mem_seq1_in_last[ 40 ] <= 0; tx_mem_seq1_in_last[ 41 ] <= 0; tx_mem_seq1_in_last[ 42 ] <= 0; tx_mem_seq1_in_last[ 43 ] <= 0; tx_mem_seq1_in_last[ 44 ] <= 0; tx_mem_seq1_in_last[ 45 ] <= 0; tx_mem_seq1_in_last[ 46 ] <= 0; tx_mem_seq1_in_last[ 47 ] <= 0; tx_mem_seq1_in_last[ 48 ] <= 0; tx_mem_seq1_in_last[ 49 ] <= 0; tx_mem_seq1_in_last[ 50 ] <= 0; tx_mem_seq1_in_last[ 51 ] <= 0; tx_mem_seq1_in_last[ 52 ] <= 0; tx_mem_seq1_in_last[ 53 ] <= 0; tx_mem_seq1_in_last[ 54 ] <= 0; tx_mem_seq1_in_last[ 55 ] <= 0; tx_mem_seq1_in_last[ 56 ] <= 0; tx_mem_seq1_in_last[ 57 ] <= 0; tx_mem_seq1_in_last[ 58 ] <= 0; tx_mem_seq1_in_last[ 59 ] <= 0; tx_mem_seq1_in_last[ 60 ] <= 0; tx_mem_seq1_in_last[ 61 ] <= 0; tx_mem_seq1_in_last[ 62 ] <= 0; tx_mem_seq1_in_last[ 63 ] <= 0; tx_mem_seq1_in_last[ 64 ] <= 0; tx_mem_seq1_in_last[ 65 ] <= 0; tx_mem_seq1_in_last[ 66 ] <= 0; tx_mem_seq1_in_last[ 67 ] <= 0; tx_mem_seq1_in_last[ 68 ] <= 0; tx_mem_seq1_in_last[ 69 ] <= 0; tx_mem_seq1_in_last[ 70 ] <= 0; tx_mem_seq1_in_last[ 71 ] <= 0; tx_mem_seq1_in_last[ 72 ] <= 0; tx_mem_seq1_in_last[ 73 ] <= 0; tx_mem_seq1_in_last[ 74 ] <= 0; tx_mem_seq1_in_last[ 75 ] <= 0; tx_mem_seq1_in_last[ 76 ] <= 0; tx_mem_seq1_in_last[ 77 ] <= 0; tx_mem_seq1_in_last[ 78 ] <= 0; tx_mem_seq1_in_last[ 79 ] <= 0; tx_mem_seq1_in_last[ 80 ] <= 0; tx_mem_seq1_in_last[ 81 ] <= 0; tx_mem_seq1_in_last[ 82 ] <= 0; tx_mem_seq1_in_last[ 83 ] <= 0; tx_mem_seq1_in_last[ 84 ] <= 0; tx_mem_seq1_in_last[ 85 ] <= 0; tx_mem_seq1_in_last[ 86 ] <= 0; tx_mem_seq1_in_last[ 87 ] <= 0; tx_mem_seq1_in_last[ 88 ] <= 0; tx_mem_seq1_in_last[ 89 ] <= 0; tx_mem_seq1_in_last[ 90 ] <= 0; tx_mem_seq1_in_last[ 91 ] <= 0; tx_mem_seq1_in_last[ 92 ] <= 0; tx_mem_seq1_in_last[ 93 ] <= 0; tx_mem_seq1_in_last[ 94 ] <= 0; tx_mem_seq1_in_last[ 95 ] <= 0; tx_mem_seq1_in_last[ 96 ] <= 0; tx_mem_seq1_in_last[ 97 ] <= 0; tx_mem_seq1_in_last[ 98 ] <= 0; tx_mem_seq1_in_last[ 99 ] <= 0; tx_mem_seq1_in_last[ 100 ] <= 0; tx_mem_seq1_in_last[ 101 ] <= 0; tx_mem_seq1_in_last[ 102 ] <= 0; tx_mem_seq1_in_last[ 103 ] <= 0; tx_mem_seq1_in_last[ 104 ] <= 0; tx_mem_seq1_in_last[ 105 ] <= 0; tx_mem_seq1_in_last[ 106 ] <= 0; tx_mem_seq1_in_last[ 107 ] <= 0; tx_mem_seq1_in_last[ 108 ] <= 0; tx_mem_seq1_in_last[ 109 ] <= 0; tx_mem_seq1_in_last[ 110 ] <= 0; tx_mem_seq1_in_last[ 111 ] <= 0; tx_mem_seq1_in_last[ 112 ] <= 0; tx_mem_seq1_in_last[ 113 ] <= 0; tx_mem_seq1_in_last[ 114 ] <= 0; tx_mem_seq1_in_last[ 115 ] <= 0; tx_mem_seq1_in_last[ 116 ] <= 0; tx_mem_seq1_in_last[ 117 ] <= 0; tx_mem_seq1_in_last[ 118 ] <= 0; tx_mem_seq1_in_last[ 119 ] <= 0; tx_mem_seq1_in_last[ 120 ] <= 0; tx_mem_seq1_in_last[ 121 ] <= 0; tx_mem_seq1_in_last[ 122 ] <= 0; tx_mem_seq1_in_last[ 123 ] <= 0; tx_mem_seq1_in_last[ 124 ] <= 0; tx_mem_seq1_in_last[ 125 ] <= 0; tx_mem_seq1_in_last[ 126 ] <= 0; tx_mem_seq1_in_last[ 127 ] <= 0; 
            tx_mem_ts1_in_last[ 0 ] <= 0; tx_mem_ts1_in_last[ 1 ] <= 0; tx_mem_ts1_in_last[ 2 ] <= 0; tx_mem_ts1_in_last[ 3 ] <= 0; tx_mem_ts1_in_last[ 4 ] <= 0; tx_mem_ts1_in_last[ 5 ] <= 0; tx_mem_ts1_in_last[ 6 ] <= 0; tx_mem_ts1_in_last[ 7 ] <= 0; tx_mem_ts1_in_last[ 8 ] <= 0; tx_mem_ts1_in_last[ 9 ] <= 0; tx_mem_ts1_in_last[ 10 ] <= 0; tx_mem_ts1_in_last[ 11 ] <= 0; tx_mem_ts1_in_last[ 12 ] <= 0; tx_mem_ts1_in_last[ 13 ] <= 0; tx_mem_ts1_in_last[ 14 ] <= 0; tx_mem_ts1_in_last[ 15 ] <= 0; tx_mem_ts1_in_last[ 16 ] <= 0; tx_mem_ts1_in_last[ 17 ] <= 0; tx_mem_ts1_in_last[ 18 ] <= 0; tx_mem_ts1_in_last[ 19 ] <= 0; tx_mem_ts1_in_last[ 20 ] <= 0; tx_mem_ts1_in_last[ 21 ] <= 0; tx_mem_ts1_in_last[ 22 ] <= 0; tx_mem_ts1_in_last[ 23 ] <= 0; tx_mem_ts1_in_last[ 24 ] <= 0; tx_mem_ts1_in_last[ 25 ] <= 0; tx_mem_ts1_in_last[ 26 ] <= 0; tx_mem_ts1_in_last[ 27 ] <= 0; tx_mem_ts1_in_last[ 28 ] <= 0; tx_mem_ts1_in_last[ 29 ] <= 0; tx_mem_ts1_in_last[ 30 ] <= 0; tx_mem_ts1_in_last[ 31 ] <= 0; tx_mem_ts1_in_last[ 32 ] <= 0; tx_mem_ts1_in_last[ 33 ] <= 0; tx_mem_ts1_in_last[ 34 ] <= 0; tx_mem_ts1_in_last[ 35 ] <= 0; tx_mem_ts1_in_last[ 36 ] <= 0; tx_mem_ts1_in_last[ 37 ] <= 0; tx_mem_ts1_in_last[ 38 ] <= 0; tx_mem_ts1_in_last[ 39 ] <= 0; tx_mem_ts1_in_last[ 40 ] <= 0; tx_mem_ts1_in_last[ 41 ] <= 0; tx_mem_ts1_in_last[ 42 ] <= 0; tx_mem_ts1_in_last[ 43 ] <= 0; tx_mem_ts1_in_last[ 44 ] <= 0; tx_mem_ts1_in_last[ 45 ] <= 0; tx_mem_ts1_in_last[ 46 ] <= 0; tx_mem_ts1_in_last[ 47 ] <= 0; tx_mem_ts1_in_last[ 48 ] <= 0; tx_mem_ts1_in_last[ 49 ] <= 0; tx_mem_ts1_in_last[ 50 ] <= 0; tx_mem_ts1_in_last[ 51 ] <= 0; tx_mem_ts1_in_last[ 52 ] <= 0; tx_mem_ts1_in_last[ 53 ] <= 0; tx_mem_ts1_in_last[ 54 ] <= 0; tx_mem_ts1_in_last[ 55 ] <= 0; tx_mem_ts1_in_last[ 56 ] <= 0; tx_mem_ts1_in_last[ 57 ] <= 0; tx_mem_ts1_in_last[ 58 ] <= 0; tx_mem_ts1_in_last[ 59 ] <= 0; tx_mem_ts1_in_last[ 60 ] <= 0; tx_mem_ts1_in_last[ 61 ] <= 0; tx_mem_ts1_in_last[ 62 ] <= 0; tx_mem_ts1_in_last[ 63 ] <= 0; tx_mem_ts1_in_last[ 64 ] <= 0; tx_mem_ts1_in_last[ 65 ] <= 0; tx_mem_ts1_in_last[ 66 ] <= 0; tx_mem_ts1_in_last[ 67 ] <= 0; tx_mem_ts1_in_last[ 68 ] <= 0; tx_mem_ts1_in_last[ 69 ] <= 0; tx_mem_ts1_in_last[ 70 ] <= 0; tx_mem_ts1_in_last[ 71 ] <= 0; tx_mem_ts1_in_last[ 72 ] <= 0; tx_mem_ts1_in_last[ 73 ] <= 0; tx_mem_ts1_in_last[ 74 ] <= 0; tx_mem_ts1_in_last[ 75 ] <= 0; tx_mem_ts1_in_last[ 76 ] <= 0; tx_mem_ts1_in_last[ 77 ] <= 0; tx_mem_ts1_in_last[ 78 ] <= 0; tx_mem_ts1_in_last[ 79 ] <= 0; tx_mem_ts1_in_last[ 80 ] <= 0; tx_mem_ts1_in_last[ 81 ] <= 0; tx_mem_ts1_in_last[ 82 ] <= 0; tx_mem_ts1_in_last[ 83 ] <= 0; tx_mem_ts1_in_last[ 84 ] <= 0; tx_mem_ts1_in_last[ 85 ] <= 0; tx_mem_ts1_in_last[ 86 ] <= 0; tx_mem_ts1_in_last[ 87 ] <= 0; tx_mem_ts1_in_last[ 88 ] <= 0; tx_mem_ts1_in_last[ 89 ] <= 0; tx_mem_ts1_in_last[ 90 ] <= 0; tx_mem_ts1_in_last[ 91 ] <= 0; tx_mem_ts1_in_last[ 92 ] <= 0; tx_mem_ts1_in_last[ 93 ] <= 0; tx_mem_ts1_in_last[ 94 ] <= 0; tx_mem_ts1_in_last[ 95 ] <= 0; tx_mem_ts1_in_last[ 96 ] <= 0; tx_mem_ts1_in_last[ 97 ] <= 0; tx_mem_ts1_in_last[ 98 ] <= 0; tx_mem_ts1_in_last[ 99 ] <= 0; tx_mem_ts1_in_last[ 100 ] <= 0; tx_mem_ts1_in_last[ 101 ] <= 0; tx_mem_ts1_in_last[ 102 ] <= 0; tx_mem_ts1_in_last[ 103 ] <= 0; tx_mem_ts1_in_last[ 104 ] <= 0; tx_mem_ts1_in_last[ 105 ] <= 0; tx_mem_ts1_in_last[ 106 ] <= 0; tx_mem_ts1_in_last[ 107 ] <= 0; tx_mem_ts1_in_last[ 108 ] <= 0; tx_mem_ts1_in_last[ 109 ] <= 0; tx_mem_ts1_in_last[ 110 ] <= 0; tx_mem_ts1_in_last[ 111 ] <= 0; tx_mem_ts1_in_last[ 112 ] <= 0; tx_mem_ts1_in_last[ 113 ] <= 0; tx_mem_ts1_in_last[ 114 ] <= 0; tx_mem_ts1_in_last[ 115 ] <= 0; tx_mem_ts1_in_last[ 116 ] <= 0; tx_mem_ts1_in_last[ 117 ] <= 0; tx_mem_ts1_in_last[ 118 ] <= 0; tx_mem_ts1_in_last[ 119 ] <= 0; tx_mem_ts1_in_last[ 120 ] <= 0; tx_mem_ts1_in_last[ 121 ] <= 0; tx_mem_ts1_in_last[ 122 ] <= 0; tx_mem_ts1_in_last[ 123 ] <= 0; tx_mem_ts1_in_last[ 124 ] <= 0; tx_mem_ts1_in_last[ 125 ] <= 0; tx_mem_ts1_in_last[ 126 ] <= 0; tx_mem_ts1_in_last[ 127 ] <= 0; 
            loss_in <= 0;
            loss_wr <= 0;
        end else begin
            if(rx_mem_vld_in)begin
                tx_mem_seq1_in_last[id_in] <= tx_mem_seq1_in;
                tx_mem_ts1_in_last[id_in] <= tx_mem_ts1_in;
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

	assign dertatime_rx = tx_mem_ts1_in - tx_mem_ts1_in_last[id_in];
	

    div_gen_0 div_inst(
        .aclk(clk),
        .s_axis_divisor_tvalid(tx_mem_vld_in),
        .s_axis_divisor_tdata(dertatime_rx[31:0]),
        .s_axis_dividend_tvalid(tx_mem_vld_in),
        .s_axis_dividend_tdata(tx_mem_seq1_in - tx_mem_seq1_in_last[id_in]),
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
