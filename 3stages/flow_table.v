`timescale 1ps/1ps

module flow_table (
  // TX/RX flow attributes as query input
  input             tx_flow_attribute_vld_in,
  input      [95:0] tx_flow_attribute_in,
  input             rx_flow_attribute_vld_in,
  input      [95:0] rx_flow_attribute_in,

  // TX/RX flow ID as query output
  output reg        tx_flow_id_vld_out,
  output reg        tx_flow_id_match_out,
  output reg [21:0] tx_flow_id_out,
  output reg        rx_flow_id_match_out,
  output reg        rx_flow_id_vld_out,
  output reg [21:0] rx_flow_id_out,

  // Configuration interface for flow table
  input       [7:0] s_axil_bcam_awaddr_in,
  input             s_axil_bcam_awvalid_in,
  output            s_axil_bcam_awready_out,
  input      [31:0] s_axil_bcam_wdata_in,
  input       [3:0] s_axil_bcam_wstrb_in,
  input             s_axil_bcam_wvalid_in,
  output            s_axil_bcam_wready_out,
  input             s_axil_bcam_bready_in,
  output      [1:0] s_axil_bcam_bresp_out,
  output            s_axil_bcam_bvalid_out,
  input       [7:0] s_axil_bcam_araddr_in,
  input             s_axil_bcam_arvalid_in,
  output            s_axil_bcam_arready_out,
  input             s_axil_bcam_rready_in,
  output     [31:0] s_axil_bcam_rdata_out,
  output      [1:0] s_axil_bcam_rresp_out,
  output            s_axil_bcam_rvalid_out,

  input             pkt_clk,
  input             pkt_rst_n,
  input             cfg_clk,
  input             cfg_rst_n
  );

  wire [95:0] fifo_tx_dout;
  wire [95:0] fifo_rx_dout;
  wire        fifo_tx_empty;
  wire        fifo_rx_empty;
  reg         fifo_tx_rd;
  reg         fifo_rx_rd;

  wire        fifo_q;
  wire        fifo_q_empty;
  reg         in_q;
  reg         in_valid_q;
  reg         fifo_q_rd;
  
  reg         input_sel;//决定轮询读取哪一个的标志位
  
  reg         tuple_in_request_VALID;
  reg  [95:0] tuple_in_request_DATA;
  
  wire        tuple_out_response_VALID;//////for test
  wire        LookupRespMatch;////for test

  wire [21:0] tuple_out_response_DATA;//////for test

  fifofall #(
    .C_WIDTH(96),
    .C_MAX_DEPTH_BITS(4)
    ) tx_flow_in_fifo_inst//
  (// Outputs
    .dout              (fifo_tx_dout),
    .full              (),
    .nearly_full       (),
    .empty             (fifo_tx_empty),
    // Inputs
    .din               (tx_flow_attribute_in),
    .wr_en             (tx_flow_attribute_vld_in),
    .rd_en             (fifo_tx_rd),
    
    .rst               (pkt_rst_n),
    .clk               (pkt_clk));

  fifofall #(
    .C_WIDTH(96),
    .C_MAX_DEPTH_BITS(4)
    ) rx_flow_in_fifo_inst
  (// Outputs
    .dout              (fifo_rx_dout),
    .full              (),
    .nearly_full       (),
    .empty             (fifo_rx_empty),
    // Inputs
    .din               (rx_flow_attribute_in),
    .wr_en             (rx_flow_attribute_vld_in),
    .rd_en             (fifo_rx_rd),
    
    .rst               (pkt_rst_n),
    .clk               (pkt_clk)); 
  
  fifofall #(
    .C_WIDTH(1),
    .C_MAX_DEPTH_BITS(9)
    ) fifo_q_in_inst//存放查询先后顺序的FIFO
  (// Outputs
    .dout              (fifo_q),
    .full              (),
    .nearly_full       (),
    .empty             (fifo_q_empty),
    // Inputs
    .din               (in_q),
    .wr_en             (in_valid_q),
    .rd_en             (fifo_q_rd),
    
    .rst               (pkt_rst_n),
    .clk               (pkt_clk));	  
  
  BCAM#() bcam_inst(
    .clk_lookup_rst_high(!pkt_rst_n),  
    .clk_lookup(pkt_clk),
    .tuple_in_request_VALID(tuple_in_request_VALID),
    .tuple_in_request_DATA(tuple_in_request_DATA),
    .tuple_out_response_VALID(tuple_out_response_VALID),//tuple_out_response_VALID//////for test
    .tuple_out_response_DATA({LookupRespMatch,tuple_out_response_DATA}),//{LookupRespMatch,tuple_out_response_DATA}//////for test
    .clk_control(cfg_clk),
    .clk_control_rst_low(cfg_rst_n),
    .control_S_AXI_AWADDR(s_axil_bcam_awaddr_in),
    .control_S_AXI_AWVALID(s_axil_bcam_awvalid_in),
    .control_S_AXI_AWREADY(s_axil_bcam_awready_out),
    .control_S_AXI_WDATA(s_axil_bcam_wdata_in),
    .control_S_AXI_WSTRB(s_axil_bcam_wstrb_in),
    .control_S_AXI_WVALID(s_axil_bcam_wvalid_in),
    .control_S_AXI_WREADY(s_axil_bcam_wready_out),
    .control_S_AXI_BREADY(s_axil_bcam_bready_in),
    .control_S_AXI_BRESP(s_axil_bcam_bresp_out),
    .control_S_AXI_BVALID(s_axil_bcam_bvalid_out),
    .control_S_AXI_ARADDR(s_axil_bcam_araddr_in),
    .control_S_AXI_ARVALID(s_axil_bcam_arvalid_in),
    .control_S_AXI_ARREADY(s_axil_bcam_arready_out),
    .control_S_AXI_RREADY(s_axil_bcam_rready_in),
    .control_S_AXI_RDATA(s_axil_bcam_rdata_out),
    .control_S_AXI_RRESP(s_axil_bcam_rresp_out),
    .control_S_AXI_RVALID(s_axil_bcam_rvalid_out)
    );
  
  always @ (posedge pkt_clk) begin//轮询调度的指示变化位。
    if (!pkt_rst_n) begin
      input_sel <= 0;
      // time_stemp <= 0;
    end else begin
      input_sel <= input_sel + 1;// 一周期换一个
      //time_stemp <= time_stemp + 1;
    end
  end
  
  always @ (posedge pkt_clk) begin//search
    if (!pkt_rst_n) begin
      tuple_in_request_VALID <= 0;
      tuple_in_request_DATA <= 0;
      fifo_tx_rd <= 0;
      fifo_rx_rd <= 0;
      in_q <= 0;
      in_valid_q <= 0;
      
    end else begin
      if(!input_sel && !fifo_tx_empty)begin//从0中取出一个去查表
	tuple_in_request_VALID <= 1;
	tuple_in_request_DATA <= fifo_tx_dout;
	fifo_tx_rd <= 1;
	in_q <= input_sel;//插入到历史记录队列中
	in_valid_q <= 1;
	
      end else if(input_sel && !fifo_rx_empty)begin//从1中取出一个去查表
	tuple_in_request_VALID <= 1;
	tuple_in_request_DATA <= fifo_rx_dout;
	fifo_rx_rd <= 1;
	in_q <= input_sel;//插入到历史记录队列中
	in_valid_q <= 1;
      end else begin
	tuple_in_request_VALID <= 0;
	tuple_in_request_DATA <= 0;
	fifo_tx_rd <= 0;
	fifo_rx_rd <= 0;
	in_q <= 0;
	in_valid_q <= 0;
      end
    end
  end	  
  
  always @ (posedge pkt_clk) begin//当ID返回时,按照q_fifo中的顺序，从另外两组大FIFO中读取数据
    if (!pkt_rst_n) begin
      tx_flow_id_vld_out <= 0;//0组信号
      //out_time_0 <= 0;
      //out_sqn_0 <= 0;
      tx_flow_id_out <= 0;
      
      rx_flow_id_vld_out <= 0;//1组信号
      //out_time_1 <= 0;
      //out_sqn_1 <= 0;
      rx_flow_id_out <= 0;
      
      //fifo_sqn_0_rd <= 0;//读FIFO信号
      //fifo_sqn_1_rd <= 0;			
      fifo_q_rd <= 0;
      tx_flow_id_match_out <= 0;
      rx_flow_id_match_out <= 0;
    end else begin
      if(tuple_out_response_VALID)begin
	if(!fifo_q)begin//0组，读取0组tx group
	  tx_flow_id_vld_out <= 1;
	  //out_time_0 <= time_stemp;
	  //out_sqn_0 <= fifo_sqn_0;
	  tx_flow_id_match_out <= LookupRespMatch;
	  tx_flow_id_out <= {tuple_out_response_DATA[21:0]};
	  //fifo_sqn_0_rd <= 1;
	  fifo_q_rd <= 1;
	end else begin//1组
	  rx_flow_id_vld_out <= 1;
	  //out_time_1 <= time_stemp;
	  //out_sqn_1 <= fifo_sqn_1;
	  rx_flow_id_match_out <= LookupRespMatch;
	  rx_flow_id_out <= {tuple_out_response_DATA[21:0]};
	  //fifo_sqn_1_rd <= 1;
	  fifo_q_rd <= 1;
	end
      end else begin
	tx_flow_id_vld_out <= 0;
	//out_time_0 <= 0;
	//out_sqn_0 <= 0;
	tx_flow_id_out <= 0;
	
	rx_flow_id_vld_out <= 0;
	//out_time_1 <= 0;
	//out_sqn_1 <= 0;
	tx_flow_id_match_out <= 0;
        rx_flow_id_match_out <= 0;
	rx_flow_id_out <= 0;
	
	//fifo_sqn_0_rd <= 0;
	//fifo_sqn_1_rd <= 0;			
	fifo_q_rd <= 0;
      end
    end
  end	  

endmodule // flow_table
