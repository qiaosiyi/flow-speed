module txrx_ram_update #(
  parameter  C_LENGTH_5TUPLE = 104,
  parameter  C_ID_WIDTH = 12,
  parameter  C_COUNTER_WIDTH = 20,
  parameter  C_pd_WIDTH = 32
  )(
	input                            in_valid_tx,
	input [22:0]                     in_id_tx,
	input [63:0]                     in_time_tx,
	input [31:0]                     in_sqn_tx,      
	
	input                            in_valid_rx,
	input [22:0]                     in_id_rx,
	input [63:0]                     in_time_rx,
	input [31:0]                     in_sqn_rx,
	
    input                            clk,
    input                            reset,//高复位
    
    output reg                      out_math_valid,
    output reg [22:0]                out_data_id,
    output reg [31:0]               out_send_r,
    output reg [31:0]               out_send_f,
    output reg [31:0]               out_derta_ack
  );
	wire [22:0]                     fifo_in_id_tx;
	wire [63:0]                     fifo_in_time_tx;
	wire [31:0]                     fifo_in_sqn_tx;
	wire                            fifo_in_empty_tx;
	reg                             fifo_in_rd_tx; 
	
	reg 		mm_wea_tx;
	reg [9:0]	mm_addra_tx;
	reg [191:0] mm_dina_tx;
        wire [63:0]	time_old2_a_tx;
	wire [63:0]	time_old1_a_tx;
	wire [31:0]	sqn_old2_a_tx;
	wire [31:0]	sqn_old1_a_tx;

	reg 		mm_web_tx;
	reg [9:0]	mm_addrb_tx;
	//reg [191:0] mm_dinb_tx;
	wire [191:0] mm_doutb_tx;
	
	localparam    IDLE_tx = 0;
	localparam    READ0_tx = 1;
	localparam    READ1_tx = 2;
	localparam    WRITE_tx = 3;
	
	reg [7:0] state_tx;
	
//////////////////////////////////////////////////////////////////rx 
	wire [22:0]                     fifo_in_id_rx;
	wire [63:0]                     fifo_in_time_rx;
	wire [31:0]                     fifo_in_sqn_rx;
	wire                            fifo_in_empty_rx;
	reg                             fifo_in_rd_rx; 
	
	reg 		mm_wea_rx;
	reg [9:0]	mm_addra_rx;
	reg [191:0] mm_dina_rx;
	wire [63:0]	time_old2_a_rx;
	wire [63:0]	time_old1_a_rx;
	wire [31:0]	sqn_old2_a_rx;
	wire [31:0]	sqn_old1_a_rx;

	reg 		mm_web_rx;
	reg [9:0]	mm_addrb_rx;
	//reg [191:0] mm_dinb_rx;
	wire [191:0] mm_doutb_rx;
	
	localparam    IDLE_rx = 0;
	localparam    READ0_rx = 1;
	localparam    READ1_rx = 2;
	localparam    WRITE_rx = 3;
	
	reg [7:0] state_rx;
	
	//////////////////////////////////////////////////////////////////
	
	reg fifo_rxid_valid;
	reg [22:0] fifo_rxid_in;
	reg fifo_rxid_rd;
	wire [22:0] fifo_rxid_dout;
	wire fifo_rxid_empty;
	//////////////////////////////////////////////////////////////////
	
	reg [7:0] state_id;
	localparam    IDLE_id = 0;
	localparam    READ0_id = 1;
	localparam    READ1_id = 2;
	localparam    WRITE_id = 3;
	
	reg dertatime_tx_valid;
	reg dertasqn_tx_valid ;
	reg [63:0] dertatime_tx;
	reg [31:0] dertasqn_tx;
	
	reg [31:0] fifo_sqnack_in;
	reg  fifo_sqnack_valid;
	reg fifo_sqnack_rd;
	wire [31:0] fifo_sqnack_dout;
	////
	//reg s_axis_divisor_tvalid;
	wire m_axis_dout_tvalid;
    wire [63:0] m_axis_dout_tdata;
    /////
    
    wire [22:0] fifo_out_id_dout;
    wire fifo_out_id_empty;
    reg [22:0] fifo_out_id_in;
    reg fifo_out_id_valid;
    reg fifo_out_id_rd;
    	
div_gen_0 div_inst(
    .aclk(clk),
    .s_axis_divisor_tvalid(dertasqn_tx_valid),
    .s_axis_divisor_tdata(dertatime_tx[31:0]),
    .s_axis_dividend_tvalid(dertatime_tx_valid),
    .s_axis_dividend_tdata(dertasqn_tx),
    .m_axis_dout_tvalid(m_axis_dout_tvalid),
    .m_axis_dout_tdata(m_axis_dout_tdata)    //[63:0]
);


