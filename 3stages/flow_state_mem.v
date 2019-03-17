	`timescale 1ps/1ps

module flow_state_mem (
  // TX sequence number and RX acknowledge number
  // 
  // These signals are stored in FIFOs inside this module and synchronized with
  // flow ID queried from flow table
  input             tx_flow_state_vld_in,
  input      [31:0] tx_flow_state_in,
  input             rx_flow_state_vld_in,
  input      [31:0] rx_flow_state_in,

  // TX/RX flow ID to be updated
  // 
  // Note that at 40G/128b, it takes at least 4 cycles to generate a flow ID.
  // The latency of this module is also 4 cycles.  So there is no need to setup
  // backpressure.
  input             tx_flow_id_vld_in,
  input             tx_flow_id_match_in,
  input      [21:0] tx_flow_id_in,
  
  input             rx_flow_id_vld_in,
  input             rx_flow_id_match_in,
  input      [21:0] rx_flow_id_in,

  // Output TX flow state (sequence number and timestamp) triggered by the
  // update of RX flowe
  output reg        tx_mem_vld_out,
  output reg [31:0] tx_mem_seq0_out,
  output reg [31:0] tx_mem_seq1_out,
  output reg [63:0] tx_mem_ts0_out,
  output reg [63:0] tx_mem_ts1_out,

  // Output RX flow state (sequence number and timestamp) triggered by the
  // update of RX flow
  output reg        rx_mem_vld_out,
  output reg [31:0] rx_mem_ack0_out,
  output reg [31:0] rx_mem_ack1_out,
  output reg [31:0] rx_mem_ack2_out,
  output reg [63:0] rx_mem_ts0_out,
  output reg [63:0] rx_mem_ts1_out,
  output reg [63:0] rx_mem_ts2_out,
  
  output reg [21:0] id_mem_out,

  input             clk,
  input             rst_n
);
reg [63:0] time_stemp;//时间，这是时间戳

wire [31:0] fifo_state_tx_dout;
wire fifo_state_tx_empty;
reg fifo_state_tx_rd;

wire fifo_id_match_tx_dout;
wire [21:0] fifo_id_tx_dout;
wire fifo_id_tx_empty;
reg fifo_id_tx_rd;

wire [31:0] fifo_state_rx_dout;
wire fifo_state_rx_empty;
reg fifo_state_rx_rd;

wire fifo_id_match_rx_dout;
wire [21:0] fifo_id_rx_dout;
wire fifo_id_rx_empty;
reg fifo_id_rx_rd;

wire [21:0] fifo_rxid_dout;
wire fifo_rxid_empty;
reg [21:0] fifo_rxid_in;
reg fifo_rxid_valid;
reg fifo_rxid_rd;

reg mm_wea_tx;
reg [9:0] mm_addra_tx;
reg [191:0] mm_dina_tx;
wire [63:0] time_old2_a_tx;
wire [63:0] time_old1_a_tx;
wire [31:0] sqn_old2_a_tx;
wire [31:0] sqn_old1_a_tx;
reg [9:0] mm_addrb_tx;
wire [191:0] mm_doutb_tx;

reg mm_wea_rx;
reg [9:0] mm_addra_rx;
reg [287:0] mm_dina_rx;
wire [63:0] time_old3_a_rx;
wire [63:0] time_old2_a_rx;
wire [63:0] time_old1_a_rx;
wire [31:0] sqn_old3_a_rx;
wire [31:0] sqn_old2_a_rx;
wire [31:0] sqn_old1_a_rx;
reg [9:0] mm_addrb_rx;
wire [287:0] mm_doutb_rx;

reg [7:0] state_tx;
localparam           IDLE_tx = 0;
localparam           READ0_tx = 1;
localparam           READ1_tx = 2;
localparam           WRITE_tx = 3;
localparam           IDLE_tx_nomatch = 4;

reg [7:0] state_rx;
localparam           IDLE_rx = 0;
localparam           READ0_rx = 1;
localparam           READ1_rx = 2;
localparam           WRITE_rx = 3;
localparam           IDLE_rx_nomatch = 4;

reg [7:0] state_id;
localparam           IDLE_id = 0;
localparam           READ0_id = 1;
localparam           READ1_id = 2;
localparam           WRITE_id = 3;

reg [31:0] fifo_state_tx_tmp;
reg [31:0] fifo_state_rx_tmp;

reg mm_web_rx;
reg [21:0] out_id_tmp;


   fifofall #(//存放TCP协议数据seq
	  .C_WIDTH(32),
      .C_MAX_DEPTH_BITS(8)
      ) fifo_state_tx
      (// Outputs
      .dout              (fifo_state_tx_dout),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_state_tx_empty),
      // Inputs
      .din               (tx_flow_state_in),
      .wr_en             (tx_flow_state_vld_in),
      .rd_en             (fifo_state_tx_rd),
      
      .rst               (rst_n),
      .clk               (clk)); 

     fifofall #(//存放查表结果tx id
	  .C_WIDTH(23),
      .C_MAX_DEPTH_BITS(4)
      ) fifo_id_tx
      (// Outputs
      .dout              ({fifo_id_match_tx_dout,fifo_id_tx_dout}),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_id_tx_empty),
      // Inputs
      .din               ({tx_flow_id_match_in,tx_flow_id_in}),
      .wr_en             (tx_flow_id_vld_in),
      .rd_en             (fifo_id_tx_rd),
      
      .rst               (rst_n),
      .clk               (clk)); 

     fifofall #(//存放TCP协议数据ack
	  .C_WIDTH(32),
      .C_MAX_DEPTH_BITS(8)
      ) fifo_state_rx
      (// Outputs
      .dout              (fifo_state_rx_dout),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_state_rx_empty),
      // Inputs
      .din               (rx_flow_state_in),
      .wr_en             (rx_flow_state_vld_in),
      .rd_en             (fifo_state_rx_rd),
      
      .rst               (rst_n),
      .clk               (clk)); 

     fifofall #(//存放查表结果rx id
	  .C_WIDTH(23),
      .C_MAX_DEPTH_BITS(4)
      ) fifo_id_rx
      (// Outputs
      .dout              ({fifo_id_match_rx_dout,fifo_id_rx_dout}),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_id_rx_empty),
      // Inputs
      .din               ({rx_flow_id_match_in,rx_flow_id_in}),
      .wr_en             (rx_flow_id_vld_in),
      .rd_en             (fifo_id_rx_rd),
      
      .rst               (rst_n),
      .clk               (clk));  

	  fifofall #(//放置rxid数据的FIFO,当rx的更新状态机执行结束之后再执行对这个FIFO附一个id元素
        .C_WIDTH(22),
        .C_MAX_DEPTH_BITS(6)
        ) fifo_in_rxid_inst
        (// Outputs
        .dout              (fifo_rxid_dout),
        .full              (),
        .nearly_full       (),
        .empty             (fifo_rxid_empty),
        // Inputs
        .din               (fifo_rxid_in),
        .wr_en             (fifo_rxid_valid),
        .rd_en             (fifo_rxid_rd),
      
        .rst               (rst_n),
        .clk               (clk)); 


    bram_192_1024 tx_ram_inst(
        .clka(clk),
        .wea(mm_wea_tx),//写使能,写入为高，读数据为低 //A：存储接口，接受从流表匹配过来的值，
        .addra(mm_addra_tx),//【9：0】
        .dina(mm_dina_tx),//【127：0】
        .douta({time_old2_a_tx,time_old1_a_tx,sqn_old2_a_tx,sqn_old1_a_tx}),//【191：0】
      
        .clkb(clk),
        .web(0),//写使能,写入为高，读数据为低 //B：读取接口，为下一级模块使用。
        .addrb(mm_addrb_tx),//【9：0】
        .dinb(0),//【127：0】
        .doutb(mm_doutb_tx)//【127：0】
    );

	bram_288_1024 rx_ram_inst(

        .clka(clk),
        .wea(mm_wea_rx),//写使能,写入为高，读数据为低 //A：存储接口，接受从流表匹配过来的值，
        .addra(mm_addra_rx),//【9：0】
        .dina(mm_dina_rx),//【127：0】
        .douta({time_old3_a_rx,time_old2_a_rx,time_old1_a_rx,sqn_old3_a_rx,sqn_old2_a_rx,sqn_old1_a_rx}),//【127：0】
	  
        .clkb(clk),
        .web(0),//写使能,写入为高，读数据为低 //B：读取接口，为下一级模块使用。
        .addrb(mm_addrb_rx),//【9：0】
        .dinb(0),//【127：0】
        .doutb(mm_doutb_rx)//【127：0】
	);
	always @ (posedge clk) begin//轮询调度的指示变化位。
		if (!rst_n) begin
		  //input_sel <= 0;
		  time_stemp <= 0;
		end else begin
		 // input_sel <= input_sel + 1;// 一周期换一个
		  time_stemp <= time_stemp + 1;
		end
	  end

    always @(posedge clk)begin//更新tx RAM
        if(!rst_n)begin
            mm_wea_tx <= 0;
            mm_addra_tx <= 0;
            mm_dina_tx <= 0;
            //fifo_in_rd_tx <= 0;
			fifo_state_tx_rd <= 0;
			fifo_id_tx_rd <= 0;
            state_tx <= IDLE_tx;
            fifo_rxid_in <= 0;
            fifo_rxid_valid <= 0;	
			fifo_state_tx_tmp <= 0;	
        end else begin
            case(state_tx)
                IDLE_tx: begin
                    if(!fifo_id_tx_empty && fifo_id_match_tx_dout)begin//读取id的地址，然后做修改，放回
                        mm_wea_tx <= 0;//读使能
                        mm_addra_tx <= fifo_id_tx_dout[9:0];//读地址
                       // fifo_in_rd_tx <= 0;//读取输入值一个节拍
						fifo_state_tx_rd <= 0;//读取输入值一个节拍
						fifo_id_tx_rd <= 0;//读取输入值一个节拍
                        mm_dina_tx <= 0;
                        state_tx <= READ0_tx;
						fifo_state_tx_tmp <= 0;	
                    end else if(!fifo_id_tx_empty && !fifo_id_match_tx_dout) begin// entry not match 
                        fifo_state_tx_rd <= 1;
                        fifo_id_tx_rd <= 1;
                        state_tx <= IDLE_tx_nomatch;
                        mm_wea_tx <= 0;
                        mm_addra_tx <= 0;
                        mm_dina_tx <= 0;
                        fifo_state_tx_tmp <= 0;
                    end else begin
                        mm_wea_tx <= 0;
                        mm_addra_tx <= 0;
                        mm_dina_tx <= 0;
                        //fifo_in_rd_tx <= 0;
						fifo_state_tx_rd <= 0;
						fifo_id_tx_rd <= 0;
                        state_tx <= IDLE_tx;
						fifo_state_tx_tmp <= 0;	
                    end
                end
                READ0_tx:begin
                    state_tx <= READ1_tx;
                end
                READ1_tx:begin//写入修改后的新值
                    mm_wea_tx <= 0;
                    //mm_dina_tx <= {time_old1_a_tx,fifo_in_time_tx,sqn_old1_a_tx,fifo_in_sqn_tx};
                    //fifo_in_rd_tx <= 1;//读取
					fifo_state_tx_tmp <= fifo_state_tx_dout;//保存FIFO输出结果
					fifo_state_tx_rd <= 1;
					fifo_id_tx_rd <= 1;
                    state_tx <= WRITE_tx;
                end
                WRITE_tx:begin
                    mm_wea_tx <= 1;
                    // fifo_in_rd_tx <= 0;
				    fifo_state_tx_rd <= 0;
					fifo_id_tx_rd <= 0;
                    mm_dina_tx <= {time_old1_a_tx,time_stemp,sqn_old1_a_tx,fifo_state_tx_tmp};
                    state_tx <= IDLE_tx;
                end
                IDLE_tx_nomatch:begin
                    mm_wea_tx <= 0;
                    mm_addra_tx <= 0;
                    mm_dina_tx <= 0;
                    //fifo_in_rd_tx <= 0;
                    fifo_state_tx_rd <= 0;
                    fifo_id_tx_rd <= 0;
                    state_tx <= IDLE_tx;
                    fifo_state_tx_tmp <= 0;
                end
            endcase
        end
    end
    
    always @(posedge clk)begin
        if(!rst_n)begin
            mm_wea_rx <= 0;
            mm_addra_rx <= 0;
            mm_dina_rx <= 0;
            mm_web_rx <= 0;
            //fifo_in_rd_rx <= 0;
			fifo_state_rx_rd <= 0;
			fifo_id_rx_rd <= 0;
            state_rx <= IDLE_rx;
			fifo_state_rx_tmp <= 0;
        end else begin
            case(state_rx)
                IDLE_rx: begin
                    if(!fifo_id_rx_empty && fifo_id_match_rx_dout)begin//读取id的地址，然后做修改放回!fifo_id_tx_empty && fifo_id_match_tx_dout
                        mm_wea_rx <= 0;
                        mm_addra_rx <= fifo_id_rx_dout[9:0];
                        //fifo_in_rd_rx <= 0;
						fifo_state_rx_rd <= 0;
						fifo_id_rx_rd <= 0;
                        mm_dina_rx <= 0;
                        state_rx <= READ0_rx;
						fifo_state_rx_tmp <= 0;
                    end else if(!fifo_id_rx_empty && !fifo_id_match_rx_dout)begin//!fifo_id_tx_empty && !fifo_id_match_tx_dout
                        fifo_state_rx_rd <= 1;
                        fifo_id_rx_rd <= 1;
                        state_rx <= IDLE_rx_nomatch;
                        mm_wea_rx <= 0;
                        mm_addra_rx <= 0;
                        mm_dina_rx <= 0;
                        fifo_state_rx_tmp <= 0;
                    end else begin
                        mm_wea_rx <= 0;
                        mm_addra_rx <= 0;
                        mm_dina_rx <= 0;
                        //fifo_in_rd_rx <= 0;
						fifo_state_rx_rd <= 0;
						fifo_id_rx_rd <= 0;
                        state_rx <= IDLE_rx;
						fifo_state_rx_tmp <= 0;
                    end
                end
                READ0_rx:begin
                    state_rx <= READ1_rx;
                end
                READ1_rx:begin//写入修改后的新值
                    mm_wea_rx <= 0;
                    //fifo_in_rd_rx <= 1;
					fifo_state_rx_rd <= 1;
					fifo_id_rx_rd <= 1;
                    state_rx <= WRITE_rx;
                    fifo_rxid_valid <= 1;//给rxid FIFO写入一个新值
                    fifo_rxid_in <= fifo_id_rx_dout;
					fifo_state_rx_tmp <= fifo_state_rx_dout;
                end
                WRITE_rx:begin
                    mm_wea_rx <= 1;
                    //fifo_in_rd_rx <= 0;
					fifo_state_rx_rd <= 0;
					fifo_id_rx_rd <= 0;
                    mm_dina_rx <= {time_old2_a_rx,time_old1_a_rx,time_stemp,sqn_old2_a_rx,sqn_old1_a_rx,fifo_state_rx_tmp};
                    state_rx <= IDLE_rx;
                    fifo_rxid_valid <= 0;//给rxid FIFO写入一个新值
                    fifo_rxid_in <= 0;
                end
                IDLE_rx_nomatch:begin
                    mm_wea_rx <= 0;
                    mm_addra_rx <= 0;
                    mm_dina_rx <= 0;
                    //fifo_in_rd_tx <= 0;
                    fifo_state_rx_rd <= 0;
                    fifo_id_rx_rd <= 0;
                    state_rx <= IDLE_rx;
                    fifo_state_rx_tmp <= 0;
                end
            endcase
        end
    end


    always @(posedge clk)begin//计算过程状态机，计算差值，送给除法器和数据暂存器
        if(!rst_n)begin
            mm_addrb_tx <= 0;
            mm_addrb_rx <= 0;
            fifo_rxid_rd <= 0;
            state_id <= IDLE_id;
            //fifo_sqnack_valid <= 0;
            //dertatime_tx_valid <= 0;
           // dertasqn_tx_valid <= 0;
           // fifo_out_id_valid <= 0;
            //fifo_out_id_in <= 0;
			tx_mem_vld_out <= 0;
			rx_mem_vld_out <= 0;
			tx_mem_ts0_out <= 0;
			tx_mem_ts1_out <= 0;
			tx_mem_seq0_out <= 0;
			tx_mem_seq1_out <= 0;
			
			rx_mem_ts0_out <= 0;
			rx_mem_ts1_out <= 0;
			rx_mem_ts2_out <= 0;
			rx_mem_ack0_out <= 0;
			rx_mem_ack1_out <= 0;
			rx_mem_ack2_out <= 0;
			id_mem_out <= 0;
			
        end else begin
            case(state_id)
                IDLE_id:begin
                    if(!fifo_rxid_empty)begin
                        mm_addrb_tx <= fifo_rxid_dout[9:0];
                        mm_addrb_rx <= fifo_rxid_dout[9:0];
                        tx_mem_vld_out <= 0;
                        rx_mem_vld_out <= 0;
                        tx_mem_ts0_out <= 0;
                        tx_mem_ts1_out <= 0;
                        tx_mem_seq0_out <= 0;
                        tx_mem_seq1_out <= 0;
                        
                        rx_mem_ts0_out <= 0;
                        rx_mem_ts1_out <= 0;
                        rx_mem_ts2_out <= 0;
                        rx_mem_ack0_out <= 0;
                        rx_mem_ack1_out <= 0;
                        id_mem_out <= 0;
                        state_id <= READ0_id;
                    end else begin
                        tx_mem_vld_out <= 0;
                        rx_mem_vld_out <= 0;
                        tx_mem_ts0_out <= 0;
                        tx_mem_ts1_out <= 0;
                        tx_mem_seq0_out <= 0;
                        tx_mem_seq1_out <= 0;
                        
                        rx_mem_ts0_out <= 0;
                        rx_mem_ts1_out <= 0;
                        rx_mem_ts2_out <= 0;
                        rx_mem_ack0_out <= 0;
                        rx_mem_ack1_out <= 0;
                        rx_mem_ack2_out <= 0;
                        id_mem_out <= 0;
                        state_id <= IDLE_id;
                        //fifo_out_id_valid <= 0;
                        //fifo_out_id_in <= 0;
                    end
                end
                READ0_id:begin
                    state_id <= READ1_id;
                    
                    //fifo_out_id_valid <= 0;
                    //fifo_out_id_in <= 0;
                end
                READ1_id:begin
                    state_id <= WRITE_id;
                    out_id_tmp <= fifo_rxid_dout;
                    fifo_rxid_rd <= 1;
                end
                WRITE_id:begin
					tx_mem_vld_out <= 1;
					{tx_mem_ts0_out,tx_mem_ts1_out,tx_mem_seq0_out,tx_mem_seq1_out} <= mm_doutb_tx;
					rx_mem_vld_out <= 1;
					{rx_mem_ts0_out,rx_mem_ts1_out,rx_mem_ts2_out,rx_mem_ack0_out,rx_mem_ack1_out,rx_mem_ack2_out} <= mm_doutb_rx;
                    fifo_rxid_rd <= 0;
                    id_mem_out <= out_id_tmp;
                    state_id <= IDLE_id;
                end
            endcase
        end
    end
endmodule // flow_state_mem
