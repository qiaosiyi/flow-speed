`timescale 1ns / 1ps
//两路查询，给一个table，分别返回两路的结果。
module arbiter #(
  parameter  C_LENGTH_5TUPLE = 104,
  parameter  C_ID_WIDTH = 12,
  parameter  C_COUNTER_WIDTH = 20,
  parameter  C_pd_WIDTH = 32
  )(
	input                            in_valid_5tuple_0,//egress 数据包parser 结果
	input [103:0]                    in_5tuple_0,
	input                            in_valid_sqn_0,
	input [31:0]                     in_sqn_0,
	
	input                            in_valid_5tuple_1,//ingress 数据包parser 结果
	input [103:0]                    in_5tuple_1,
	input                            in_valid_sqn_1,
	input [31:0]                     in_sqn_1,
	
	output reg                       out_valid_0,//egress 数据包lookup 结果
	output reg [63:0]                out_time_0,
	output reg [31:0]                out_sqn_0,
	output reg [22:0]                out_id_0,
	
	output reg                       out_valid_1,//ingress 数据包lookup 结果
	output reg [63:0]                out_time_1,
	output reg [31:0]                out_sqn_1,
	output reg [22:0]                out_id_1,
//========
//============================================================table interface
	output reg                       out_valid_tuple4search,
	output reg [95 : 0]              out_tuple4search,
	
	input                            in_valid_id,
	input [22:0]                     in_id,
//============================================================table interface
	
    input                            clk,
    input                            reset//高复位
  );
    wire [95:0] fifo_5tuple_0;
    wire [95:0] fifo_5tuple_1;
	wire fifo_5tuple_0_empty;
	wire fifo_5tuple_1_empty;
	reg fifo_5tuple_0_rd;
	reg fifo_5tuple_1_rd;
	
    wire [31:0] fifo_sqn_0;
    wire [31:0] fifo_sqn_1;
	wire fifo_sqn_0_empty;
	wire fifo_sqn_1_empty;
	reg fifo_sqn_0_rd;
	reg fifo_sqn_1_rd;
	
	wire fifo_q;
	wire fifo_q_empty;
	reg in_q;
	reg in_valid_q;
	reg fifo_q_rd;
	
	reg input_sel;//决定轮询读取哪一个的标志位
	
	reg [63:0] time_stemp;//时间，这是时间戳
  
    fifofall #(
	  .C_WIDTH(96),
      .C_MAX_DEPTH_BITS(4)
      ) fifo_5t_in_inst_0
      (// Outputs
      .dout              (fifo_5tuple_0),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_5tuple_0_empty),
      // Inputs
      .din               (in_5tuple_0[95:0]),
      .wr_en             (in_valid_5tuple_0),
      .rd_en             (fifo_5tuple_0_rd),
      
      .rst               (reset),
      .clk               (clk));
  
     fifofall #(
	  .C_WIDTH(96),
      .C_MAX_DEPTH_BITS(4)
      ) fifo_5t_in_inst_1
      (// Outputs
      .dout              (fifo_5tuple_1),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_5tuple_1_empty),
      // Inputs
      .din               (in_5tuple_1[95:0]),
      .wr_en             (in_valid_5tuple_1),
      .rd_en             (fifo_5tuple_1_rd),
      
      .rst               (reset),
      .clk               (clk)); 
  
     fifofall #(
	  .C_WIDTH(32),
      .C_MAX_DEPTH_BITS(8)
      ) fifo_sqn_in_inst_0
      (// Outputs
      .dout              (fifo_sqn_0),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_sqn_0_empty),
      // Inputs
      .din               (in_sqn_0),
      .wr_en             (in_valid_sqn_0),
      .rd_en             (fifo_sqn_0_rd),
      
      .rst               (reset),
      .clk               (clk)); 

     fifofall #(
	  .C_WIDTH(32),
      .C_MAX_DEPTH_BITS(8)
      ) fifo_sqn_in_inst_1
      (// Outputs
      .dout              (fifo_sqn_1),
      .full              (),
      .nearly_full       (),
      .empty             (fifo_sqn_1_empty),
      // Inputs
      .din               (in_sqn_1),
      .wr_en             (in_valid_sqn_1),
      .rd_en             (fifo_sqn_1_rd),
      
      .rst               (reset),
      .clk               (clk)); 
	  
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
      
      .rst               (reset),
      .clk               (clk));	  

	  always @ (posedge clk) begin//轮询调度的指示变化位。
		if (reset) begin
		  input_sel <= 0;
		  time_stemp <= 0;
		end else begin
		  input_sel <= input_sel + 1;// 一周期换一个
		  time_stemp <= time_stemp + 1;
		end
	  end
  
	always @ (posedge clk) begin//轮询的mux
		if (reset) begin
			out_valid_tuple4search <= 0;
			out_tuple4search <= 0;
			fifo_5tuple_0_rd <= 0;
			fifo_5tuple_1_rd <= 0;
			in_q <= 0;
			in_valid_q <= 0;
			
		end else begin
			if(!input_sel && !fifo_5tuple_0_empty)begin//从0中取出一个去查表
				out_valid_tuple4search <= 1;
				out_tuple4search <= fifo_5tuple_0;
				fifo_5tuple_0_rd <= 1;
				in_q <= input_sel;//插入到历史记录队列中
				in_valid_q <= 1;
				
			end else if(input_sel && !fifo_5tuple_1_empty)begin//从1中取出一个去查表
				out_valid_tuple4search <= 1;
				out_tuple4search <= fifo_5tuple_1;
				fifo_5tuple_1_rd <= 1;
				in_q <= input_sel;//插入到历史记录队列中
				in_valid_q <= 1;
			end else begin
				out_valid_tuple4search <= 0;
				out_tuple4search <= 0;
				fifo_5tuple_0_rd <= 0;
				fifo_5tuple_1_rd <= 0;
				in_q <= 0;
				in_valid_q <= 0;
			end
		end
	  end
  
	always @ (posedge clk) begin//当ID返回时,按照q_fifo中的顺序，从另外两组大FIFO中读取数据
		if (reset) begin
			out_valid_0 <= 0;//0组信号
			out_time_0 <= 0;
			out_sqn_0 <= 0;
			out_id_0 <= 0;
			
			out_valid_1 <= 0;//1组信号
			out_time_1 <= 0;
			out_sqn_1 <= 0;
			out_id_1 <= 0;
			
			fifo_sqn_0_rd <= 0;//读FIFO信号
			fifo_sqn_1_rd <= 0;			
			fifo_q_rd <= 0;
		end else begin
			if(in_valid_id)begin
				if(!fifo_q)begin//0组，读取0组
					out_valid_0 <= 1;
					out_time_0 <= time_stemp;
					out_sqn_0 <= fifo_sqn_0;
					out_id_0 <= in_id;
					fifo_sqn_0_rd <= 1;
					fifo_q_rd <= 1;
				end else begin//1组
					out_valid_1 <= 1;
					out_time_1 <= time_stemp;
					out_sqn_1 <= fifo_sqn_1;
					out_id_1 <= in_id;
					fifo_sqn_1_rd <= 1;
					fifo_q_rd <= 1;
				end
			end else begin
				out_valid_0 <= 0;
				out_time_0 <= 0;
				out_sqn_0 <= 0;
				out_id_0 <= 0;
				
				out_valid_1 <= 0;
				out_time_1 <= 0;
				out_sqn_1 <= 0;
				out_id_1 <= 0;
				
				fifo_sqn_0_rd <= 0;
				fifo_sqn_1_rd <= 0;			
				fifo_q_rd <= 0;
			end
		end
	end   
endmodule