bram_128_1024 tx_ram_inst(

  .clka(clk),
  .wea(mm_wea_tx),//写使能,写入为高，读数据为低 //A：存储接口，接受从流表匹配过来的值，
  .addra(mm_addra_tx),//【9：0】
  .dina(mm_dina_tx),//【127：0】
  .douta({time_old2_a_tx,time_old1_a_tx,sqn_old2_a_tx,sqn_old1_a_tx}),//【127：0】
  
  .clkb(clk),
  .web(),//写使能,写入为高，读数据为低 //B：读取接口，为下一级模块使用。
  .addrb(mm_addrb_tx),//【9：0】
  .dinb(),//【127：0】
  .doutb(mm_doutb_tx)//【127：0】
);

     fifofall #(//放置tx数据的FIFO
	  .C_WIDTH(64+32+23),
      .C_MAX_DEPTH_BITS(6)
      ) fifo_in_tx_inst
      (// Outputs
      .dout              ({fifo_in_id_tx,fifo_in_time_tx,fifo_in_sqn_tx}),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_in_empty_tx),
      // Inputs
      .din               ({in_id_tx,in_time_tx,in_sqn_tx}),
      .wr_en             (in_valid_tx),
      .rd_en             (fifo_in_rd_tx),
      
      .rst               (reset),
      .clk               (clk)); 
	  

bram_128_1024 rx_ram_inst(

  .clka(clk),
  .wea(mm_wea_rx),//写使能,写入为高，读数据为低 //A：存储接口，接受从流表匹配过来的值，
  .addra(mm_addra_rx),//【9：0】
  .dina(mm_dina_rx),//【127：0】
  .douta({time_old2_a_rx,time_old1_a_rx,sqn_old2_a_rx,sqn_old1_a_rx}),//【127：0】
  
  .clkb(clk),
  .web(),//写使能,写入为高，读数据为低 //B：读取接口，为下一级模块使用。
  .addrb(mm_addrb_rx),//【9：0】
  .dinb(),//【127：0】
  .doutb(mm_doutb_rx)//【127：0】
);

     fifofall #(
	  .C_WIDTH(64+32+23),
      .C_MAX_DEPTH_BITS(6)
      ) fifo_in_rx_inst
      (// Outputs
      .dout              ({fifo_in_id_rx,fifo_in_time_rx,fifo_in_sqn_rx}),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_in_empty_rx),
      // Inputs
      .din               ({in_id_rx,in_time_rx,in_sqn_rx}),
      .wr_en             (in_valid_rx),
      .rd_en             (fifo_in_rd_rx),
      
      .rst               (reset),
      .clk               (clk)); 
	  
	  
	  always @(posedge clk)begin
		if(reset)begin
			mm_wea_tx <= 0;
			mm_addra_tx <= 0;
			mm_dina_tx <= 0;
			mm_web_tx <= 0;
			fifo_in_rd_tx <= 0;
			state_tx <= IDLE_tx;
			fifo_rxid_in <= 0;
			fifo_rxid_valid <= 0;
			
		end else begin
			case(state_tx)
				IDLE_tx: begin
					if(!fifo_in_empty_tx)begin//读取id的地址，然后做修改放回
						mm_wea_tx <= 0;
						mm_addra_tx <= fifo_in_id_tx[9:0];
						fifo_in_rd_tx <= 0;
						mm_dina_tx <= 0;
						state_tx <= READ0_tx;
					end else begin
						mm_wea_tx <= 0;
						mm_addra_tx <= 0;
						mm_dina_tx <= 0;
						fifo_in_rd_tx <= 0;
						state_tx <= IDLE_tx;
					end
				end
				READ0_tx:begin
					state_tx <= READ1_tx;
				end
				READ1_tx:begin//写入修改后的新值
					mm_wea_tx <= 0;
					//mm_dina_tx <= {time_old1_a_tx,fifo_in_time_tx,sqn_old1_a_tx,fifo_in_sqn_tx};
					fifo_in_rd_tx <= 1;
					state_tx <= WRITE_tx;
				end
				WRITE_tx:begin
					mm_wea_tx <= 1;
					fifo_in_rd_tx <= 0;
					mm_dina_tx <= {time_old1_a_tx,fifo_in_time_tx,sqn_old1_a_tx,fifo_in_sqn_tx};
					state_tx <= IDLE_tx;
				end
			endcase
		end
	  end
	  	  
	  always @(posedge clk)begin
		if(reset)begin
			mm_wea_rx <= 0;
			mm_addra_rx <= 0;
			mm_dina_rx <= 0;
			mm_web_rx <= 0;
			fifo_in_rd_rx <= 0;
			state_rx <= IDLE_rx;
		end else begin
			case(state_rx)
				IDLE_rx: begin
					if(!fifo_in_empty_rx)begin//读取id的地址，然后做修改放回
						mm_wea_rx <= 0;
						mm_addra_rx <= fifo_in_id_rx[9:0];
						fifo_in_rd_rx <= 0;
						mm_dina_rx <= 0;
						state_rx <= READ0_rx;
					end else begin
						mm_wea_rx <= 0;
						mm_addra_rx <= 0;
						mm_dina_rx <= 0;
						fifo_in_rd_rx <= 0;
						state_rx <= IDLE_rx;
					end
				end
				READ0_rx:begin
					state_rx <= READ1_rx;
				end
				READ1_rx:begin//写入修改后的新值
					mm_wea_rx <= 0;
					fifo_in_rd_rx <= 1;
					state_rx <= WRITE_rx;
					fifo_rxid_valid <= 1;//给rxid FIFO写入一个新值
					fifo_rxid_in <= fifo_in_id_rx;
				end
				WRITE_rx:begin
					mm_wea_rx <= 1;
					fifo_in_rd_rx <= 0;
					mm_dina_rx <= {time_old1_a_rx,fifo_in_time_rx,sqn_old1_a_rx,fifo_in_sqn_rx};
					state_rx <= IDLE_rx;
					fifo_rxid_valid <= 0;//给rxid FIFO写入一个新值
					fifo_rxid_in <= 0;
				end
			endcase
		end
	  end
	  
	fifofall #(//放置rxid数据的FIFO,当rx的更新状态机执行结束之后再执行对这个FIFO附一个id元素
	  .C_WIDTH(23),
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
      
      .rst               (reset),
      .clk               (clk)); 
	  
	fifofall #(//放置rxid数据的FIFO,当rx的更新状态机执行结束之后再执行对这个FIFO附一个id元素
        .C_WIDTH(23),
        .C_MAX_DEPTH_BITS(6)
        ) fifo_out_id_inst
        (// Outputs
        .dout              (fifo_out_id_dout),
        .full              (),
        .nearly_full       (),
        .empty             (fifo_out_id_empty),
        // Inputs
        .din               (fifo_out_id_in),
        .wr_en             (fifo_out_id_valid),
        .rd_en             (fifo_out_id_rd),
        
        .rst               (reset),
        .clk               (clk)); 

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
      .din               (fifo_sqnack_in),
      .wr_en             (fifo_sqnack_valid),
      .rd_en             (fifo_sqnack_rd),
      
      .rst               (reset),
      .clk               (clk));
	  
	  always @(posedge clk)begin//计算过程状态机，计算差值，送给除法器和数据暂存器
		if(reset)begin
			mm_addrb_tx <= 0;
			mm_addrb_rx <= 0;
			fifo_rxid_rd <= 0;
			state_id <= IDLE_id;
			dertatime_tx <= 0;
			dertasqn_tx <= 0;
			fifo_sqnack_in <= 0;
			fifo_sqnack_valid <= 0;
			dertatime_tx_valid <= 0;
			dertasqn_tx_valid <= 0;
			fifo_out_id_valid <= 0;
            fifo_out_id_in <= 0;
		end else begin
			case(state_id)
				IDLE_id:begin
					if(!fifo_rxid_empty)begin
						mm_addrb_tx <= fifo_rxid_dout[9:0];
						mm_addrb_rx <= fifo_rxid_dout[9:0];
						
						fifo_out_id_valid <= 1;
						fifo_out_id_in <= fifo_rxid_dout;
						
						fifo_sqnack_valid <= 0;
						dertatime_tx_valid <= 0;
						dertasqn_tx_valid <= 0;
						state_id <= READ0_id;
					end else begin
						fifo_sqnack_valid <= 0;
						dertatime_tx_valid <= 0;
						dertasqn_tx_valid <= 0;
						state_id <= IDLE_id;
						fifo_out_id_valid <= 0;
                        fifo_out_id_in <= 0;
					end
				end
				READ0_id:begin
					state_id <= READ1_id;
					fifo_out_id_valid <= 0;
                    fifo_out_id_in <= 0;
				end
				READ1_id:begin
					state_id <= WRITE_id;
					fifo_rxid_rd <= 1;
				end
				WRITE_id:begin
					dertatime_tx_valid <= 1;
					dertatime_tx <= mm_doutb_tx[127:64] - mm_doutb_tx[191:128];//差值送给除法器
					dertasqn_tx_valid <= 1;
					dertasqn_tx <= mm_doutb_tx[31:0] - mm_doutb_tx[63:32];
					fifo_sqnack_in <= mm_doutb_tx[31:0] - mm_doutb_rx[31:0];//中间答案放入FIFO
					fifo_sqnack_valid <= 1;
					fifo_rxid_rd <= 0;
					state_id <= IDLE_id;
				end
			endcase
		end
	  end
	  
	  always @(posedge clk)begin
	   if(reset)begin
	       out_math_valid <= 0;
          out_data_id <= 0;
          fifo_out_id_rd <= 0;
          out_derta_ack <= 0;
          fifo_sqnack_rd <= 0;
          {out_send_r,out_send_f} <= 0;
	   end else begin
	       if(m_axis_dout_tvalid)begin
	           out_math_valid <= 1;
	           out_data_id <= fifo_out_id_dout;
	           fifo_out_id_rd <= 1;
	           out_derta_ack <= fifo_sqnack_dout;
	           fifo_sqnack_rd <= 1;
	           {out_send_r,out_send_f} <= m_axis_dout_tdata;
	       end else begin
	          out_math_valid <= 0;
              out_data_id <= 0;
              fifo_out_id_rd <= 0;
              out_derta_ack <= 0;
              fifo_sqnack_rd <= 0;
              {out_send_r,out_send_f} <= 0;
	       end
	   end
	  end
  
  endmodule
